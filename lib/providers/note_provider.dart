// AI生成 - 笔记状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import 'user_provider.dart';

final noteProvider =
    StateNotifierProvider<NoteNotifier, List<Note>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return NoteNotifier(userId);
});

class NoteNotifier extends StateNotifier<List<Note>> {
  NoteNotifier(this._userId) : super([]) { _loadNotes(); }

  final String _userId;
  final _box = Hive.box<Note>('notes');
  final _uuid = const Uuid();

  void _loadNotes() {
    state = _box.values.where((n) => n.userId == _userId).toList()..sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  Future<void> addNote({
    required String title, String content = '', String? courseId, List<String> tags = const [],
  }) async {
    final note = Note(id: _uuid.v4(), title: title, content: content, courseId: courseId, tags: tags, userId: _userId);
    await _box.put(note.id, note);
    _loadNotes();
  }

  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    await _box.put(note.id, note);
    _loadNotes();
  }

  Future<void> togglePin(String noteId) async {
    final note = _box.get(noteId);
    if (note != null) { note.isPinned = !note.isPinned; await note.save(); _loadNotes(); }
  }

  Future<void> deleteNote(String id) async { await _box.delete(id); _loadNotes(); }

  List<Note> searchNotes(String query) {
    final q = query.toLowerCase();
    return state.where((n) =>
      n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q) ||
      n.tags.any((t) => t.toLowerCase().contains(q))).toList();
  }

  List<Note> getNotesByCourse(String courseId) =>
      state.where((n) => n.courseId == courseId).toList();
}
