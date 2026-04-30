// AI生成 - 闪卡编辑页（Anki 风格：显示卡片状态、间隔、下次复习）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/flashcard_provider.dart';
import '../../models/flashcard.dart';
import 'flashcard_study_page.dart';

class FlashcardEditPage extends ConsumerWidget {
  final String deckId;
  const FlashcardEditPage({super.key, required this.deckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(flashcardProvider);
    final deck = decks.where((d) => d.id == deckId).firstOrNull;
    if (deck == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('卡组不存在')));

    final theme = Theme.of(context);
    final needsReview = ref.read(flashcardProvider.notifier).getCardsNeedingReview(deckId);
    final stats = ref.read(flashcardProvider.notifier).getDeckStats(deckId);

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          // ─── 卡组统计微标 ───
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniBadge('新${stats['new']}', Colors.blue),
                const SizedBox(width: 4),
                _miniBadge('学${stats['learning']}', Colors.orange),
                const SizedBox(width: 4),
                _miniBadge('复${stats['review']}', Colors.purple),
                const SizedBox(width: 4),
                _miniBadge('掌${stats['mastered']}', Colors.green),
              ],
            ),
          ),
          if (needsReview.isNotEmpty)
            FilledButton.tonal(
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => FlashcardStudyPage(deckId: deckId))),
              child: Text('复习 ${needsReview.length}'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: deck.cards.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.note_add_outlined, size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text('卡组为空，添加卡片开始学习',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deck.cards.length,
              itemBuilder: (_, i) {
                final card = deck.cards[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: _statusBadge(card),
                    title: Text(card.front, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.back, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        // ─── 间隔信息 ───
                        Row(children: [
                          Icon(Icons.schedule, size: 12,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            card.nextReviewDate != null
                              ? _fmtNextReview(card.nextReviewDate!)
                              : '尚未学习',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(width: 12),
                          Text('EF ${card.easeFactor.toStringAsFixed(2)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                          ),
                        ]),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => ref.read(flashcardProvider.notifier).deleteCard(deckId, card.id)),
                  ),
                );
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCard(context, ref),
        child: const Icon(Icons.add)),
    );
  }

  Widget _statusBadge(Flashcard card) {
    Color c;
    switch (card.status) {
      case CardStatus.isNew: c = Colors.blue; break;
      case CardStatus.learning: c = Colors.orange; break;
      case CardStatus.review: c = Colors.purple; break;
      case CardStatus.mastered: c = Colors.green; break;
    }
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Text(card.statusLabel,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c))),
    );
  }

  Widget _miniBadge(String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
    );
  }

  String _fmtNextReview(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inMinutes < 0) return '已到期';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分后';
    if (diff.inHours < 24) return '${diff.inHours}小时后';
    if (diff.inDays == 1) return '明天';
    if (diff.inDays < 30) return '${diff.inDays}天后';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()}月后';
    return '${(diff.inDays / 365).round()}年后';
  }

  void _addCard(BuildContext context, WidgetRef ref) {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('添加卡片', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: frontCtrl,
            decoration: const InputDecoration(labelText: '正面 (问题) *'),
            autofocus: true, maxLines: 3, minLines: 1),
          const SizedBox(height: 12),
          TextField(controller: backCtrl,
            decoration: const InputDecoration(labelText: '背面 (答案) *'),
            maxLines: 3, minLines: 1),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () {
              if (frontCtrl.text.trim().isEmpty || backCtrl.text.trim().isEmpty) return;
              ref.read(flashcardProvider.notifier).addCard(deckId,
                front: frontCtrl.text.trim(), back: backCtrl.text.trim());
              frontCtrl.clear(); backCtrl.clear();
            }, child: const Text('添加并继续'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () {
              if (frontCtrl.text.trim().isEmpty || backCtrl.text.trim().isEmpty) return;
              ref.read(flashcardProvider.notifier).addCard(deckId,
                front: frontCtrl.text.trim(), back: backCtrl.text.trim());
              Navigator.pop(ctx);
            }, child: const Text('添加并关闭'))),
          ]),
        ])));
  }
}
