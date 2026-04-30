// AI生成 - 应用主框架页，自适应导航（桌面 Rail / 移动 Bar）+ 页面切换动画
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'home/dashboard_page.dart';
import 'course/course_list_page.dart';
import 'task/task_board_page.dart';
import 'pomodoro/pomodoro_page.dart';
import 'profile/profile_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _currentIndex = 0;

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, '首页'),
    _NavItem(Icons.school_outlined, Icons.school_rounded, '课程'),
    _NavItem(Icons.task_alt_outlined, Icons.task_alt_rounded, '待办'),
    _NavItem(Icons.timer_outlined, Icons.timer_rounded, '专注'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, '我的'),
  ];

  static const _pages = [
    DashboardPage(),
    CourseListPage(),
    TaskBoardPage(),
    PomodoroPage(),
    ProfilePage(),
  ];

  void _onDestinationSelected(int index) {
    if (index != _currentIndex) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 720;
    final theme = Theme.of(context);

    final pageView = PageTransitionSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, primaryAnim, secondaryAnim) =>
          FadeThroughTransition(
            animation: primaryAnim,
            secondaryAnimation: secondaryAnim,
            child: child,
          ),
      child: KeyedSubtree(
        key: ValueKey<int>(_currentIndex),
        child: _pages[_currentIndex],
      ),
    );

    if (useRail) {
      // ─── 桌面端：左侧 NavigationRail ───
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 12),
                child: Icon(Icons.auto_stories_rounded,
                    color: theme.colorScheme.primary, size: 32),
              ),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.activeIcon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
            Expanded(child: pageView),
          ],
        ),
      );
    }

    // ─── 移动端：底部 NavigationBar ───
    return Scaffold(
      body: pageView,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: _navItems
                .map((item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: item.label,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
