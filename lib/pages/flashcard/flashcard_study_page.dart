// AI生成 - Anki 风格闪卡学习页
// 核心特性：队列信息条、间隔预览、实时掌握度统计
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/flashcard_provider.dart';
import '../../models/flashcard.dart';
import '../../theme/app_theme.dart';

class FlashcardStudyPage extends ConsumerStatefulWidget {
  final String deckId;
  const FlashcardStudyPage({super.key, required this.deckId});
  @override
  ConsumerState<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends ConsumerState<FlashcardStudyPage> {
  int _idx = 0;
  bool _showAnswer = false;
  List<Flashcard> _cards = [];

  @override
  void initState() {
    super.initState();
    ref.read(flashcardProvider.notifier).startSession();
  }

  @override
  void dispose() {
    ref.read(flashcardProvider.notifier).endSession();
    super.dispose();
  }

  void _reveal() {
    if (!_showAnswer) setState(() => _showAnswer = true);
  }

  void _rate(int quality) {
    if (_cards.isEmpty) return;
    final cardId = _cards[_idx].id;
    ref.read(flashcardProvider.notifier).updateCardReview(widget.deckId, cardId, quality);
    setState(() {
      _showAnswer = false;
      if (_idx < _cards.length - 1) {
        _idx++;
      } else {
        _showDoneDialog();
      }
    });
  }

  void _showDoneDialog() {
    final session = ref.read(flashcardProvider.notifier).currentSession;
    final timeMin = session != null
        ? DateTime.now().difference(session.startedAt).inMinutes
        : 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration, size: 48, color: Colors.amber),
        title: const Text('复习完成！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('共复习 ${_cards.length} 张卡片，耗时 ${timeMin > 0 ? '$timeMin 分' : '不足1分钟'}'),
            const SizedBox(height: 16),
            if (session != null) ...[
              _statRow(Icons.check_circle, Colors.green, '简单', session.easyCount),
              _statRow(Icons.check, Colors.blue, '良好', session.goodCount),
              _statRow(Icons.help, Colors.orange, '困难', session.hardCount),
              _statRow(Icons.close, Colors.red, '重来', session.againCount),
              const Divider(height: 24),
              _statRow(Icons.percent, Colors.purple,
                '正确率', session.cardsStudied > 0
                  ? '${((session.accuracyCards / session.cardsStudied) * 100).round()}%'
                  : '0%',
                isRate: true),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, Color c, String label, dynamic value, {bool isRate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(value.toString(),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isRate ? c : null)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(flashcardProvider);
    final deck = decks.where((d) => d.id == widget.deckId).firstOrNull;
    if (deck == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('卡组不存在')));

    if (_cards.isEmpty) {
      _cards = ref.read(flashcardProvider.notifier).buildStudyQueue(widget.deckId);
      if (_cards.isEmpty) _cards = deck.cards.toList();
    }
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('复习')),
        body: const Center(child: Text('没有卡片')),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final card = _cards[_idx];
    final progress = (_idx + 1) / _cards.length;
    final preview = card.intervalPreview;
    final stats = ref.read(flashcardProvider.notifier).getDeckStats(widget.deckId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_idx + 1} / ${_cards.length}'),
        actions: [
          // ─── 队列信息条 ───
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _queueBadge('新', stats['new'] ?? 0, cs.primary),
                const SizedBox(width: 6),
                _queueBadge('学中', stats['learning'] ?? 0, Colors.orange),
                const SizedBox(width: 6),
                _queueBadge('复习', stats['due'] ?? 0, cs.secondary),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(children: [
          // ─── 进度条 ───
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 4),
          ),
          const SizedBox(height: 20),

          // ─── 问题区 ───
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(children: [
                    _statusChip(card.statusLabel, card.status),
                    const SizedBox(height: 16),
                    Text('问题', style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4))),
                    const SizedBox(height: 8),
                    Text(card.front,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  ]),
                ),

                const SizedBox(height: 16),

                // ─── 答案区（点击后展开） ───
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SizeTransition(sizeFactor: anim, child: child)),
                  child: _showAnswer
                    ? Container(
                        key: const ValueKey('answer'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.flashcardColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.flashcardColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(children: [
                          Text('答案', style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.flashcardColor.withValues(alpha: 0.6))),
                          const SizedBox(height: 8),
                          Text(card.back,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.flashcardColor),
                            textAlign: TextAlign.center),
                        ]),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ─── 底部操作区 ───
          if (_showAnswer)
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _ankiBtn('重来', preview[0] ?? '<10分', Colors.red, Icons.close_rounded, 0),
              _ankiBtn('困难', preview[2] ?? '1天', Colors.orange, Icons.remove_rounded, 2),
              _ankiBtn('良好', preview[3] ?? '1天', Colors.blue, Icons.check_rounded, 3),
              _ankiBtn('简单', preview[5] ?? '4天', Colors.green, Icons.done_all_rounded, 5),
            ])
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _reveal,
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('显示答案'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.flashcardColor,
                ),
              ),
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _queueBadge(String label, int count, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$label: $count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
    );
  }

  Widget _statusChip(String label, CardStatus status) {
    Color c;
    switch (status) {
      case CardStatus.isNew: c = Colors.blue; break;
      case CardStatus.learning: c = Colors.orange; break;
      case CardStatus.review: c = Colors.purple; break;
      case CardStatus.mastered: c = Colors.green; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
    );
  }

  /// Anki 风格评分按钮：名称 + 下次间隔时间
  Widget _ankiBtn(String label, String interval, Color c, IconData icon, int q) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: () => _rate(q),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(interval,
                  style: TextStyle(fontSize: 11, color: c.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Icon(icon, color: c, size: 20),
                const SizedBox(height: 2),
                Text(label,
                  style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
