import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/quiz_attempt.dart';
import '../../models/school_class.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_service.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key, required this.student});

  final AppUser student;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SchoolClass>>(
      stream: FirestoreService.instance.streamClasses(),
      builder: (BuildContext context, AsyncSnapshot<List<SchoolClass>> classSnapshot) {
        if (!classSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<SchoolClass> classes = classSnapshot.data!;

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
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Welcome, ${student.name}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(student.email),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  initialValue: student.classId,
                                  decoration: const InputDecoration(
                                    labelText: 'Your Class',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: classes
                                      .map(
                                        (SchoolClass schoolClass) =>
                                            DropdownMenuItem<String>(
                                              value: schoolClass.id,
                                              child: Text(schoolClass.name),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (String? value) async {
                                    if (value == null) {
                                      return;
                                    }
                                    try {
                                      await FirestoreService.instance
                                          .assignClassToStudent(
                                            studentId: student.id,
                                            classId: value,
                                          );
                                    } catch (error) {
                                      if (context.mounted) {
                                        _showMessage(context, error.toString());
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Progress Summary',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text('Total Attempts: ${attempts.length}'),
                                Text(
                                  'Average Score: ${average.toStringAsFixed(1)}%',
                                ),
                                Text(
                                  latest == null
                                      ? 'Latest Score: -'
                                      : 'Latest Score: ${latest.scorePercent.toStringAsFixed(1)}%',
                                ),
                                Text(
                                  latest?.attemptedAt == null
                                      ? 'Last Attempt Date: -'
                                      : 'Last Attempt Date: '
                                            '${DateFormat.yMMMd().add_jm().format(latest!.attemptedAt!)}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Subject-wise Performance',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                if (attemptsBySubject.isEmpty)
                                  const Text('No quiz attempts yet.')
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
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        '$subjectName: ${subjectAverage.toStringAsFixed(1)}% '
                                        '(${subjectAttempts.length} attempts)',
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (student.classId == null)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Select your class first to access study materials and quizzes.',
                              ),
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
}
