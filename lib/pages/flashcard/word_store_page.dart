// AI生成 - 词库商店页：内置词库 + 自定义导入（含推荐URL）
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/flashcard_provider.dart';

class WordStorePage extends ConsumerStatefulWidget {
  const WordStorePage({super.key});
  @override
  ConsumerState<WordStorePage> createState() => _WordStorePageState();
}

class _WordStorePageState extends ConsumerState<WordStorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _importing = <String>{};
  final _downloading = <String>{};

  // ─── 内置词库列表 ───
  static const _localPacks = [
    _LocalPack(
      name: '英语四级核心词汇', description: 'CET-4 大学英语四级核心高频词汇 500+',
      asset: 'assets/data/cet4_words.json', icon: Icons.looks_4_rounded,
      color: Color(0xFF2196F3), count: 500, category: '大学英语',
    ),
    _LocalPack(
      name: '英语六级核心词汇', description: 'CET-6 大学英语六级核心词汇 1500 词',
      asset: 'assets/data/cet6_words.json', icon: Icons.looks_6_rounded,
      color: Color(0xFF1565C0), count: 1500, category: '大学英语',
    ),
    _LocalPack(
      name: '考研英语核心词汇', description: '考研英语核心词汇 1500 词',
      asset: 'assets/data/postgrad_words.json', icon: Icons.school_rounded,
      color: Color(0xFFC62828), count: 1500, category: '大学英语',
    ),
    _LocalPack(
      name: '数据结构', description: '数据结构核心知识点 51 题',
      asset: 'assets/data/data_structure.json', icon: Icons.account_tree_rounded,
      color: Color(0xFF2E7D32), count: 51, category: '计算机专业课',
    ),
    _LocalPack(
      name: '计算机组成原理', description: '计算机组成原理核心知识点 40 题',
      asset: 'assets/data/computer_organization.json', icon: Icons.memory_rounded,
      color: Color(0xFFE65100), count: 40, category: '计算机专业课',
    ),
    _LocalPack(
      name: '操作系统', description: '操作系统核心知识点 49 题',
      asset: 'assets/data/operating_system.json', icon: Icons.computer_rounded,
      color: Color(0xFF6A1B9A), count: 49, category: '计算机专业课',
    ),
    _LocalPack(
      name: '计算机网络', description: '计算机网络核心知识点 45 题',
      asset: 'assets/data/computer_network.json', icon: Icons.lan_rounded,
      color: Color(0xFF00695C), count: 45, category: '计算机专业课',
    ),
  ];

  // ─── 推荐词库源（国内 CDN 加速，无需翻墙） ───
  static const _recommendedUrls = [
    _RecommendedSource(
      name: 'ECDICT 英汉词典（340万词条）',
      description: 'jsDelivr 国内镜像加速，CSV/StarDict 格式',
      url: 'https://cdn.jsdmirror.com/gh/skywind3000/ECDICT@master/',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF1565C0),
      category: '开源词典',
    ),
    _RecommendedSource(
      name: 'CET-4 / CET-6 词汇表',
      description: 'jsDelivr 加速，含四六级/考研/GRE 词表',
      url: 'https://cdn.jsdmirror.com/gh/mahavivo/english-wordlists@master/',
      icon: Icons.school_rounded,
      color: Color(0xFF2E7D32),
      category: '大学考试',
    ),
    _RecommendedSource(
      name: '考研 / TOEFL / IELTS 词汇',
      description: '多种考试词汇 TXT 合集，CDN 加速',
      url: 'https://cdn.jsdmirror.com/gh/mahavivo/english-wordlists@master/',
      icon: Icons.psychology_rounded,
      color: Color(0xFFC62828),
      category: '出国考试',
    ),
    _RecommendedSource(
      name: '47万英语单词库（dwyl）',
      description: '完整英语词典 JSON，jsDelivr 加速',
      url: 'https://cdn.jsdmirror.com/gh/dwyl/english-words@master/words_dictionary.json',
      icon: Icons.translate_rounded,
      color: Color(0xFFE65100),
      category: '综合词库',
    ),
    _RecommendedSource(
      name: '中华新华字典（成语/汉字/词语）',
      description: '成语、汉字、歇后语 JSON，CDN 加速',
      url: 'https://cdn.jsdmirror.com/gh/pwxcoo/chinese-xinhua@master/data/',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF6A1B9A),
      category: '中文词库',
    ),
    _RecommendedSource(
      name: '程序员英语词汇',
      description: 'IT/编程领域常用英语，CDN 加速',
      url: 'https://cdn.jsdmirror.com/gh/Wei-Xia/most-frequent-technology-english-words@master/',
      icon: Icons.code_rounded,
      color: Color(0xFF00695C),
      category: '专业词汇',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _importLocal(_LocalPack pack) async {
    setState(() => _importing.add(pack.name));
    try {
      await ref.read(flashcardProvider.notifier).importFromAsset(pack.asset);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入「${pack.name}」'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _importing.remove(pack.name));
    }
  }

  void _showUrlImport({String? prefillUrl}) {
    final urlCtrl = TextEditingController(text: prefillUrl);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('从 URL 导入', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('支持 JSON 和 TXT 格式，自动识别', style: Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(
              labelText: '词库文件 URL',
              hintText: 'https://cdn.jsdmirror.com/.../words.txt',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('支持的格式:', style: Theme.of(ctx).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'JSON: {"name":"...", "cards":[...]}\n'
                'TXT:  word\t释义（Tab分隔）\n'
                'TXT:  word,释义（逗号分隔）\n'
                'TXT:  word 中文释义（空格分隔）\n'
                'TXT:  每行一个单词',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 11),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () async {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final count = await ref.read(flashcardProvider.notifier).importFromUrl(url);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('导入成功！共 $count 张卡片'), behavior: SnackBarBehavior.floating),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('导入失败: $e'), behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('下载并导入'),
          )),
        ]),
      ),
    );
  }

  void _showJsonPaste() {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('粘贴导入', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('支持 JSON 或 TXT 格式，自动识别', style: Theme.of(ctx).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: textCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '粘贴内容（JSON 或 TXT）',
              hintText: 'abandon\t放弃\nability\t能力\n...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () async {
              final text = textCtrl.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                int count;
                if (text.startsWith('{') || text.startsWith('[')) {
                  count = await ref.read(flashcardProvider.notifier).importFromJsonString(text);
                } else {
                  count = await ref.read(flashcardProvider.notifier).importFromText(text);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('导入成功！共 $count 张卡片'), behavior: SnackBarBehavior.floating),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('解析失败: $e'), behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            icon: const Icon(Icons.content_paste_rounded),
            label: const Text('解析并导入'),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final notifier = ref.watch(flashcardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('词库商店'),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: '内置词库'),
            Tab(text: '自定义导入'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildLocalTab(theme, cs, notifier),
        _buildCustomTab(theme, cs),
      ]),
    );
  }

  Widget _buildLocalTab(ThemeData theme, ColorScheme cs, FlashcardNotifier notifier) {
    final categories = <String, List<_LocalPack>>{};
    for (final p in _localPacks) {
      categories.putIfAbsent(p.category, () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 顶部 Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primaryContainer, cs.secondaryContainer]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(Icons.auto_awesome, size: 36, color: cs.primary),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('内置精选词库', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('本地存储，无需网络，一键导入\n搭配 SM-2 算法高效记忆',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        ...categories.entries.map((entry) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Text(entry.key, style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold, color: cs.primary))),
            ...entry.value.map((pack) => _localPackCard(theme, pack, notifier)),
            const SizedBox(height: 12),
          ],
        )),
      ],
    );
  }

  Widget _localPackCard(ThemeData theme, _LocalPack pack, FlashcardNotifier notifier) {
    final imported = notifier.isDeckImported(pack.name);
    final isImporting = _importing.contains(pack.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: pack.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(pack.icon, color: pack.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pack.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${pack.description} · ${pack.count}词',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ])),
          const SizedBox(width: 8),
          if (imported)
            Chip(label: const Text('已导入'), avatar: const Icon(Icons.check, size: 16),
              backgroundColor: theme.colorScheme.secondaryContainer, side: BorderSide.none)
          else if (isImporting)
            const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
          else
            FilledButton.tonal(onPressed: () => _importLocal(pack), child: const Text('导入')),
        ]),
      ),
    );
  }

  Widget _buildCustomTab(ThemeData theme, ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF4A148C).withValues(alpha: 0.12),
              const Color(0xFF7B1FA2).withValues(alpha: 0.06),
            ]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Icon(Icons.tune_rounded, size: 36, color: cs.primary),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('自定义导入', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('支持 JSON 和 TXT 格式，自动识别\n从 URL 下载或粘贴文本导入',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        // ─── 操作入口 ───
        Row(children: [
          Expanded(child: _customActionCard(
            theme, cs,
            icon: Icons.link_rounded,
            color: const Color(0xFF1565C0),
            title: '从 URL 导入',
            subtitle: '输入网址下载',
            onTap: () => _showUrlImport(),
          )),
          const SizedBox(width: 10),
          Expanded(child: _customActionCard(
            theme, cs,
            icon: Icons.content_paste_rounded,
            color: const Color(0xFF6A1B9A),
            title: '粘贴导入',
            subtitle: 'JSON / TXT 均可',
            onTap: _showJsonPaste,
          )),
        ]),

        const SizedBox(height: 24),

        // ─── 推荐词库源 ───
        Text('推荐词库源（国内可访问）', style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold, color: cs.primary)),
        const SizedBox(height: 4),
        Text('点击复制链接，找到 TXT/JSON 文件后用「从 URL 导入」下载',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),

        ..._recommendedUrls.map((src) => _recommendedCard(theme, cs, src)),

        const SizedBox(height: 20),

        // ─── 格式说明 ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline_rounded, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('支持的文件格式', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            Text('TXT 格式（最常见）', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                'abandon\t放弃，遗弃\n'
                'ability\t能力，才能\n'
                'absorb\t吸收，吸引\n'
                '(支持 Tab/逗号/空格 分隔，或每行一词)',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: cs.onSurface),
              ),
            ),
            const SizedBox(height: 12),
            Text('JSON 格式', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                '{"name": "词库名",\n'
                ' "cards": [{"front":"word","back":"释义"}]}',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: cs.onSurface),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _recommendedCard(ThemeData theme, ColorScheme cs, _RecommendedSource src) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Clipboard.setData(ClipboardData(text: src.url));
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已复制: ${src.url}'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 40),
              action: SnackBarAction(label: '去导入', onPressed: () => _showUrlImport()),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: src.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(src.icon, color: src.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(src.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(src.description,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(src.url, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.primary, fontSize: 11, decoration: TextDecoration.underline)),
            ])),
            const SizedBox(width: 8),
            Icon(Icons.content_copy_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
          ]),
        ),
      ),
    );
  }

  Widget _customActionCard(ThemeData theme, ColorScheme cs, {
    required IconData icon, required Color color, required String title,
    required String subtitle, required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

// ─── 数据模型 ───
class _LocalPack {
  final String name, description, asset, category;
  final IconData icon;
  final Color color;
  final int count;
  const _LocalPack({required this.name, required this.description, required this.asset,
    required this.icon, required this.color, required this.count, required this.category});
}

class _RecommendedSource {
  final String name, description, url, category;
  final IconData icon;
  final Color color;
  const _RecommendedSource({required this.name, required this.description, required this.url,
    required this.icon, required this.color, required this.category});
}
