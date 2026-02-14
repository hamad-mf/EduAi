import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/quiz_attempt.dart';
import '../../models/school_class.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_service.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key, required this.student});

  final AppUser student;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SchoolClass>>(
      stream: FirestoreService.instance.streamClasses(),
      builder: (BuildContext context, AsyncSnapshot<List<SchoolClass>> classSnapshot) {
        if (!classSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<SchoolClass> classes = classSnapshot.data!;
        final String assignedClassName =
            classes
                .where((SchoolClass item) => item.id == student.classId)
                .map((SchoolClass item) => item.name)
                .cast<String?>()
                .firstOrNull ??
            'Not assigned yet';

        return StreamBuilder<List<QuizAttempt>>(
          stream: FirestoreService.instance.streamStudentAttempts(student.id),
          builder: (BuildContext context, AsyncSnapshot<List<QuizAttempt>> attemptSnapshot) {
            if (!attemptSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<QuizAttempt> attempts = attemptSnapshot.data!;

            return StreamBuilder<List<SubjectModel>>(
              stream: FirestoreService.instance.streamSubjects(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<SubjectModel>> subjectSnapshot,
                  ) {
                    if (!subjectSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final List<SubjectModel> subjects = subjectSnapshot.data!;
                    final Map<String, String> subjectNameById =
                        <String, String>{
                          for (final SubjectModel item in subjects)
                            item.id: item.name,
                        };

                    final double average = attempts.isEmpty
                        ? 0
                        : attempts
                                  .map((QuizAttempt item) => item.scorePercent)
                                  .reduce((double a, double b) => a + b) /
                              attempts.length;
                    final QuizAttempt? latest = attempts.isEmpty
                        ? null
                        : attempts.first;

                    final Map<String, List<QuizAttempt>> attemptsBySubject =
                        <String, List<QuizAttempt>>{};
                    for (final QuizAttempt attempt in attempts) {
                      attemptsBySubject.putIfAbsent(
                        attempt.subjectId,
                        () => <QuizAttempt>[],
                      );
                      attemptsBySubject[attempt.subjectId]!.add(attempt);
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        // ── Welcome Card ──
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(color: AppTheme.shadowBlue, blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  gradient: AppTheme.heroGradient,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                'Welcome, ${student.name}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                student.email,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: AppTheme.surfaceWhite,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(18),
                                    bottomRight: Radius.circular(18),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: AppTheme.tintedContainer(),
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.school_outlined,
                                        color: AppTheme.primaryBlue,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            const Text(
                                              'Assigned Class',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: AppTheme.secondaryText,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              assignedClassName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: AppTheme.darkText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Progress Summary ──
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.accentLeftBorder(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.trending_up_rounded, color: AppTheme.primaryBlue, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Progress Summary',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _statRow(Icons.format_list_numbered, 'Total Attempts', '${attempts.length}'),
                              const SizedBox(height: 8),
                              _statRow(Icons.percent, 'Average Score', '${average.toStringAsFixed(1)}%'),
                              const SizedBox(height: 8),
                              _statRow(
                                Icons.star_outline,
                                'Latest Score',
                                latest == null ? '-' : '${latest.scorePercent.toStringAsFixed(1)}%',
                              ),
                              const SizedBox(height: 8),
                              _statRow(
                                Icons.calendar_today_outlined,
                                'Last Attempt',
                                latest?.attemptedAt == null
                                    ? '-'
                                    : DateFormat.yMMMd().add_jm().format(latest!.attemptedAt!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Subject-wise Performance ──
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryBlue, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Subject-wise Performance',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (attemptsBySubject.isEmpty)
                                const Text(
                                  'No quiz attempts yet.',
                                  style: TextStyle(color: AppTheme.secondaryText),
                                )
                              else
                                ...attemptsBySubject.entries.map((
                                  MapEntry<String, List<QuizAttempt>> entry,
                                ) {
                                  final String subjectName =
                                      subjectNameById[entry.key] ?? 'Unknown';
                                  final List<QuizAttempt> subjectAttempts =
                                      entry.value;
                                  final double subjectAverage =
                                      subjectAttempts
                                          .map(
                                            (QuizAttempt item) =>
                                                item.scorePercent,
                                          )
                                          .reduce(
                                            (double a, double b) => a + b,
                                          ) /
                                      subjectAttempts.length;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '$subjectName (${subjectAttempts.length} attempts)',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        AppTheme.scoreBadge(subjectAverage),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (student.classId == null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.tintedContainer(),
                            child: const Row(
                              children: <Widget>[
                                Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Your class is not assigned yet. Please contact your teacher.',
                                    style: TextStyle(color: AppTheme.secondaryText),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                    );
                  },
            );
          },
        );
      },
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: AppTheme.secondaryText),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.secondaryText,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.darkText,
            ),
          ),
        ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
