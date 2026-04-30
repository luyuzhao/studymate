// AI生成 - 任务/待办状态管理，支持子任务、重复任务、智能优先级
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import 'user_provider.dart';

final taskProvider =
    StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return TaskNotifier(userId);
});

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier(this._userId) : super([]) { _loadTasks(); }

  final String _userId;
  final _box = Hive.box<Task>('tasks');
  final _uuid = const Uuid();

  void _loadTasks() {
    state = _box.values.where((t) => t.userId == _userId).toList()..sort((a, b) {
      final statusOrder = {TaskStatus.inProgress: 0, TaskStatus.todo: 1, TaskStatus.done: 2};
      final cmp = statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
      if (cmp != 0) return cmp;
      return b.priority.compareTo(a.priority);
    });
  }

  Future<void> addTask({
    required String title, String description = '', DateTime? dueDate,
    String? courseId, int priority = 1, List<String> tags = const [],
    List<SubTask> subtasks = const [],
    int repeatType = 0, int repeatInterval = 1,
  }) async {
    final task = Task(id: _uuid.v4(), title: title, description: description,
      dueDate: dueDate, courseId: courseId, priority: priority, tags: tags,
      userId: _userId, subtasks: subtasks,
      repeatType: repeatType, repeatInterval: repeatInterval);
    await _box.put(task.id, task);
    _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _box.put(task.id, task);
    _loadTasks();
  }

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    final task = _box.get(taskId);
    if (task != null) {
      task.status = status;
      task.completedAt = status == TaskStatus.done ? DateTime.now() : null;
      await task.save();
      // 重复任务完成后自动生成下一期
      if (status == TaskStatus.done && task.isRecurring) {
        await _generateNextRecurrence(task);
      }
      _loadTasks();
    }
  }

  Future<void> deleteTask(String id) async {
    await _box.delete(id);
    _loadTasks();
  }

  // ─── 子任务 CRUD ───
  Future<void> addSubtask(String taskId, String title) async {
    final task = _box.get(taskId);
    if (task == null) return;
    final list = List<SubTask>.from(task.subtasks);
    list.add(SubTask(id: _uuid.v4(), title: title));
    task.subtasks = list;
    await task.save();
    _loadTasks();
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final task = _box.get(taskId);
    if (task == null) return;
    final list = List<SubTask>.from(task.subtasks);
    final idx = list.indexWhere((s) => s.id == subtaskId);
    if (idx >= 0) list[idx].done = !list[idx].done;
    task.subtasks = list;
    await task.save();
    _loadTasks();
  }

  Future<void> removeSubtask(String taskId, String subtaskId) async {
    final task = _box.get(taskId);
    if (task == null) return;
    final list = List<SubTask>.from(task.subtasks);
    list.removeWhere((s) => s.id == subtaskId);
    task.subtasks = list;
    await task.save();
    _loadTasks();
  }

  // ─── 重复任务 ───
  Future<void> _generateNextRecurrence(Task parent) async {
    if (parent.dueDate == null) return;
    final days = parent.repeatType == 2 ? 7 * parent.repeatInterval : parent.repeatInterval;
    final nextDue = parent.dueDate!.add(Duration(days: days));
    // 重置子任务为未完成
    final resetSubs = parent.subtasks.map((s) => SubTask(id: _uuid.v4(), title: s.title)).toList();
    final next = Task(
      id: _uuid.v4(), title: parent.title, description: parent.description,
      dueDate: nextDue, courseId: parent.courseId, priority: parent.priority,
      tags: parent.tags, userId: _userId, subtasks: resetSubs,
      repeatType: parent.repeatType, repeatInterval: parent.repeatInterval,
      parentId: parent.id,
    );
    await _box.put(next.id, next);
  }

  // ─── 查询 ───
  List<Task> getTasksByStatus(TaskStatus s) => state.where((t) => t.status == s).toList();
  List<Task> getTasksByCourse(String cid) => state.where((t) => t.courseId == cid).toList();
  List<Task> getOverdueTasks() => state.where((t) => t.isOverdue).toList();

  List<Task> getTodayTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return state.where((t) =>
      t.status != TaskStatus.done &&
      t.dueDate != null && t.dueDate!.isBefore(tomorrow) && t.dueDate!.isAfter(today.subtract(const Duration(seconds: 1)))
    ).toList();
  }

  /// 智能优先级建议：今日最需关注的任务列表
  /// 排序规则: 逾期 > 今天到期 > 高优先级 > 有子任务进度的
  List<Task> getSuggestedTasks() {
    final active = state.where((t) => t.status != TaskStatus.done).toList();
    active.sort((a, b) {
      // 逾期最优先
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      // 今日到期次之
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final aToday = a.dueDate != null && a.dueDate!.isBefore(tomorrow) && a.dueDate!.isAfter(today);
      final bToday = b.dueDate != null && b.dueDate!.isBefore(tomorrow) && b.dueDate!.isAfter(today);
      if (aToday && !bToday) return -1;
      if (!aToday && bToday) return 1;
      // 优先级
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);
      // 有截止日期的优先
      if (a.dueDate != null && b.dueDate == null) return -1;
      if (a.dueDate == null && b.dueDate != null) return 1;
      if (a.dueDate != null && b.dueDate != null) return a.dueDate!.compareTo(b.dueDate!);
      return 0;
    });
    return active.take(5).toList();
  }
}
