
import 'package:flutter/material.dart';

import '../tasks/task_screen.dart';
import 'dashboard_home.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  int _dashboardVersion = 0;
  int _taskVersion = 0;

  void _handleBack(bool didPop) {
    if (didPop) return;

    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
        _dashboardVersion++;
      });
    }
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;

      if (index == 0) {
        _dashboardVersion++;
      }

      if (index == 1) {
        _taskVersion++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        _handleBack(didPop);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardHome(
              key: ValueKey('dashboard_$_dashboardVersion'),
            ),
            TaskScreen(
              key: ValueKey('tasks_$_taskVersion'),
            ),
            const NotificationScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist),
              selectedIcon: Icon(Icons.checklist),
              label: 'Công việc',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Thông báo',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
