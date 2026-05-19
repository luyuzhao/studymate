// AI生成 - 闪卡卡组列表页（Anki 风格掌握度统计）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/flashcard.dart';
import 'flashcard_study_page.dart';
import 'flashcard_edit_page.dart';
import 'preset_decks_page.dart';
import 'word_store_page.dart';

class FlashcardListPage extends ConsumerWidget {
  const FlashcardListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(flashcardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('闪卡记忆'), actions: [
        IconButton(
          icon: const Icon(Icons.store_rounded),
          tooltip: '词库商店',
          onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const WordStorePage()))),
      ]),
      body: decks.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.style_outlined, size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('还没有卡组', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('创建卡组开始记忆吧',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: decks.length,
              itemBuilder: (_, i) => _deckCard(context, ref, decks[i])),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDeck(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新建卡组'),
      ),
    );
  }

  Widget _deckCard(BuildContext context, WidgetRef ref, FlashcardDeck deck) {
    final theme = Theme.of(context);
    final color = Color(deck.colorValue);
    final stats = ref.read(flashcardProvider.notifier).getDeckStats(deck.id);
    final dueToday = stats['due'] ?? 0;

    // 计算掌握度条各段比例
    final total = deck.totalCards;
    final newP = total > 0 ? (stats['new'] ?? 0) / total : 0.0;
    final learningP = total > 0 ? (stats['learning'] ?? 0) / total : 0.0;
    final reviewP = total > 0 ? (stats['review'] ?? 0) / total : 0.0;
    final masteredP = total > 0 ? (stats['mastered'] ?? 0) / total : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => FlashcardEditPage(deckId: deck.id))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.style, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    // ─── 四状态数量行 ───
                    Row(children: [
                      _miniChip('新${stats['new']}', Colors.blue),
                      const SizedBox(width: 4),
                      _miniChip('学${stats['learning']}', Colors.orange),
                      const SizedBox(width: 4),
                      _miniChip('复${stats['review']}', Colors.purple),
                      const SizedBox(width: 4),
                      _miniChip('掌${stats['mastered']}', Colors.green),
                    ]),
                  ],
                )),
                if (dueToday > 0)
                  FilledButton.tonal(
                    onPressed: () => Navigator.push(
                      context, MaterialPageRoute(
                        builder: (_) => FlashcardStudyPage(deckId: deck.id))),
                    child: Text('复习 $dueToday'),
                  )
                else
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context, MaterialPageRoute(
                        builder: (_) => FlashcardStudyPage(deckId: deck.id))),
                    child: const Text('浏览'),
                  ),
                const SizedBox(width: 4),
                PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Text('删除卡组')),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') {
                      ref.read(flashcardProvider.notifier).deleteDeck(deck.id);
                    }
                  }),
              ]),

              if (total > 0) ...[
                const SizedBox(height: 12),
                // ─── Anki 风格四色掌握度条 ───
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      if (newP > 0) Expanded(flex: (newP * 1000).round(),
                        child: Container(height: 6, color: Colors.blue)),
                      if (learningP > 0) Expanded(flex: (learningP * 1000).round(),
                        child: Container(height: 6, color: Colors.orange)),
                      if (reviewP > 0) Expanded(flex: (reviewP * 1000).round(),
                        child: Container(height: 6, color: Colors.purple)),
                      if (masteredP > 0) Expanded(flex: (masteredP * 1000).round(),
                        child: Container(height: 6, color: Colors.green)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Text('掌握度 ${(deck.masteryRate * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
                  const Spacer(),
                  Text('${deck.totalCards} 张 · 今日到期 $dueToday 张',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
    );
  }

  void _addDeck(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final courses = ref.read(courseProvider);
    String? courseId;
    int selColor = 0xFF27AE60;
    final colors = [
      0xFF27AE60, 0xFF4A90D9, 0xFFE74C3C, 0xFFF39C12,
      0xFF8E44AD, 0xFF16A085, 0xFFE67E22, 0xFF2C3E50,
    ];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('新建卡组', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '卡组名称 *'),
                autofocus: true),
              const SizedBox(height: 12),
              if (courses.isNotEmpty)
                DropdownButtonFormField<String?>(
                  value: courseId,
                  decoration: const InputDecoration(labelText: '关联课程 (可选)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('无')),
                    ...courses.map((c) => DropdownMenuItem(
                      value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => courseId = v)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: colors.map((c) => GestureDetector(
                  onTap: () => setState(() => selColor = c),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Color(c), shape: BoxShape.circle,
                      border: selColor == c
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    ref.read(flashcardProvider.notifier).addDeck(
                      name: nameCtrl.text.trim(),
                      courseId: courseId,
                      colorValue: selColor);
                    Navigator.pop(ctx);
                  },
                  child: const Text('创建'))),
            ],
          ),
        ),
      ),
    );
  }
}
