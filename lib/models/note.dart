// AI生成 - 笔记数据模型
import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 3)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  String? courseId;

  @HiveField(4)
  List<String> tags;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isPinned;

  @HiveField(8)
  String userId;

  Note({
    required this.id,
    required this.title,
    this.content = '',
    this.courseId,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.userId = 'guest',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
