import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/quiz_attempt.dart';
import '../../models/quiz_question.dart';
import '../../models/school_class.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_service.dart';

class StudentQuizPage extends StatefulWidget {
  const StudentQuizPage({super.key, required this.student});

  final AppUser student;

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  String? _selectedSubjectId;
  String _selectedChapter = 'All Chapters';
  int _questionCount = 5;

  List<QuizQuestion> _activeQuestions = <QuizQuestion>[];
  final Map<String, int> _selectedAnswers = <String, int>{};
  bool _loadingQuiz = false;
  bool _submitting = false;
  double? _lastScore;
  int? _lastCorrect;
  int? _lastTotalQuestions;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startQuiz({
    required String classId,
    required String subjectId,
  }) async {
    setState(() {
      _loadingQuiz = true;
      _lastScore = null;
      _lastCorrect = null;
      _lastTotalQuestions = null;
    });
    try {
      final String? chapter = _selectedChapter == 'All Chapters'
          ? null
          : _selectedChapter;
      final List<QuizQuestion> questions = await FirestoreService.instance
          .getRandomQuestions(
            classId: classId,
            subjectId: subjectId,
            count: _questionCount,
            chapter: chapter,
          );

      if (questions.isEmpty) {
        _showMessage('No quiz questions available for this selection.');
        return;
      }

      setState(() {
        _activeQuestions = questions;
        _selectedAnswers.clear();
      });
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingQuiz = false);
      }
    }
  }

  Future<void> _submitQuiz({
    required String classId,
    required String subjectId,
  }) async {
    if (_activeQuestions.isEmpty) {
      return;
    }
    setState(() => _submitting = true);

    try {
      int correct = 0;
      for (final QuizQuestion question in _activeQuestions) {
        final int? answer = _selectedAnswers[question.id];
        if (answer != null && answer == question.correctIndex) {
          correct += 1;
        }
      }

      final double percent = (correct / _activeQuestions.length) * 100;
      final QuizAttempt attempt = QuizAttempt(
        id: '',
        studentId: widget.student.id,
        classId: classId,
        subjectId: subjectId,
        chapter: _selectedChapter == 'All Chapters'
            ? 'Mixed'
            : _selectedChapter,
        totalQuestions: _activeQuestions.length,
        correctAnswers: correct,
        scorePercent: percent,
        questionIds: _activeQuestions.map((QuizQuestion q) => q.id).toList(),
        attemptedAt: DateTime.now(),
      );

      await FirestoreService.instance.saveQuizAttempt(attempt);

      setState(() {
        _lastCorrect = correct;
        _lastScore = percent;
        _lastTotalQuestions = _activeQuestions.length;
        _activeQuestions = <QuizQuestion>[];
        _selectedAnswers.clear();
      });
      _showMessage('Quiz submitted successfully.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.student.classId == null) {
      return const Center(child: Text('Select class from Dashboard first.'));
    }

    return StreamBuilder<List<SchoolClass>>(
      stream: FirestoreService.instance.streamClasses(),
      builder: (BuildContext context, AsyncSnapshot<List<SchoolClass>> classSnapshot) {
        return StreamBuilder<List<SubjectModel>>(
          stream: FirestoreService.instance.streamSubjects(),
          builder: (BuildContext context, AsyncSnapshot<List<SubjectModel>> subjectSnapshot) {
            if (!classSnapshot.hasData || !subjectSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<SchoolClass> classes = classSnapshot.data!;
            final List<SubjectModel> allSubjects = subjectSnapshot.data!;

            final SchoolClass? schoolClass = classes
                .where((SchoolClass c) => c.id == widget.student.classId)
                .cast<SchoolClass?>()
                .firstOrNull;

            if (schoolClass == null) {
              return const Center(
                child: Text(
                  'Selected class not found. Please re-select class.',
                ),
              );
            }

            final Map<String, SubjectModel> subjectById =
                <String, SubjectModel>{
                  for (final SubjectModel s in allSubjects) s.id: s,
                };
            final List<SubjectModel> classSubjects = schoolClass.subjectIds
                .map((String id) => subjectById[id])
                .whereType<SubjectModel>()
                .toList();

            if (classSubjects.isEmpty) {
              return const Center(
                child: Text('No subjects assigned to your class yet.'),
              );
            }

            if (_selectedSubjectId == null ||
                classSubjects.every(
                  (SubjectModel s) => s.id != _selectedSubjectId,
                )) {
              _selectedSubjectId = classSubjects.first.id;
            }

            return StreamBuilder<List<QuizQuestion>>(
              stream: FirestoreService.instance.streamQuizQuestions(
                classId: schoolClass.id,
                subjectId: _selectedSubjectId!,
              ),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<QuizQuestion>> questionSnapshot,
                  ) {
                    if (!questionSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final List<QuizQuestion> questionBank =
                        questionSnapshot.data!;
                    final List<String> chapters = <String>[
                      'All Chapters',
                      ...{for (final QuizQuestion q in questionBank) q.chapter},
                    ];
                    if (!chapters.contains(_selectedChapter)) {
                      _selectedChapter = 'All Chapters';
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
                                Text('Class: ${schoolClass.name}'),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedSubjectId,
                                  decoration: const InputDecoration(
                                    labelText: 'Subject',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: classSubjects
                                      .map(
                                        (SubjectModel subject) =>
                                            DropdownMenuItem<String>(
                                              value: subject.id,
                                              child: Text(subject.name),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (String? value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() {
                                      _selectedSubjectId = value;
                                      _selectedChapter = 'All Chapters';
                                      _activeQuestions = <QuizQuestion>[];
                                      _selectedAnswers.clear();
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedChapter,
                                  decoration: const InputDecoration(
                                    labelText: 'Chapter',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: chapters
                                      .map(
                                        (String chapter) =>
                                            DropdownMenuItem<String>(
                                              value: chapter,
                                              child: Text(chapter),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (String? value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() => _selectedChapter = value);
                                  },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  initialValue: _questionCount,
                                  decoration: const InputDecoration(
                                    labelText: 'Number of Questions',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const <DropdownMenuItem<int>>[
                                    DropdownMenuItem<int>(
                                      value: 5,
                                      child: Text('5'),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 10,
                                      child: Text('10'),
                                    ),
                                    DropdownMenuItem<int>(
                                      value: 15,
                                      child: Text('15'),
                                    ),
                                  ],
                                  onChanged: (int? value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() => _questionCount = value);
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Question bank size: ${questionBank.length}',
                                ),
                                const SizedBox(height: 8),
                                FilledButton(
                                  onPressed: (_loadingQuiz || _submitting)
                                      ? null
                                      : () => _startQuiz(
                                          classId: schoolClass.id,
                                          subjectId: _selectedSubjectId!,
                                        ),
                                  child: Text(
                                    _loadingQuiz
                                        ? 'Loading...'
                                        : 'Start Random Quiz',
                                  ),
                                ),
                                if (_lastScore != null) ...<Widget>[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Last Score: ${_lastScore!.toStringAsFixed(1)}% '
                                    '($_lastCorrect/$_lastTotalQuestions)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_activeQuestions.isNotEmpty) ...<Widget>[
                          Card(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Current Quiz: ${_activeQuestions.length} questions',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List<Widget>.generate(_activeQuestions.length, (
                            int index,
                          ) {
                            final QuizQuestion question =
                                _activeQuestions[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Q${index + 1}. ${question.question}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List<Widget>.generate(
                                      question.options.length,
                                      (int optionIndex) {
                                        final bool selected =
                                            _selectedAnswers[question.id] ==
                                            optionIndex;
                                        return ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            selected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_off,
                                          ),
                                          title: Text(
                                            question.options[optionIndex],
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _selectedAnswers[question.id] =
                                                  optionIndex;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          FilledButton(
                            onPressed: _submitting
                                ? null
                                : () => _submitQuiz(
                                    classId: schoolClass.id,
                                    subjectId: _selectedSubjectId!,
                                  ),
                            child: Text(
                              _submitting ? 'Submitting...' : 'Submit Quiz',
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          'Score History',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<List<QuizAttempt>>(
                          stream: FirestoreService.instance
                              .streamStudentAttempts(widget.student.id),
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<List<QuizAttempt>> snapshot,
                              ) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final List<QuizAttempt> attempts =
                                    snapshot.data!;
                                if (attempts.isEmpty) {
                                  return const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text('No attempts yet.'),
                                    ),
                                  );
                                }
                                return Column(
                                  children: attempts.take(15).map((
                                    QuizAttempt attempt,
                                  ) {
                                    final String subjectName =
                                        subjectById[attempt.subjectId]?.name ??
                                        'Unknown Subject';
                                    return Card(
                                      child: ListTile(
                                        title: Text(
                                          '$subjectName - ${attempt.scorePercent.toStringAsFixed(1)}%',
                                        ),
                                        subtitle: Text(
                                          '${attempt.correctAnswers}/${attempt.totalQuestions} correct'
                                          ' | ${attempt.chapter}',
                                        ),
                                        trailing: Text(
                                          attempt.attemptedAt == null
                                              ? '-'
                                              : DateFormat.yMMMd().format(
                                                  attempt.attemptedAt!,
                                                ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
