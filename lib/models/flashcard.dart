// AI生成 - 闪卡记忆数据模型，Anki 风格 SM-2 间隔重复算法
import 'package:hive/hive.dart';

part 'flashcard.g.dart';

/// Anki 风格卡片状态
enum CardStatus { isNew, learning, review, mastered }

@HiveType(typeId: 8)
class FlashcardDeck extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? courseId;

  @HiveField(3)
  List<Flashcard> cards;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String userId;

  FlashcardDeck({
    required this.id,
    required this.name,
    this.courseId,
    this.cards = const [],
    this.colorValue = 0xFF27AE60,
    DateTime? createdAt,
    this.userId = 'guest',
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalCards => cards.length;

  // ─── Anki 风格分类统计 ───
  int get newCount => cards.where((c) => c.status == CardStatus.isNew).length;
  int get learningCount => cards.where((c) => c.status == CardStatus.learning).length;
  int get reviewCount => cards.where((c) => c.status == CardStatus.review).length;
  int get masteredCount => cards.where((c) => c.status == CardStatus.mastered).length;

  /// 今日待复习（含新卡 + 到期复习卡 + 学习中的卡）
  int get dueCount => cards.where((c) => c.isDue).length;

  /// 掌握度 = (复习中 × 0.6 + 已掌握 × 1.0) / 总数
  double get masteryRate {
    if (totalCards == 0) return 0;
    return (reviewCount * 0.6 + masteredCount * 1.0) / totalCards;
  }

  // 兼容旧接口
  int get masteredCards => masteredCount;
}

@HiveType(typeId: 9)
class Flashcard {
  @HiveField(0)
  String id;

  @HiveField(1)
  String front;

  @HiveField(2)
  String back;

  @HiveField(3)
  int repetitionLevel; // 连续正确次数（n）

  @HiveField(4)
  double easeFactor; // 难易因子，最低 1.3

  @HiveField(5)
  DateTime? nextReviewDate;

  @HiveField(6)
  int reviewCount; // 总复习次数

  /// 当前间隔天数（用于计算下次间隔）
  @HiveField(7)
  int intervalDays;

  /// 学习阶段中的步骤索引（0=1min, 1=10min）
  @HiveField(8)
  int learningStep;

  Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.repetitionLevel = 0,
    this.easeFactor = 2.5,
    this.nextReviewDate,
    this.reviewCount = 0,
    this.intervalDays = 0,
    this.learningStep = 0,
  });

  // ─── Anki 风格状态推断 ───
  CardStatus get status {
    if (reviewCount == 0 && repetitionLevel == 0) return CardStatus.isNew;
    if (intervalDays < 1) return CardStatus.learning;
    if (intervalDays >= 21) return CardStatus.mastered;
    return CardStatus.review;
  }

  String get statusLabel {
    switch (status) {
      case CardStatus.isNew: return '新';
      case CardStatus.learning: return '学习中';
      case CardStatus.review: return '复习';
      case CardStatus.mastered: return '已掌握';
    }
  }

  bool get isDue =>
      nextReviewDate == null || nextReviewDate!.isBefore(DateTime.now());

  // 兼容旧接口
  bool get needsReview => isDue;

  // ─── Anki 风格间隔预览（不修改状态）───
  /// 返回各评级对应的下次间隔描述
  Map<int, String> get intervalPreview {
    return {
      0: _formatInterval(_calcAgainInterval()),
      2: _formatInterval(_calcHardInterval()),
      3: _formatInterval(_calcGoodInterval()),
      5: _formatInterval(_calcEasyInterval()),
    };
  }

  int _calcAgainInterval() => 0; // 重来 → 回到学习队列（分钟级）
  int _calcHardInterval() {
    if (status == CardStatus.isNew || status == CardStatus.learning) return 0;
    return (intervalDays * 1.2).round().clamp(1, 36500);
  }
  int _calcGoodInterval() {
    if (status == CardStatus.isNew || status == CardStatus.learning) return 1;
    if (repetitionLevel == 1) return 1;
    if (repetitionLevel == 2) return 6;
    return (intervalDays * easeFactor).round().clamp(1, 36500);
  }
  int _calcEasyInterval() {
    if (status == CardStatus.isNew || status == CardStatus.learning) return 4;
    return (intervalDays * easeFactor * 1.3).round().clamp(1, 36500);
  }

  String _formatInterval(int days) {
    if (days == 0) return '<10分';
    if (days == 1) return '1天';
    if (days < 30) return '$days天';
    if (days < 365) return '${(days / 30).round()}月';
    return '${(days / 365).toStringAsFixed(1)}年';
  }

  /// Anki 风格 SM-2 算法
  /// rating: 0=重来(Again), 2=困难(Hard), 3=良好(Good), 5=简单(Easy)
  void updateReview(int rating) {
    reviewCount++;
    final now = DateTime.now();

    if (rating == 0) {
      // ── 重来：回到学习队列 ──
      repetitionLevel = 0;
      intervalDays = 0;
      learningStep = 0;
      nextReviewDate = now.add(const Duration(minutes: 10));
      easeFactor = (easeFactor - 0.2).clamp(1.3, 10.0);
    } else if (status == CardStatus.isNew || status == CardStatus.learning) {
      // ── 新卡/学习中 ──
      if (rating == 2) {
        // 困难：留在学习步骤
        learningStep = 0;
        intervalDays = 0;
        nextReviewDate = now.add(const Duration(minutes: 10));
      } else if (rating == 3) {
        // 良好：毕业到复习队列
        repetitionLevel = 1;
        intervalDays = 1;
        nextReviewDate = now.add(const Duration(days: 1));
      } else {
        // 简单：直接到 4 天
        repetitionLevel = 2;
        intervalDays = 4;
        nextReviewDate = now.add(const Duration(days: 4));
        easeFactor = (easeFactor + 0.15).clamp(1.3, 10.0);
      }
    } else {
      // ── 复习卡 ──
      if (rating == 2) {
        // 困难：间隔 × 1.2
        intervalDays = (intervalDays * 1.2).round().clamp(1, 36500);
        nextReviewDate = now.add(Duration(days: intervalDays));
        easeFactor = (easeFactor - 0.15).clamp(1.3, 10.0);
      } else if (rating == 3) {
        // 良好：间隔 × EF
        intervalDays = (intervalDays * easeFactor).round().clamp(1, 36500);
        nextReviewDate = now.add(Duration(days: intervalDays));
      } else {
        // 简单：间隔 × EF × 1.3
        intervalDays = (intervalDays * easeFactor * 1.3).round().clamp(1, 36500);
        nextReviewDate = now.add(Duration(days: intervalDays));
        easeFactor = (easeFactor + 0.15).clamp(1.3, 10.0);
      }
      repetitionLevel++;
    }
  }
}
