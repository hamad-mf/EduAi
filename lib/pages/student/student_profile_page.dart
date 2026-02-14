import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../services/firestore_service.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key, required this.student});

  final AppUser student;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SchoolClass>>(
      stream: FirestoreService.instance.streamClasses(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<SchoolClass>> classSnapshot,
          ) {
            final List<SchoolClass> classes =
                classSnapshot.data ?? <SchoolClass>[];
            final String className =
                classes
                    .where((SchoolClass item) => item.id == student.classId)
                    .map((SchoolClass item) => item.name)
                    .fold<String?>(
                      null,
                      (String? prev, String next) => prev ?? next,
                    ) ??
                'Not assigned';

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
                            student.name.isEmpty
                                ? '?'
                                : student.name[0].toUpperCase(),
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
                        student.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.email,
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
                      _profileRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Role',
                        value: 'Student',
                      ),
                      const SizedBox(height: 8),
                      _profileRow(
                        icon: Icons.school_outlined,
                        label: 'Assigned Class',
                        value: className,
                      ),
                      const SizedBox(height: 8),
                      _profileRow(
                        icon: Icons.alternate_email_rounded,
                        label: 'Email',
                        value: student.email,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _profileRow({
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
