// AI生成 - 番茄钟专注页，支持中断记录、每日目标、专注模式
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/pomodoro_provider.dart';

class PomodoroPage extends ConsumerStatefulWidget {
  const PomodoroPage({super.key});
  @override
  ConsumerState<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends ConsumerState<PomodoroPage> {
  int _totalSec = 25 * 60, _remainSec = 25 * 60;
  bool _running = false, _isBreak = false;
  bool _focusMode = false; // 专注模式（简化UI）
  Timer? _timer;
  DateTime? _startTime;
  int _selDur = 25;
  int _interruptions = 0; // 当前轮中断计数
  final _opts = [15, 25, 30, 45, 60];

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _start() {
    _startTime = DateTime.now();
    _interruptions = 0;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { setState(() { if (_remainSec > 0) _remainSec--; else _complete(); }); });
  }

  void _pause() { _timer?.cancel(); setState(() => _running = false); }

  void _reset() { _timer?.cancel(); setState(() { _running = false; _remainSec = _totalSec; _isBreak = false; _interruptions = 0; }); }

  void _recordInterrupt() {
    setState(() => _interruptions++);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已记录第 $_interruptions 次中断'), duration: const Duration(seconds: 1)));
  }

  void _complete() {
    _timer?.cancel(); setState(() => _running = false);
    if (!_isBreak && _startTime != null) {
      ref.read(pomodoroRecordProvider.notifier).addRecord(
        durationMinutes: _selDur, startTime: _startTime!, endTime: DateTime.now(),
        completed: true, interruptions: _interruptions,
      );
      showDialog(context: context, builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration, size: 48, color: Colors.amber),
        title: const Text('专注完成！'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('你完成了 $_selDur 分钟的专注，休息一下吧！'),
          if (_interruptions > 0) ...[const SizedBox(height: 8),
            Text('本次中断 $_interruptions 次', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500))],
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('好的'))]));
    }
    setState(() {
      _interruptions = 0;
      if (!_isBreak) { _isBreak = true; _totalSec = 5 * 60; _remainSec = 5 * 60; }
      else { _isBreak = false; _totalSec = _selDur * 60; _remainSec = _selDur * 60; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(pomodoroRecordProvider.notifier);
    final todayMin = notifier.todayMinutes;
    final todaySes = notifier.todaySessions;
    final todayInts = notifier.todayInterruptions;
    final weekMin = notifier.weekMinutes;
    final weekDist = notifier.getWeeklyDistribution();
    final dailyGoal = ref.watch(dailyGoalProvider);
    ref.watch(pomodoroRecordProvider);

    final progress = _totalSec > 0 ? (_totalSec - _remainSec) / _totalSec : 0.0;
    final min = _remainSec ~/ 60, sec = _remainSec % 60;
    final goalProgress = dailyGoal > 0 ? (todayMin / dailyGoal).clamp(0.0, 1.0) : 0.0;

    // 专注模式：只显示计时器和控制按钮
    if (_focusMode && _running) return _buildFocusMode(theme, progress, min, sec);

    return Scaffold(
      appBar: AppBar(title: const Text('番茄专注'), actions: [
        IconButton(icon: Icon(_focusMode ? Icons.fullscreen_exit : Icons.fullscreen),
          tooltip: _focusMode ? '退出专注模式' : '进入专注模式',
          onPressed: () => setState(() => _focusMode = !_focusMode)),
        IconButton(icon: const Icon(Icons.flag_outlined), tooltip: '设置每日目标',
          onPressed: () => _showGoalDialog(context)),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // 每日目标进度条
        _buildGoalProgress(theme, todayMin, dailyGoal, goalProgress),
        const SizedBox(height: 20),
        // 计时器
        CircularPercentIndicator(radius: 120, lineWidth: 14, percent: progress.clamp(0.0, 1.0),
          center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_isBreak ? '休息时间' : '专注时间', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text('${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
              style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, fontFamily: 'monospace', color: _isBreak ? Colors.green : theme.colorScheme.primary)),
            if (_running && _interruptions > 0) Text('中断 $_interruptions 次', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
          ]),
          progressColor: _isBreak ? Colors.green : theme.colorScheme.primary, backgroundColor: theme.colorScheme.surfaceContainerHighest, circularStrokeCap: CircularStrokeCap.round, animation: false),
        const SizedBox(height: 20),
        if (!_running && !_isBreak) Wrap(spacing: 8, children: _opts.map((d) => ChoiceChip(label: Text('$d 分钟'), selected: _selDur == d,
          onSelected: (_) => setState(() { _selDur = d; _totalSec = d * 60; _remainSec = d * 60; }))).toList()),
        const SizedBox(height: 20),
        // 控制按钮区
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_running || _remainSec != _totalSec) IconButton.outlined(onPressed: _reset, icon: const Icon(Icons.stop), iconSize: 32),
          const SizedBox(width: 12),
          FloatingActionButton.large(heroTag: 'pomo', onPressed: _running ? _pause : _start, child: Icon(_running ? Icons.pause : Icons.play_arrow, size: 40)),
          const SizedBox(width: 12),
          if (_running && !_isBreak) IconButton.filled(
            onPressed: _recordInterrupt, icon: const Icon(Icons.front_hand_outlined), iconSize: 28,
            tooltip: '记录中断', style: IconButton.styleFrom(backgroundColor: Colors.orange.shade100, foregroundColor: Colors.orange.shade800)),
        ]),
        const Divider(height: 32),
        // 统计卡片
        Row(children: [
          Expanded(child: _Stat(label: '今日专注', value: '$todayMin 分钟', icon: Icons.timer, color: theme.colorScheme.primary)),
          const SizedBox(width: 8),
          Expanded(child: _Stat(label: '今日番茄', value: '$todaySes 个', icon: Icons.local_fire_department, color: Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _Stat(label: '今日中断', value: '$todayInts 次', icon: Icons.front_hand, color: Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _Stat(label: '本周总计', value: '$weekMin 分', icon: Icons.date_range, color: Colors.green)),
        ]),
        const SizedBox(height: 24),
        if (weekDist.values.any((v) => v > 0)) ...[
          Align(alignment: Alignment.centerLeft, child: Text('本周专注分布', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (weekDist.values.fold<int>(0, (a, b) => a > b ? a : b) * 1.2).toDouble().clamp(30, double.infinity),
            titlesData: FlTitlesData(show: true,
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                const d = ['一', '二', '三', '四', '五', '六', '日'];
                final i = v.toInt() - 1;
                return i >= 0 && i < d.length ? Padding(padding: const EdgeInsets.only(top: 8), child: Text(d[i], style: const TextStyle(fontSize: 12))) : const SizedBox();
              })),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false), gridData: const FlGridData(show: false),
            barGroups: weekDist.entries.map((e) => BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(toY: e.value.toDouble(), color: theme.colorScheme.primary, width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))])).toList(),
          ))),
        ],
      ])));
  }

  /// 每日目标进度条
  Widget _buildGoalProgress(ThemeData theme, int todayMin, int goal, double goalProgress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: goalProgress >= 1.0 ? Colors.green.withValues(alpha: 0.08) : theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(goalProgress >= 1.0 ? Icons.emoji_events : Icons.flag, size: 20, color: goalProgress >= 1.0 ? Colors.green : theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('每日目标', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('$todayMin / $goal 分钟', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600,
            color: goalProgress >= 1.0 ? Colors.green : theme.colorScheme.primary)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: goalProgress, minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: goalProgress >= 1.0 ? Colors.green : theme.colorScheme.primary)),
        if (goalProgress >= 1.0) ...[const SizedBox(height: 6),
          Text('🎉 已达成今日目标！', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontWeight: FontWeight.bold))],
      ]),
    );
  }

  /// 专注模式 - 极简全屏UI
  Widget _buildFocusMode(ThemeData theme, double progress, int min, int sec) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: GestureDetector(
        onDoubleTap: () => setState(() => _focusMode = false),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularPercentIndicator(radius: 140, lineWidth: 16, percent: progress.clamp(0.0, 1.0),
            center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(_isBreak ? '休息' : '专注', style: const TextStyle(color: Colors.white54, fontSize: 16)),
              Text('${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              if (_interruptions > 0) Text('中断 $_interruptions', style: TextStyle(color: Colors.orange.shade300, fontSize: 14)),
            ]),
            progressColor: _isBreak ? Colors.green : Colors.blue, backgroundColor: Colors.white12, circularStrokeCap: CircularStrokeCap.round, animation: false),
          const SizedBox(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: _reset, icon: const Icon(Icons.stop, color: Colors.white54), iconSize: 36),
            const SizedBox(width: 24),
            FloatingActionButton.large(heroTag: 'pomo_focus', backgroundColor: Colors.white12,
              onPressed: _running ? _pause : _start, child: Icon(_running ? Icons.pause : Icons.play_arrow, size: 44, color: Colors.white)),
            const SizedBox(width: 24),
            if (_running && !_isBreak) IconButton(onPressed: _recordInterrupt,
              icon: Icon(Icons.front_hand_outlined, color: Colors.orange.shade300), iconSize: 36),
          ]),
          const SizedBox(height: 32),
          Text('双击屏幕退出专注模式', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
        ])),
      ),
    );
  }

  /// 设置每日目标弹窗
  void _showGoalDialog(BuildContext context) {
    final ctrl = TextEditingController(text: ref.read(dailyGoalProvider).toString());
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('设置每日专注目标'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '目标分钟数', suffixText: '分钟')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () {
          final v = int.tryParse(ctrl.text);
          if (v != null && v > 0 && v <= 600) {
            ref.read(dailyGoalProvider.notifier).setGoal(v);
            Navigator.pop(ctx);
          }
        }, child: const Text('确定')),
      ],
    ));
  }
}

class _Stat extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [Icon(icon, color: color, size: 18), const SizedBox(height: 4),
        Text(value, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)), Text(label, style: theme.textTheme.labelSmall)]));
  }
}
