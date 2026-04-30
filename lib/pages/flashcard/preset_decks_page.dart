// AI生成 - 预置题库页面
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/flashcard_provider.dart';

class PresetDecksPage extends ConsumerStatefulWidget {
  const PresetDecksPage({super.key});

  @override
  ConsumerState<PresetDecksPage> createState() => _PresetDecksPageState();
}

class _PresetDecksPageState extends ConsumerState<PresetDecksPage> {
  final _importing = <String>{};

  static const _presets = [
    _PresetInfo(
      name: '英语六级核心词汇',
      description: 'CET-6 大学英语六级核心词汇 1500 词',
      asset: 'assets/data/cet6_words.json',
      icon: Icons.language,
      color: Color(0xFF1565C0),
      count: 1500,
      category: '英语词汇',
    ),
    _PresetInfo(
      name: '考研英语核心词汇',
      description: '考研英语核心词汇 1500 词',
      asset: 'assets/data/postgrad_words.json',
      icon: Icons.school,
      color: Color(0xFFC62828),
      count: 1500,
      category: '英语词汇',
    ),
    _PresetInfo(
      name: '数据结构',
      description: '数据结构核心知识点 51 题',
      asset: 'assets/data/data_structure.json',
      icon: Icons.account_tree,
      color: Color(0xFF2E7D32),
      count: 51,
      category: '计算机专业课',
    ),
    _PresetInfo(
      name: '计算机组成原理',
      description: '计算机组成原理核心知识点 40 题',
      asset: 'assets/data/computer_organization.json',
      icon: Icons.memory,
      color: Color(0xFFE65100),
      count: 40,
      category: '计算机专业课',
    ),
    _PresetInfo(
      name: '操作系统',
      description: '操作系统核心知识点 49 题',
      asset: 'assets/data/operating_system.json',
      icon: Icons.computer,
      color: Color(0xFF6A1B9A),
      count: 49,
      category: '计算机专业课',
    ),
    _PresetInfo(
      name: '计算机网络',
      description: '计算机网络核心知识点 45 题',
      asset: 'assets/data/computer_network.json',
      icon: Icons.lan,
      color: Color(0xFF00695C),
      count: 45,
      category: '计算机专业课',
    ),
  ];

  Future<void> _importDeck(_PresetInfo preset) async {
    setState(() => _importing.add(preset.name));
    try {
      await ref.read(flashcardProvider.notifier).importFromAsset(preset.asset);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入「${preset.name}」(${preset.count}张卡片)'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _importing.remove(preset.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.watch(flashcardProvider.notifier);

    // 按分类分组
    final categories = <String, List<_PresetInfo>>{};
    for (final p in _presets) {
      categories.putIfAbsent(p.category, () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('预置题库')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Icon(Icons.auto_awesome, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('精选题库', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('涵盖英语词汇和计算机专业课核心知识点\n一键导入，搭配 SM-2 算法高效记忆', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),
          ...categories.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(entry.key, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ),
              ...entry.value.map((preset) {
                final imported = notifier.isDeckImported(preset.name);
                final isImporting = _importing.contains(preset.name);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: preset.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(preset.icon, color: preset.color, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(preset.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(preset.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ])),
                      const SizedBox(width: 8),
                      if (imported)
                        Chip(
                          label: const Text('已导入'),
                          avatar: const Icon(Icons.check, size: 16),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          side: BorderSide.none,
                        )
                      else if (isImporting)
                        const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        FilledButton.tonal(
                          onPressed: () => _importDeck(preset),
                          child: const Text('导入'),
                        ),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          )),
        ],
      ),
    );
  }
}

class _PresetInfo {
  final String name;
  final String description;
  final String asset;
  final IconData icon;
  final Color color;
  final int count;
  final String category;
  const _PresetInfo({required this.name, required this.description, required this.asset, required this.icon, required this.color, required this.count, required this.category});
}
