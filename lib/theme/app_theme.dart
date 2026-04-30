// AI生成 - 大厂级 Material Design 3 主题配置
// 灵感来源：Linear / Notion / 飞书 — 克制、高级、专业
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── 品牌色 ───
  // 主色调：沉稳靛蓝 (Linear 风格)
  static const Color brandPrimary = Color(0xFF5B5FC7);
  // 辅助色
  static const Color _secondary = Color(0xFF6B7280);
  static const Color _tertiary = Color(0xFF8B5CF6);

  // ─── 各功能模块专属色（饱和度适中，不刺眼） ───
  static const Color courseColor    = Color(0xFF3B82F6); // 课程-蓝
  static const Color taskColor      = Color(0xFFF59E0B); // 任务-琥珀
  static const Color pomodoroColor  = Color(0xFFEF4444); // 番茄-红
  static const Color flashcardColor = Color(0xFF10B981); // 闪卡-翠绿
  static const Color noteColor      = Color(0xFF8B5CF6); // 笔记-紫
  static const Color habitColor     = Color(0xFF14B8A6); // 习惯-青
  static const Color expenseColor   = Color(0xFFF97316); // 记账-橙

  // ─── 亮色主题 ───
  static final lightColorScheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    secondary: _secondary,
    tertiary: _tertiary,
    brightness: Brightness.light,
    surface: const Color(0xFFF9FAFB),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF3F4F6),
    surfaceContainer: const Color(0xFFE5E7EB),
  );

  // ─── 深色主题 ───
  static final darkColorScheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    secondary: _secondary,
    tertiary: _tertiary,
    brightness: Brightness.dark,
    surface: const Color(0xFF111318),
    surfaceContainerLowest: const Color(0xFF0D0F14),
    surfaceContainerLow: const Color(0xFF1A1D24),
    surfaceContainer: const Color(0xFF23262F),
  );

  static ThemeData get lightTheme => _buildTheme(lightColorScheme);
  static ThemeData get darkTheme => _buildTheme(darkColorScheme);

  static ThemeData _buildTheme(ColorScheme cs) {
    final isLight = cs.brightness == Brightness.light;
    // 使用系统默认字体 + Google Fonts fallback
    final baseText = GoogleFonts.notoSansScTextTheme(
      isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme,
    );
    // 微调字重层级
    final textTheme = baseText.copyWith(
      headlineLarge: baseText.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: baseText.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineSmall: baseText.headlineSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: baseText.bodyLarge?.copyWith(height: 1.6),
      bodyMedium: baseText.bodyMedium?.copyWith(height: 1.5),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );

    final dividerColor = isLight ? const Color(0xFFE5E7EB) : const Color(0xFF2D3139);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: textTheme,
      scaffoldBackgroundColor: cs.surface,
      dividerColor: dividerColor,
      splashFactory: InkSparkle.splashFactory,

      // ─── AppBar：无阴影，干净 ───
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),

      // ─── 卡片：微阴影 + 边框，高级感 ───
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: dividerColor, width: 1),
        ),
        color: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // ─── FAB ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),

      // ─── 输入框：精致边框 ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : cs.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.4)),
      ),

      // ─── 底部导航栏 ───
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: cs.primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 24);
          }
          return IconThemeData(color: cs.onSurface.withValues(alpha: 0.5), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: cs.primary, fontWeight: FontWeight.w600, fontSize: 11);
          }
          return textTheme.labelSmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.5), fontSize: 11);
        }),
      ),

      // ─── NavigationRail（桌面端） ───
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        indicatorColor: cs.primary.withValues(alpha: 0.12),
        selectedIconTheme: IconThemeData(color: cs.primary),
        unselectedIconTheme: IconThemeData(color: cs.onSurface.withValues(alpha: 0.5)),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: cs.primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.5)),
      ),

      // ─── Chip：圆润精致 ───
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: dividerColor),
        backgroundColor: cs.surfaceContainerLow,
        labelStyle: textTheme.labelMedium,
      ),

      // ─── 按钮 ───
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide(color: dividerColor),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ─── 对话框 ───
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Colors.transparent,
        backgroundColor: cs.surfaceContainerLowest,
      ),

      // ─── 底部弹出面板 ───
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // ─── ListTile ───
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ─── Divider ───
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ─── TabBar ───
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
        dividerHeight: 1,
        dividerColor: dividerColor,
      ),

      // ─── SnackBar ───
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
      ),
    );
  }
}
