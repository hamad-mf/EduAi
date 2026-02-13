import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/quiz_attempt.dart';
import '../../models/school_class.dart';
import '../../services/firestore_service.dart';

class AdminStudentsPage extends StatelessWidget {
  const AdminStudentsPage({super.key, required this.admin});

  final AppUser admin;

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
        return StreamBuilder<List<AppUser>>(
          stream: FirestoreService.instance.streamStudents(),
          builder: (BuildContext context, AsyncSnapshot<List<AppUser>> studentSnapshot) {
            return StreamBuilder<List<QuizAttempt>>(
              stream: FirestoreService.instance.streamAllAttempts(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<QuizAttempt>> attemptSnapshot,
                  ) {
                    if (!classSnapshot.hasData ||
                        !studentSnapshot.hasData ||
                        !attemptSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final List<SchoolClass> classes = classSnapshot.data!;
                    final List<AppUser> students = studentSnapshot.data!;
                    final List<QuizAttempt> attempts = attemptSnapshot.data!;

                    final Map<String, String> classNameById = <String, String>{
                      for (final SchoolClass item in classes)
                        item.id: item.name,
                    };

                    if (students.isEmpty) {
                      return const Center(
                        child: Text('No students found yet.'),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        Text(
                          'Students (${students.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...students.map((AppUser student) {
                          final List<QuizAttempt> studentAttempts = attempts
                              .where(
                                (QuizAttempt item) =>
                                    item.studentId == student.id,
                              )
                              .toList();

                          final double avgScore = studentAttempts.isEmpty
                              ? 0
                              : studentAttempts
                                        .map(
                                          (QuizAttempt item) =>
                                              item.scorePercent,
                                        )
                                        .reduce((double a, double b) => a + b) /
                                    studentAttempts.length;

                          final DateTime? latest = studentAttempts.isEmpty
                              ? null
                              : studentAttempts.first.attemptedAt;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(student.email),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: student.classId,
                                    decoration: const InputDecoration(
                                      labelText: 'Assigned class',
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
                                          _showMessage(
                                            context,
                                            error.toString(),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Class: ${classNameById[student.classId] ?? 'Not assigned'}',
                                  ),
                                  Text('Attempts: ${studentAttempts.length}'),
                                  Text(
                                    'Average Score: ${avgScore.toStringAsFixed(1)}%',
                                  ),
                                  Text(
                                    latest == null
                                        ? 'Last Attempt: -'
                                        : 'Last Attempt: ${DateFormat.yMMMd().add_jm().format(latest)}',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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
