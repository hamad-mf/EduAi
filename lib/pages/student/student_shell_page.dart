import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'student_chat_page.dart';
import 'student_dashboard_page.dart';
import 'student_materials_page.dart';
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
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      StudentDashboardPage(student: widget.student),
      StudentMaterialsPage(student: widget.student),
      StudentQuizPage(student: widget.student),
      StudentWellbeingPage(student: widget.student),
      StudentChatPage(student: widget.student),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          IconButton(
            onPressed: AuthService.instance.signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Materials'),
          NavigationDestination(icon: Icon(Icons.quiz), label: 'Quiz'),
          NavigationDestination(
            icon: Icon(Icons.self_improvement),
            label: 'Mood',
          ),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }
}
