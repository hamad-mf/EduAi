import 'package:flutter/material.dart';

import '../onboarding/onboarding_page.dart';
import 'role_selection_page.dart';
import 'student_auth_page.dart';
import 'teacher_sign_in_page.dart';

enum _AuthStep { onboarding, roleSelection, studentAuth, teacherSignIn }

class AuthFlowPage extends StatefulWidget {
  const AuthFlowPage({super.key});

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  _AuthStep _step = _AuthStep.onboarding;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (_step) {
      case _AuthStep.onboarding:
        page = OnboardingPage(
          onComplete: () => setState(() => _step = _AuthStep.roleSelection),
        );
        break;
      case _AuthStep.roleSelection:
        page = RoleSelectionPage(
          onStudentSelected: () {
            setState(() => _step = _AuthStep.studentAuth);
          },
          onTeacherSelected: () {
            setState(() => _step = _AuthStep.teacherSignIn);
          },
        );
        break;
      case _AuthStep.studentAuth:
        page = StudentAuthPage(
          onBack: () => setState(() => _step = _AuthStep.roleSelection),
        );
        break;
      case _AuthStep.teacherSignIn:
        page = TeacherSignInPage(
          onBack: () => setState(() => _step = _AuthStep.roleSelection),
        );
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey<_AuthStep>(_step), child: page),
    );
  }
}
