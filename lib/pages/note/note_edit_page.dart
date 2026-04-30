// AI生成 - 笔记编辑页，支持 Markdown 编辑和快捷工具栏
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/note_provider.dart';
import '../../providers/course_provider.dart';

class NoteEditPage extends ConsumerStatefulWidget {
  final String? noteId;
  const NoteEditPage({super.key, this.noteId});
  @override
  ConsumerState<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends ConsumerState<NoteEditPage> {
  late TextEditingController _titleCtrl, _contentCtrl;
  String? _courseId;
  bool _isNew = true, _init = false;

  @override
  void initState() { super.initState(); _titleCtrl = TextEditingController(); _contentCtrl = TextEditingController(); }
  @override
  void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  void _load() {
    if (widget.noteId != null) {
      final note = ref.read(noteProvider).where((n) => n.id == widget.noteId).firstOrNull;
      if (note != null) { _isNew = false; _titleCtrl.text = note.title; _contentCtrl.text = note.content; _courseId = note.courseId; }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_init) { _load(); _init = true; }
    final theme = Theme.of(context);
    final courses = ref.watch(courseProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? '新建笔记' : '编辑笔记'), actions: [
        if (!_isNew) IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { ref.read(noteProvider.notifier).deleteNote(widget.noteId!); Navigator.pop(context); }),
        IconButton(icon: const Icon(Icons.check), onPressed: _save)]),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _titleCtrl, style: theme.textTheme.titleLarge,
          decoration: InputDecoration(hintText: '笔记标题', border: InputBorder.none, hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)))),
        if (courses.isNotEmpty) SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
          FilterChip(label: const Text('无课程'), selected: _courseId == null, onSelected: (_) => setState(() => _courseId = null), visualDensity: VisualDensity.compact),
          const SizedBox(width: 8),
          ...courses.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
            label: Text(c.name), selected: _courseId == c.id, onSelected: (_) => setState(() => _courseId = c.id),
            visualDensity: VisualDensity.compact, avatar: CircleAvatar(backgroundColor: Color(c.colorValue), radius: 6)))),
        ])),
        const Divider(height: 24),
        Expanded(child: TextField(controller: _contentCtrl, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(hintText: '开始记录...\n\n支持 Markdown 格式:\n# 标题\n- 列表\n**加粗** *斜体*', border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4))))),
      ])),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant))),
        child: SafeArea(child: Row(children: [
          _md('H1', () => _insert('# ')), _md('H2', () => _insert('## ')), _md('B', () => _wrap('**')), _md('I', () => _wrap('*')),
          _md('•', () => _insert('- ')), _md('[]', () => _insert('- [ ] ')), _md('``', () => _wrap('`')), _md('>', () => _insert('> ')),
        ]))),
    );
  }

  Widget _md(String label, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Theme.of(context).colorScheme.onSurfaceVariant))));

  void _insert(String text) {
    final s = _contentCtrl.selection;
    _contentCtrl.text = _contentCtrl.text.replaceRange(s.start, s.end, text);
    _contentCtrl.selection = TextSelection.collapsed(offset: s.start + text.length);
  }

  void _wrap(String w) {
    final s = _contentCtrl.selection;
    final sel = _contentCtrl.text.substring(s.start, s.end);
    _contentCtrl.text = _contentCtrl.text.replaceRange(s.start, s.end, '$w$sel$w');
    _contentCtrl.selection = TextSelection.collapsed(offset: s.start + w.length + sel.length + w.length);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text;
    if (title.isEmpty && content.isEmpty) { Navigator.pop(context); return; }
    if (_isNew) {
      ref.read(noteProvider.notifier).addNote(title: title.isEmpty ? '无标题' : title, content: content, courseId: _courseId);
    } else {
      final note = ref.read(noteProvider).where((n) => n.id == widget.noteId).firstOrNull;
      if (note != null) { note.title = title.isEmpty ? '无标题' : title; note.content = content; note.courseId = _courseId; ref.read(noteProvider.notifier).updateNote(note); }
    }
    Navigator.pop(context);
  }
}
