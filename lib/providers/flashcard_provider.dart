// AI生成 - 闪卡记忆状态管理（Anki 风格 SM-2 + 实时掌握度统计）
import 'dart:convert';
import 'dart:io';
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

  /// 从 JSON 字符串导入卡组（在线下载后使用）
  Future<int> importFromJsonString(String jsonStr) async {
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
    return cards.length;
  }

  /// 从纯文本导入卡组（支持多种 TXT / CSV 格式）
  /// 识别顺序：词典格式(word [音标] 释义) → tab分隔 → 逗号分隔 → 空格+中文 → 每行一词
  Future<int> importFromText(String text, {String? deckName}) async {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#') && !l.startsWith('//'))
        .toList();
    if (lines.isEmpty) throw Exception('文本为空，没有找到单词');

    // 词典格式正则：word [音标] 释义
    final dictRe = RegExp(r'^([a-zA-Z][a-zA-Z\s\-]*?)\s*\[([^\]]+)\]\s*(.*)$');

    final cards = <Flashcard>[];
    for (final line in lines) {
      String front, back;

      // 1) 词典格式：word [phonetic] pos. definition
      final dictMatch = dictRe.firstMatch(line);
      if (dictMatch != null) {
        front = dictMatch.group(1)!.trim();
        final phonetic = dictMatch.group(2)!.trim();
        final def = dictMatch.group(3)?.trim() ?? '';
        back = '[$phonetic] $def';
      }
      // 2) Tab 分隔
      else if (line.contains('\t')) {
        final parts = line.split('\t');
        front = parts[0].trim();
        back = parts.sublist(1).join(' ').trim();
      }
      // 3) 单词 + 中文释义（空格后紧跟中文/词性标记）
      else {
        final m = RegExp(r'^([a-zA-Z][a-zA-Z\-]*)\s+(.+)$').firstMatch(line);
        if (m != null) {
          front = m.group(1)!.trim();
          back = m.group(2)!.trim();
        } else {
          front = line;
          back = '';
        }
      }
      if (front.isNotEmpty) {
        cards.add(Flashcard(id: _uuid.v4(), front: front, back: back));
      }
    }
    if (cards.isEmpty) throw Exception('未能解析出有效单词');

    final name = deckName ?? '导入词库 (${cards.length}词)';
    final deck = FlashcardDeck(
      id: _uuid.v4(), name: name, colorValue: 0xFF2196F3, userId: _userId,
    );
    deck.cards = cards;
    await _box.put(deck.id, deck);
    _loadDecks();
    return cards.length;
  }

  /// 从 URL 下载并导入（自动识别 JSON / TXT）
  Future<int> importFromUrl(String url) async {
    final uri = Uri.parse(url);
    final response = await _httpGet(uri);
    if (response == null) throw Exception('下载失败，请检查网络');
    final trimmed = response.trimLeft();
    // 自动判断：以 { 或 [ 开头 → JSON，否则 → TXT
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return importFromJsonString(trimmed);
    } else {
      // 从 URL 提取文件名作为卡组名
      final fileName = Uri.decodeFull(uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'words')
          .replaceAll(RegExp(r'\.\w+$'), '');
      return importFromText(trimmed, deckName: fileName);
    }
  }

  /// HTTP GET 请求（兼容中国网络）
  static Future<String?> _httpGet(Uri uri) async {
    try {
      final request = await HttpClient().getUrl(uri);
      request.headers.set('Accept', '*/*');
      final response = await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return await response.transform(utf8.decoder).join();
      }
      return null;
    } catch (_) {
      return null;
    }
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
