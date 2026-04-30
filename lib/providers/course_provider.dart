// AI生成 - 课程数据状态管理，包含 GPA 计算逻辑
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/course.dart';
import 'user_provider.dart';

final courseProvider =
    StateNotifierProvider<CourseNotifier, List<Course>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return CourseNotifier(userId);
});

class CourseNotifier extends StateNotifier<List<Course>> {
  CourseNotifier(this._userId) : super([]) {
    _loadCourses();
  }

  final String _userId;
  final _box = Hive.box<Course>('courses');
  final _uuid = const Uuid();

  void _loadCourses() {
    state = _box.values.where((c) => c.userId == _userId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> addCourse({
    required String name,
    String teacher = '',
    String location = '',
    int colorValue = 0xFF4A90D9,
    double credit = 0,
    double? score,
    List<int> weekdays = const [],
    String startTime = '08:00',
    String endTime = '09:40',
  }) async {
    final course = Course(
      id: _uuid.v4(), name: name, teacher: teacher, location: location,
      colorValue: colorValue, credit: credit, score: score, weekdays: weekdays,
      startTime: startTime, endTime: endTime, userId: _userId,
    );
    await _box.put(course.id, course);
    _loadCourses();
  }

  Future<void> updateCourse(Course course) async {
    await _box.put(course.id, course);
    _loadCourses();
  }

  Future<void> deleteCourse(String id) async {
    await _box.delete(id);
    _loadCourses();
  }

  Future<void> setScore(String courseId, double score) async {
    if (score < 0 || score > 100) return;
    final course = _box.get(courseId);
    if (course != null) {
      course.score = score;
      await course.save();
      _loadCourses();
    }
  }

  double calculateGPA() {
    final scored = state.where((c) => c.score != null && c.credit > 0);
    if (scored.isEmpty) return 0;
    double totalPoints = 0, totalCredits = 0;
    for (final c in scored) {
      totalPoints += scoreToGpa(c.score!) * c.credit;
      totalCredits += c.credit;
    }
    return totalCredits == 0 ? 0 : totalPoints / totalCredits;
  }

  double calculateAverageScore() {
    final scored = state.where((c) => c.score != null).toList();
    if (scored.isEmpty) return 0;
    final total = scored.fold<double>(0, (sum, c) => sum + c.score!);
    return total / scored.length;
  }

  List<Course> getScoredCoursesByCreatedAt() {
    final scored = state.where((c) => c.score != null).toList();
    scored.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return scored;
  }

  double calculateRunningGpaByIndex(int index) {
    final scored = getScoredCoursesByCreatedAt();
    if (scored.isEmpty || index < 0 || index >= scored.length) return 0;
    final range = scored.sublist(0, index + 1);
    final totalCredits =
        range.fold<double>(0, (sum, c) => sum + (c.credit > 0 ? c.credit : 0));
    if (totalCredits == 0) return 0;
    final points = range.fold<double>(
      0,
      (sum, c) => sum + scoreToGpa(c.score!) * (c.credit > 0 ? c.credit : 0),
    );
    return points / totalCredits;
  }

  double scoreToGpa(double score) {
    if (score >= 90) return 4.0;
    if (score >= 85) return 3.7;
    if (score >= 82) return 3.3;
    if (score >= 78) return 3.0;
    if (score >= 75) return 2.7;
    if (score >= 72) return 2.3;
    if (score >= 68) return 2.0;
    if (score >= 64) return 1.5;
    if (score >= 60) return 1.0;
    return 0;
  }

  Course? getCourseById(String id) {
    try { return state.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }
}
