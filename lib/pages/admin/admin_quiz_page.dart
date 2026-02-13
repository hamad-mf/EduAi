import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/quiz_question.dart';
import '../../models/school_class.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_service.dart';

class AdminQuizPage extends StatefulWidget {
  const AdminQuizPage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminQuizPage> createState() => _AdminQuizPageState();
}

class _AdminQuizPageState extends State<AdminQuizPage> {
  String? _selectedClassId;
  String? _selectedSubjectId;
  final TextEditingController _chapterController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      <TextEditingController>[
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ];
  int _correctIndex = 0;
  bool _saving = false;

  @override
  void dispose() {
    _chapterController.dispose();
    _questionController.dispose();
    for (final TextEditingController controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveQuestion() async {
    if (_selectedClassId == null || _selectedSubjectId == null) {
      _showMessage('Select class and subject first.');
      return;
    }
    if (_chapterController.text.trim().isEmpty ||
        _questionController.text.trim().isEmpty) {
      _showMessage('Chapter and question are required.');
      return;
    }

    final List<String> options = _optionControllers
        .map((TextEditingController c) => c.text.trim())
        .toList();
    if (options.any((String option) => option.isEmpty)) {
      _showMessage('All four options are required.');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.saveQuizQuestion(
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
        chapter: _chapterController.text.trim(),
        question: _questionController.text.trim(),
        options: options,
        correctIndex: _correctIndex,
        createdBy: widget.admin.id,
      );
      _questionController.clear();
      _chapterController.clear();
      for (final TextEditingController c in _optionControllers) {
        c.clear();
      }
      setState(() => _correctIndex = 0);
      _showMessage('Quiz question saved.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SchoolClass>>(
      stream: FirestoreService.instance.streamClasses(),
      builder: (BuildContext context, AsyncSnapshot<List<SchoolClass>> classSnapshot) {
        return StreamBuilder<List<SubjectModel>>(
          stream: FirestoreService.instance.streamSubjects(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<SubjectModel>> subjectSnapshot,
              ) {
                if (!classSnapshot.hasData || !subjectSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<SchoolClass> classes = classSnapshot.data!;
                final List<SubjectModel> allSubjects = subjectSnapshot.data!;
                final Map<String, SubjectModel> subjectById =
                    <String, SubjectModel>{
                      for (final SubjectModel item in allSubjects)
                        item.id: item,
                    };

                if (classes.isNotEmpty &&
                    (_selectedClassId == null ||
                        classes.every(
                          (SchoolClass c) => c.id != _selectedClassId,
                        ))) {
                  _selectedClassId = classes.first.id;
                }

                final SchoolClass? selectedClass = classes
                    .where((SchoolClass item) => item.id == _selectedClassId)
                    .cast<SchoolClass?>()
                    .firstOrNull;

                final List<SubjectModel> classSubjects = selectedClass == null
                    ? <SubjectModel>[]
                    : selectedClass.subjectIds
                          .map((String id) => subjectById[id])
                          .whereType<SubjectModel>()
                          .toList();

                if (classSubjects.isNotEmpty &&
                    (_selectedSubjectId == null ||
                        classSubjects.every(
                          (SubjectModel item) => item.id != _selectedSubjectId,
                        ))) {
                  _selectedSubjectId = classSubjects.first.id;
                }
                if (classSubjects.isEmpty) {
                  _selectedSubjectId = null;
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
                            const Text(
                              'Add Quiz Question',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedClassId,
                              decoration: const InputDecoration(
                                labelText: 'Class',
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
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedClassId = value;
                                  _selectedSubjectId = null;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
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
                                setState(() => _selectedSubjectId = value);
                              },
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _chapterController,
                              decoration: const InputDecoration(
                                labelText: 'Chapter',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _questionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Question',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...List<Widget>.generate(
                              _optionControllers.length,
                              (int index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TextField(
                                  controller: _optionControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Option ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                            DropdownButtonFormField<int>(
                              initialValue: _correctIndex,
                              decoration: const InputDecoration(
                                labelText: 'Correct Option',
                                border: OutlineInputBorder(),
                              ),
                              items: const <DropdownMenuItem<int>>[
                                DropdownMenuItem<int>(
                                  value: 0,
                                  child: Text('Option 1'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 1,
                                  child: Text('Option 2'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 2,
                                  child: Text('Option 3'),
                                ),
                                DropdownMenuItem<int>(
                                  value: 3,
                                  child: Text('Option 4'),
                                ),
                              ],
                              onChanged: (int? value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _correctIndex = value);
                              },
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed: _saving ? null : _saveQuestion,
                              child: Text(
                                _saving ? 'Saving...' : 'Save Question',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Question Bank',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_selectedClassId == null || _selectedSubjectId == null)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Select class and subject to view questions.',
                          ),
                        ),
                      )
                    else
                      StreamBuilder<List<QuizQuestion>>(
                        stream: FirestoreService.instance.streamQuizQuestions(
                          classId: _selectedClassId!,
                          subjectId: _selectedSubjectId!,
                        ),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<List<QuizQuestion>> snapshot,
                            ) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final List<QuizQuestion> questions =
                                  snapshot.data!;
                              if (questions.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('No quiz questions added yet.'),
                                  ),
                                );
                              }
                              return Column(
                                children: questions.map((
                                  QuizQuestion question,
                                ) {
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Text(
                                                  'Chapter: ${question.chapter}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () async {
                                                  await FirestoreService
                                                      .instance
                                                      .deleteQuizQuestion(
                                                        question.id,
                                                      );
                                                },
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(question.question),
                                          const SizedBox(height: 8),
                                          ...List<Widget>.generate(
                                            question.options.length,
                                            (int index) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 1,
                                                  ),
                                              child: Text(
                                                '${index + 1}. ${question.options[index]}'
                                                '${question.correctIndex == index ? ' (Correct)' : ''}',
                                              ),
                                            ),
                                          ),
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
              },
        );
      },
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
