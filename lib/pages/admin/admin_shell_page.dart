import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'admin_classes_page.dart';
import 'admin_materials_page.dart';
import 'admin_quiz_page.dart';
import 'admin_students_page.dart';
import 'admin_usage_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Classes & Subjects',
    'Study Materials',
    'Quiz Bank',
    'Students',
    'Usage',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      AdminClassesPage(admin: widget.admin),
      AdminMaterialsPage(admin: widget.admin),
      AdminQuizPage(admin: widget.admin),
      AdminStudentsPage(admin: widget.admin),
      AdminUsagePage(admin: widget.admin),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EDFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: AuthService.instance.signOut,
              icon: const Icon(Icons.logout_rounded, size: 20),
              tooltip: 'Logout',
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.pageBackgroundGradient,
        ),
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE8EDF5), width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int value) =>
              setState(() => _index = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.class_outlined),
              selectedIcon: Icon(Icons.class_),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Materials',
            ),
            NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz),
              label: 'Quiz',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Students',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Usage',
            ),
          ],
        ),
      ),
    );
  }
}
