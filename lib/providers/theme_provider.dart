// AI生成 - 主题状态管理，支持亮色/深色/跟随系统切换，持久化到 Hive
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _key = 'theme_mode';
  final _box = Hive.box('settings');

  void _loadTheme() {
    final index = _box.get(_key, defaultValue: 0) as int;
    state = ThemeMode.values[index];
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _box.put(_key, mode.index);
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}
