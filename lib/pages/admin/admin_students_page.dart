import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/quiz_attempt.dart';
import '../../models/school_class.dart';
import '../../services/firestore_service.dart';

class AdminStudentsPage extends StatelessWidget {
  const AdminStudentsPage({super.key, required this.admin});

  final AppUser admin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: FirestoreService.instance.streamStudents(),
      builder: (BuildContext context, AsyncSnapshot<List<AppUser>> studentSnap) {
        return StreamBuilder<List<SchoolClass>>(
          stream: FirestoreService.instance.streamClasses(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<SchoolClass>> classSnap,
              ) {
                if (!studentSnap.hasData || !classSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<AppUser> students = studentSnap.data!;
                final List<SchoolClass> classes = classSnap.data!;
                final List<SchoolClass> uniqueClasses = <SchoolClass>[
                  ...<String, SchoolClass>{
                    for (final SchoolClass item in classes) item.id: item,
                  }.values,
                ];

                if (students.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.tintedContainer(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.people_outline,
                              color: AppTheme.primaryBlue,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'No students have signed up yet.',
                              style: TextStyle(color: AppTheme.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (BuildContext context, int index) {
                    final AppUser student = students[index];
                    final String? selectedClassId =
                        uniqueClasses.any(
                          (SchoolClass item) => item.id == student.classId,
                        )
                        ? student.classId
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.heroGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      student.name.isNotEmpty
                                          ? student.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        student.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        student.email,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedClassId,
                              decoration: const InputDecoration(
                                labelText: 'Assigned Class',
                                prefixIcon: Icon(Icons.school_outlined),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ...uniqueClasses.map(
                                  (SchoolClass item) =>
                                      DropdownMenuItem<String>(
                                        value: item.id,
                                        child: Text(item.name),
                                      ),
                                ),
                              ],
                              onChanged: (String? value) {
                                if (value != null) {
                                  FirestoreService.instance
                                      .assignClassToStudent(
                                        studentId: student.id,
                                        classId: value,
                                      );
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            StreamBuilder<List<QuizAttempt>>(
                              stream: FirestoreService.instance
                                  .streamStudentAttempts(student.id),
                              builder:
                                  (
                                    BuildContext context,
                                    AsyncSnapshot<List<QuizAttempt>>
                                    attemptSnap,
                                  ) {
                                    if (!attemptSnap.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    final List<QuizAttempt> attempts =
                                        attemptSnap.data!;
                                    if (attempts.isEmpty) {
                                      return const Text(
                                        'No quiz attempts',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.secondaryText,
                                        ),
                                      );
                                    }
                                    final double average =
                                        attempts
                                            .map(
                                              (QuizAttempt item) =>
                                                  item.scorePercent,
                                            )
                                            .reduce(
                                              (double a, double b) => a + b,
                                            ) /
                                        attempts.length;
                                    final QuizAttempt latest = attempts.first;
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: AppTheme.tintedContainer(
                                        radius: 10,
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          _miniStat(
                                            Icons.format_list_numbered,
                                            '${attempts.length}',
                                            'Attempts',
                                          ),
                                          const SizedBox(width: 14),
                                          _miniStat(
                                            Icons.percent,
                                            '${average.toStringAsFixed(1)}%',
                                            'Average',
                                          ),
                                          const SizedBox(width: 14),
                                          _miniStat(
                                            Icons.calendar_today_outlined,
                                            latest.attemptedAt == null
                                                ? '-'
                                                : DateFormat.MMMd().format(
                                                    latest.attemptedAt!,
                                                  ),
                                            'Last',
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
        );
      },
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppTheme.primaryBlue),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppTheme.darkText,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
