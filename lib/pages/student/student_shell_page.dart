import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'student_chat_page.dart';
import 'student_dashboard_page.dart';
import 'student_materials_page.dart';
import 'student_profile_page.dart';
import 'student_quiz_page.dart';
import 'student_wellbeing_page.dart';

class StudentShellPage extends StatefulWidget {
  const StudentShellPage({super.key, required this.student});

  final AppUser student;

  @override
  State<StudentShellPage> createState() => _StudentShellPageState();
}

class _StudentShellPageState extends State<StudentShellPage> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Dashboard',
    'Materials',
    'Quiz',
    'Wellbeing',
    'AI Chat',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      StudentDashboardPage(student: widget.student),
      StudentMaterialsPage(student: widget.student),
      StudentQuizPage(student: widget.student),
      StudentWellbeingPage(student: widget.student),
      StudentChatPage(student: widget.student),
      StudentProfilePage(student: widget.student),
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
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
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
              icon: Icon(Icons.self_improvement_outlined),
              selectedIcon: Icon(Icons.self_improvement_rounded),
              label: 'Wellbeing',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
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
