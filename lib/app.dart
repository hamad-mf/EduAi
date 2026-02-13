import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'pages/admin/admin_shell_page.dart';
import 'pages/auth/auth_page.dart';
import 'pages/shared/loading_page.dart';
import 'pages/student/student_shell_page.dart';
import 'services/auth_service.dart';

class EduAiApp extends StatelessWidget {
  const EduAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          secondary: const Color(0xFFF97316),
        ),
        useMaterial3: true,
      ),
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage(label: 'Checking session...');
        }

        final User? firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const AuthPage();
        }

        return FutureBuilder<void>(
          future: AuthService.instance.ensureProfile(firebaseUser),
          builder: (BuildContext context, AsyncSnapshot<void> ensureSnapshot) {
            if (ensureSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingPage(label: 'Preparing profile...');
            }

            return StreamBuilder<AppUser?>(
              stream: AuthService.instance.profileStream(firebaseUser.uid),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<AppUser?> profileSnapshot,
                  ) {
                    if (profileSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const LoadingPage(label: 'Loading dashboard...');
                    }

                    final AppUser? profile = profileSnapshot.data;
                    if (profile == null) {
                      return const LoadingPage(label: 'Profile not found...');
                    }

                    if (profile.role == UserRole.admin) {
                      return AdminShellPage(admin: profile);
                    }
                    return StudentShellPage(student: profile);
                  },
            );
          },
        );
      },
    );
  }
}
