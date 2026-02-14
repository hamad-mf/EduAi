import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
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
  List<SchoolClass> _classes = <SchoolClass>[];
  List<SubjectModel> _subjects = <SubjectModel>[];
  String? _selectedClassId;
  String? _selectedSubjectId;
  String? _selectedChapter;

  int _questionCount = 5;
  List<QuizQuestion>? _quiz;
  Map<String, int> _answers = <String, int>{};
  bool _submitted = false;
  int _correctCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.student.classId;
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final List<SchoolClass> classes =
        await FirestoreService.instance.streamClasses().first;
    final List<SubjectModel> subjects =
        await FirestoreService.instance.streamSubjects().first;
    if (!mounted) {
      return;
    }
    setState(() {
      _classes = classes;
      _subjects = subjects;
    });
  }

  Future<void> _startQuiz() async {
    if (_selectedClassId == null || _selectedSubjectId == null) {
      return;
    }
    setState(() {
      _loading = true;
      _quiz = null;
      _answers = <String, int>{};
      _submitted = false;
      _correctCount = 0;
    });
    try {
      final List<QuizQuestion> selected =
          await FirestoreService.instance.getRandomQuestions(
            classId: _selectedClassId!,
            subjectId: _selectedSubjectId!,
            count: _questionCount,
            chapter: _selectedChapter,
          );
      setState(() => _quiz = selected);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null) {
      return;
    }
    int correct = 0;
    for (final QuizQuestion question in _quiz!) {
      if (_answers[question.id] == question.correctIndex) {
        correct++;
      }
    }
    setState(() {
      _correctCount = correct;
      _submitted = true;
    });

    try {
      final double scorePercent =
          _quiz!.isEmpty ? 0 : (correct / _quiz!.length) * 100;
      await FirestoreService.instance.saveQuizAttempt(
        QuizAttempt(
          id: '',
          studentId: widget.student.id,
          classId: _selectedClassId!,
          subjectId: _selectedSubjectId!,
          chapter: _selectedChapter ?? '',
          totalQuestions: _quiz!.length,
          correctAnswers: correct,
          scorePercent: scorePercent,
          questionIds:
              _quiz!.map((QuizQuestion question) => question.id).toList(),
          attemptedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // ── Setup Card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppTheme.sectionHeader(context, 'Quiz Setup', icon: Icons.quiz_outlined),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  prefixIcon: Icon(Icons.class_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _classes
                    .map(
                      (SchoolClass item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedClassId = value;
                    _selectedSubjectId = null;
                    _selectedChapter = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.book_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _subjects
                    .map(
                      (SubjectModel item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedSubjectId = value;
                    _selectedChapter = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Chapter (optional)',
                  prefixIcon: Icon(Icons.bookmark_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (String value) {
                  setState(() {
                    _selectedChapter = value.trim().isEmpty ? null : value.trim();
                  });
                },
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  const Icon(Icons.format_list_numbered, size: 18, color: AppTheme.secondaryText),
                  const SizedBox(width: 2),
                  const Text(
                    'Questions:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...<int>[5, 10, 15, 20].map((int count) {
                    final bool selected = _questionCount == count;
                    return ChoiceChip(
                      label: Text('$count'),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _questionCount = count),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _startQuiz,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Quiz'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Quiz Questions ──
        if (_quiz != null && _quiz!.isNotEmpty)
          ..._quiz!.asMap().entries.map((MapEntry<int, QuizQuestion> entry) {
            final int index = entry.key;
            final QuizQuestion question = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3EDFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            question.question,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...question.options.asMap().entries.map(
                      (MapEntry<int, String> optionEntry) {
                        final int optionIndex = optionEntry.key;
                        final String optionText = optionEntry.value;
                        final bool isSelected = _answers[question.id] == optionIndex;
                        final bool isCorrect = optionIndex == question.correctIndex;

                        Color tileColor = AppTheme.surfaceWhite;
                        Color borderColor = AppTheme.borderLight;
                        if (_submitted) {
                          if (isCorrect) {
                            tileColor = const Color(0xFFE8F5E9);
                            borderColor = const Color(0xFF66BB6A);
                          } else if (isSelected && !isCorrect) {
                            tileColor = const Color(0xFFFFEBEE);
                            borderColor = const Color(0xFFEF5350);
                          }
                        } else if (isSelected) {
                          tileColor = const Color(0xFFE3EDFF);
                          borderColor = AppTheme.primaryBlue;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _submitted
                                  ? null
                                  : () => setState(
                                      () => _answers[question.id] = optionIndex,
                                    ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primaryBlue
                                              : AppTheme.secondaryText,
                                          width: isSelected ? 2 : 1.5,
                                        ),
                                        color: isSelected
                                            ? AppTheme.primaryBlue
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),

        // ── Submit / Score ──
        if (_quiz != null && _quiz!.isNotEmpty && !_submitted)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitQuiz,
              child: const Text('Submit Quiz'),
            ),
          ),
        if (_submitted)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.accentLeftBorder(),
            child: Row(
              children: <Widget>[
                Icon(
                  _correctCount / (_quiz?.length ?? 1) >= 0.5
                      ? Icons.emoji_events_outlined
                      : Icons.sentiment_dissatisfied_outlined,
                  color: _correctCount / (_quiz?.length ?? 1) >= 0.5
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFD32F2F),
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Quiz Result',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Score: $_correctCount / ${_quiz!.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                AppTheme.scoreBadge(
                  (_correctCount / _quiz!.length) * 100,
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // ── History ──
        AppTheme.sectionHeader(context, 'Quiz History', icon: Icons.history),
        const SizedBox(height: 4),
        StreamBuilder<List<QuizAttempt>>(
          stream: FirestoreService.instance.streamStudentAttempts(
            widget.student.id,
          ),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<QuizAttempt>> snapshot,
          ) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<QuizAttempt> attempts = snapshot.data!;
            if (attempts.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.tintedContainer(),
                child: const Text(
                  'No quiz attempts yet.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
              );
            }

            return Column(
              children: attempts.map((QuizAttempt attempt) {
                final String subjectName = _subjects
                    .where((SubjectModel item) => item.id == attempt.subjectId)
                    .map((SubjectModel item) => item.name)
                    .fold<String?>(null, (String? previous, String element) => previous ?? element) ?? 'Unknown';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppTheme.cardDecoration(radius: 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                subjectName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${attempt.correctAnswers}/${attempt.totalQuestions} · ${attempt.attemptedAt == null ? '' : DateFormat.yMMMd().add_jm().format(attempt.attemptedAt!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppTheme.scoreBadge(attempt.scorePercent),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
