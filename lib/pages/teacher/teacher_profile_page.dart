import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key, required this.teacher});

  final AppUser teacher;

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  Map<String, int>? _counts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _loading = true);
    try {
      final Map<String, int> usage = await FirestoreService.instance
          .getUsageCounts();
      if (!mounted) {
        return;
      }
      setState(() => _counts = usage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _counts = <String, int>{});
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, int> stats = _counts ?? <String, int>{};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: AppTheme.cardDecoration(radius: 18),
          child: Column(
            children: <Widget>[
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    widget.teacher.name.isEmpty
                        ? '?'
                        : widget.teacher.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.teacher.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.teacher.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppTheme.sectionHeader(
                context,
                'Account Details',
                icon: Icons.badge_outlined,
              ),
              _row(
                icon: Icons.person_outline_rounded,
                label: 'Role',
                value: 'Teacher',
              ),
              const SizedBox(height: 8),
              _row(
                icon: Icons.alternate_email_rounded,
                label: 'Email',
                value: widget.teacher.email,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AppTheme.sectionHeader(
                    context,
                    'Platform Snapshot',
                    icon: Icons.analytics_outlined,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loading ? null : _loadCounts,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 20),
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _row(
                icon: Icons.people_outline_rounded,
                label: 'Students',
                value: '${stats['students'] ?? 0}',
              ),
              const SizedBox(height: 8),
              _row(
                icon: Icons.quiz_outlined,
                label: 'Quiz Attempts',
                value: '${stats['quizAttempts'] ?? 0}',
              ),
              const SizedBox(height: 8),
              _row(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat Messages',
                value: '${stats['chats'] ?? 0}',
              ),
              const SizedBox(height: 8),
              _row(
                icon: Icons.menu_book_outlined,
                label: 'Materials',
                value: '${stats['materials'] ?? 0}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: AppTheme.secondaryText),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryText,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
        ),
      ],
    );
  }
}
