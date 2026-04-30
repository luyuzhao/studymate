// AI生成 - 闪卡记忆状态管理（Anki 风格 SM-2 + 实时掌握度统计）
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/flashcard.dart';
import 'user_provider.dart';

final flashcardProvider =
    StateNotifierProvider<FlashcardNotifier, List<FlashcardDeck>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return FlashcardNotifier(userId);
});

/// 学习会话统计
class StudySession {
  final DateTime startedAt;
  int cardsStudied;
  int againCount;
  int hardCount;
  int goodCount;
  int easyCount;
  int get accuracyCards => goodCount + easyCount;

  StudySession()
      : startedAt = DateTime.now(),
        cardsStudied = 0,
        againCount = 0,
        hardCount = 0,
        goodCount = 0,
        easyCount = 0;

  void record(int rating) {
    cardsStudied++;
    switch (rating) {
      case 0: againCount++; break;
      case 2: hardCount++; break;
      case 3: goodCount++; break;
      case 5: easyCount++; break;
    }
  }
}

class FlashcardNotifier extends StateNotifier<List<FlashcardDeck>> {
  FlashcardNotifier(this._userId) : super([]) { _loadDecks(); }

  final String _userId;
  final _box = Hive.box<FlashcardDeck>('flashcard_decks');
  final _uuid = const Uuid();

  /// 当前学习会话统计
  StudySession? _currentSession;
  StudySession? get currentSession => _currentSession;
  void startSession() => _currentSession = StudySession();
  void endSession() => _currentSession = null;

  void _loadDecks() {
    state = _box.values.where((d) => d.userId == _userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ─── 卡组 CRUD ───
  Future<void> addDeck({
    required String name, String? courseId, int colorValue = 0xFF27AE60,
  }) async {
    final deck = FlashcardDeck(
      id: _uuid.v4(), name: name, courseId: courseId,
      colorValue: colorValue, userId: _userId,
    );
    await _box.put(deck.id, deck);
    _loadDecks();
  }

  Future<void> addCard(String deckId, {required String front, required String back}) async {
    final deck = _box.get(deckId);
    if (deck == null) return;
    final cards = List<Flashcard>.from(deck.cards);
    cards.add(Flashcard(id: _uuid.v4(), front: front, back: back));
    deck.cards = cards;
    await deck.save();
    _loadDecks();
  }

  Future<void> updateCardReview(String deckId, String cardId, int quality) async {
    final deck = _box.get(deckId);
    if (deck == null) return;
    final cards = List<Flashcard>.from(deck.cards);
    final idx = cards.indexWhere((c) => c.id == cardId);
    if (idx >= 0) {
      cards[idx].updateReview(quality);
      deck.cards = cards;
      await deck.save();
      _currentSession?.record(quality);
      _loadDecks();
    }
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    final deck = _box.get(deckId);
    if (deck == null) return;
    final cards = List<Flashcard>.from(deck.cards);
    cards.removeWhere((c) => c.id == cardId);
    deck.cards = cards;
    await deck.save();
    _loadDecks();
  }

  Future<void> deleteDeck(String id) async {
    await _box.delete(id);
    _loadDecks();
  }

  /// 从 assets JSON 文件导入预置卡组
  Future<void> importFromAsset(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final name = data['name'] as String;
    final colorHex = data['color'] as String? ?? '#27AE60';
    final colorValue = int.parse('0xFF${colorHex.replaceFirst('#', '')}');
    final cardsData = data['cards'] as List<dynamic>;
    final cards = cardsData.map((c) => Flashcard(
      id: _uuid.v4(),
      front: c['front'] as String,
      back: c['back'] as String,
    )).toList();
    final deck = FlashcardDeck(
      id: _uuid.v4(), name: name, colorValue: colorValue, userId: _userId,
    );
    deck.cards = cards;
    await _box.put(deck.id, deck);
    _loadDecks();
  }

  bool isDeckImported(String name) => state.any((d) => d.name == name);

  // ─── Anki 风格学习队列 ───
  /// 返回今日应复习卡片，按 Anki 顺序：
  /// 1. 学习中（Learning）先到期的
  /// 2. 新卡（New）— 默认限制 20
  /// 3. 到期复习卡（Review）
  List<Flashcard> buildStudyQueue(String deckId, {int newCardLimit = 20}) {
    final deck = _box.get(deckId);
    if (deck == null) return [];

    final learning = deck.cards
        .where((c) => c.status == CardStatus.learning && c.isDue)
        .toList();
    learning.sort((a, b) => (a.nextReviewDate ?? DateTime(0))
        .compareTo(b.nextReviewDate ?? DateTime(0)));

    final newCards = deck.cards
        .where((c) => c.status == CardStatus.isNew)
        .take(newCardLimit)
        .toList();

    final reviewCards = deck.cards
        .where((c) =>
            (c.status == CardStatus.review || c.status == CardStatus.mastered) &&
            c.isDue)
        .toList();

    return [...learning, ...newCards, ...reviewCards];
  }

  /// 兼容旧接口：返回所有到期卡片（无队列排序）
  List<Flashcard> getCardsNeedingReview(String deckId) {
    final deck = _box.get(deckId);
    if (deck == null) return [];
    return deck.cards.where((c) => c.isDue).toList();
  }

  // ─── 卡组级统计 ───
  /// 返回卡组实时掌握度分布
  Map<String, int> getDeckStats(String deckId) {
    final deck = _box.get(deckId);
    if (deck == null) {
      return {'new': 0, 'learning': 0, 'review': 0, 'mastered': 0, 'due': 0};
    }
    return {
      'new': deck.newCount,
      'learning': deck.learningCount,
      'review': deck.reviewCount,
      'mastered': deck.masteredCount,
      'due': deck.dueCount,
      'total': deck.totalCards,
    };
  }
}
