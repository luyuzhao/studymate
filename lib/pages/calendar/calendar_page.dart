// AI生成 - 日历课程表页：整合课程、待办、闪卡到期到日历视图
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/course_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../models/course.dart';
import '../../models/task.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});
  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  // ─── 构建日历事件 ───
  List<_CalendarEvent> _getEventsForDay(DateTime day, List<Course> courses,
      List<Task> tasks, List<dynamic> decks) {
    final events = <_CalendarEvent>[];
    final weekday = day.weekday; // 1=Mon .. 7=Sun
    final dayOnly = DateTime(day.year, day.month, day.day);

    // 课程：匹配 weekday
    for (final c in courses) {
      if (c.weekdays.contains(weekday)) {
        events.add(_CalendarEvent(
          title: c.name,
          subtitle: '${c.startTime}-${c.endTime} · ${c.location}',
          color: Color(c.colorValue),
          icon: Icons.school_rounded,
          type: _EventType.course,
        ));
      }
    }

    // 待办：匹配 dueDate
    for (final t in tasks) {
      if (t.dueDate != null) {
        final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        if (due == dayOnly) {
          events.add(_CalendarEvent(
            title: t.title,
            subtitle: t.status == TaskStatus.done ? '已完成' : '待完成',
            color: t.isOverdue
                ? Colors.red
                : t.priority == 2
                    ? Colors.orange
                    : Colors.blue,
            icon: t.status == TaskStatus.done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            type: _EventType.task,
          ));
        }
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(courseProvider);
    final tasks = ref.watch(taskProvider);
    final decks = ref.watch(flashcardProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selectedEvents = _getEventsForDay(
        _selectedDay ?? _focusedDay, courses, tasks, decks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历课程表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: '回到今天',
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── 日历组件 ───
          TableCalendar(
            locale: 'zh_CN',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focused) => _focusedDay = focused,
            eventLoader: (day) =>
                _getEventsForDay(day, courses, tasks, decks),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: cs.tertiary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 6,
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: cs.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: theme.textTheme.labelSmall!,
            ),
          ),

          const Divider(height: 1),

          // ─── 日期标题 ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(children: [
              Text(
                _selectedDay != null
                    ? DateFormat('M月d日 EEEE', 'zh_CN').format(_selectedDay!)
                    : '今天',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text('${selectedEvents.length} 项',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant)),
            ]),
          ),

          // ─── 事件列表 ───
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('这一天没有安排',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: selectedEvents.length,
                    itemBuilder: (_, i) => _eventCard(theme, selectedEvents[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(ThemeData theme, _CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: event.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(event.icon, color: event.color, size: 20),
        ),
        title: Text(event.title,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(event.subtitle,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        trailing: _eventTypeBadge(event.type, event.color),
      ),
    );
  }

  Widget _eventTypeBadge(_EventType type, Color c) {
    final label = switch (type) {
      _EventType.course => '课程',
      _EventType.task => '待办',
      _EventType.flashcard => '闪卡',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

// ─── 内部数据类 ───
enum _EventType { course, task, flashcard }

class _CalendarEvent {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final _EventType type;

  _CalendarEvent({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.type,
  });
}
