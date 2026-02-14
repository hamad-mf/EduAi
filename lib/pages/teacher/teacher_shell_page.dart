import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'teacher_classes_page.dart';
import 'teacher_materials_page.dart';
import 'teacher_profile_page.dart';
import 'teacher_quiz_page.dart';
import 'teacher_students_page.dart';
import 'teacher_usage_page.dart';

class TeacherShellPage extends StatefulWidget {
  const TeacherShellPage({super.key, required this.teacher});

  final AppUser teacher;

  @override
  State<TeacherShellPage> createState() => _TeacherShellPageState();
}

class _TeacherShellPageState extends State<TeacherShellPage> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Classes & Subjects',
    'Study Materials',
    'Quiz Bank',
    'Students',
    'Usage',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      TeacherClassesPage(teacher: widget.teacher),
      TeacherMaterialsPage(teacher: widget.teacher),
      TeacherQuizPage(teacher: widget.teacher),
      TeacherStudentsPage(teacher: widget.teacher),
      TeacherUsagePage(teacher: widget.teacher),
      TeacherProfilePage(teacher: widget.teacher),
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
          border: Border(top: BorderSide(color: Color(0xFFE8EDF5), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int value) => setState(() => _index = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.class_outlined),
              selectedIcon: Icon(Icons.class_rounded),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Materials',
            ),
            NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz_rounded),
              label: 'Quiz',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Students',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Usage',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
