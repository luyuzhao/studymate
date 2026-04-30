// AI生成 - 笔记列表页，支持搜索、置顶、按课程筛选
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/note_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/note.dart';
import 'note_edit_page.dart';

class NoteListPage extends ConsumerStatefulWidget {
  const NoteListPage({super.key});
  @override
  ConsumerState<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends ConsumerState<NoteListPage> {
  String _query = '';
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(noteProvider);
    final theme = Theme.of(context);
    final notes = _query.isEmpty ? allNotes : ref.read(noteProvider.notifier).searchNotes(_query);

    return Scaffold(
      appBar: AppBar(
        title: _searching ? TextField(autofocus: true, decoration: const InputDecoration(hintText: '搜索笔记...', border: InputBorder.none), onChanged: (v) => setState(() => _query = v)) : const Text('我的笔记'),
        actions: [IconButton(icon: Icon(_searching ? Icons.close : Icons.search), onPressed: () => setState(() { _searching = !_searching; if (!_searching) _query = ''; }))]),
      body: notes.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.note_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.4)),
              const SizedBox(height: 16), Text(_query.isEmpty ? '还没有笔记' : '未找到相关笔记', style: theme.textTheme.titleMedium)]))
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: notes.length,
              itemBuilder: (_, i) => _noteCard(context, ref, notes[i])),
      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditPage())), child: const Icon(Icons.add)),
    );
  }

  Widget _noteCard(BuildContext context, WidgetRef ref, Note note) {
    final theme = Theme.of(context);
    final course = note.courseId != null ? ref.read(courseProvider.notifier).getCourseById(note.courseId!) : null;
    return Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditPage(noteId: note.id))),
      borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (note.isPinned) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary)),
          Expanded(child: Text(note.title.isEmpty ? '无标题' : note.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          PopupMenuButton(itemBuilder: (_) => [PopupMenuItem(value: 'pin', child: Text(note.isPinned ? '取消置顶' : '置顶')), const PopupMenuItem(value: 'delete', child: Text('删除'))],
            onSelected: (v) { if (v == 'pin') ref.read(noteProvider.notifier).togglePin(note.id); else if (v == 'delete') ref.read(noteProvider.notifier).deleteNote(note.id); }),
        ]),
        if (note.content.isNotEmpty) ...[const SizedBox(height: 6),
          Text(note.content, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 3, overflow: TextOverflow.ellipsis)],
        const SizedBox(height: 8),
        Row(children: [
          if (course != null) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Color(course.colorValue).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(course.name, style: TextStyle(fontSize: 11, color: Color(course.colorValue)))), const SizedBox(width: 8)],
          Text(DateFormat('MM/dd HH:mm').format(note.updatedAt), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ]))));
  }
}
