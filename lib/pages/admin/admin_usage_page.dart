import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import 'admin_api_settings_page.dart';

class AdminUsagePage extends StatefulWidget {
  const AdminUsagePage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminUsagePage> createState() => _AdminUsagePageState();
}

class _AdminUsagePageState extends State<AdminUsagePage> {
  int _studentCount = 0;
  int _quizAttemptCount = 0;
  int _chatCount = 0;
  int _materialCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    setState(() => _loading = true);
    try {
      final Map<String, int> counts =
          await FirestoreService.instance.getUsageCounts();
      if (!mounted) {
        return;
      }
      setState(() {
        _studentCount = counts['students'] ?? 0;
        _quizAttemptCount = counts['quizAttempts'] ?? 0;
        _chatCount = counts['chats'] ?? 0;
        _materialCount = counts['materials'] ?? 0;
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // ── Header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x301565C0),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'System Usage',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Overview of platform activity',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _fetchCounts,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Stat Cards Grid ──
        Row(
          children: <Widget>[
            Expanded(
              child: AppTheme.statCard(
                label: 'Students',
                value: '$_studentCount',
                icon: Icons.people_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTheme.statCard(
                label: 'Quiz Attempts',
                value: '$_quizAttemptCount',
                icon: Icons.quiz_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: AppTheme.statCard(
                label: 'Chat Messages',
                value: '$_chatCount',
                icon: Icons.chat_rounded,
                iconBg: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFE65100),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTheme.statCard(
                label: 'Materials',
                value: '$_materialCount',
                icon: Icons.menu_book_rounded,
                iconBg: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF7B1FA2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── API Settings Link ──
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdminApiSettingsPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(radius: 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EDFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.key_rounded,
                      color: AppTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'API Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Manage Gemini API key',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppTheme.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
