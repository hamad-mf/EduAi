import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
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
  final TextEditingController _chapterController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List<TextEditingController>.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctIndex = 0;

  String? _selectedClassId;
  String? _selectedSubjectId;
  bool _saving = false;
  String? _editingId;

  @override
  void dispose() {
    _chapterController.dispose();
    _questionController.dispose();
    for (final TextEditingController controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clearForm() {
    _chapterController.clear();
    _questionController.clear();
    for (final TextEditingController controller in _optionControllers) {
      controller.clear();
    }
    setState(() {
      _correctIndex = 0;
      _editingId = null;
    });
  }

  Future<void> _saveQuestion() async {
    if (_selectedClassId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select class & subject')));
      return;
    }
    final String question = _questionController.text.trim();
    if (question.isEmpty) {
      return;
    }
    final List<String> options = _optionControllers
        .map((TextEditingController controller) => controller.text.trim())
        .toList();
    if (options.any((String option) => option.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all options')));
      return;
    }

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.saveQuizQuestion(
        id: _editingId,
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
        chapter: _chapterController.text.trim(),
        question: question,
        options: options,
        correctIndex: _correctIndex,
        createdBy: widget.admin.id,
      );
      _clearForm();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _loadForEdit(QuizQuestion question) {
    _chapterController.text = question.chapter;
    _questionController.text = question.question;
    for (int i = 0; i < question.options.length && i < 4; i++) {
      _optionControllers[i].text = question.options[i];
    }
    setState(() {
      _correctIndex = question.correctIndex;
      _editingId = question.id;
    });
  }

  Future<void> _deleteQuestion(String questionId) async {
    try {
      await FirestoreService.instance.deleteQuizQuestion(questionId);
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
    return StreamBuilder<List<SchoolClass>>(
      stream: FirestoreService.instance.streamClasses(),
      builder: (BuildContext context, AsyncSnapshot<List<SchoolClass>> classSnap) {
        return StreamBuilder<List<SubjectModel>>(
          stream: FirestoreService.instance.streamSubjects(),
          builder: (BuildContext context, AsyncSnapshot<List<SubjectModel>> subjectSnap) {
            if (!classSnap.hasData || !subjectSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<SchoolClass> classes = classSnap.data!;
            final List<SubjectModel> subjects = subjectSnap.data!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // ── Form Card ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppTheme.sectionHeader(
                        context,
                        _editingId != null ? 'Edit Question' : 'Add Question',
                        icon: Icons.quiz_outlined,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          prefixIcon: Icon(Icons.class_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: classes
                            .map(
                              (SchoolClass item) => DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) =>
                            setState(() => _selectedClassId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          prefixIcon: Icon(Icons.book_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: subjects
                            .map(
                              (SubjectModel item) => DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) =>
                            setState(() => _selectedSubjectId = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _chapterController,
                        decoration: const InputDecoration(
                          labelText: 'Chapter',
                          prefixIcon: Icon(Icons.bookmark_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _questionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                          prefixIcon: Icon(Icons.help_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List<Widget>.generate(4, (int i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: <Widget>[
                              Radio<int>(
                                value: i,
                                groupValue: _correctIndex,
                                onChanged: (int? value) {
                                  if (value != null) {
                                    setState(() => _correctIndex = value);
                                  }
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _optionControllers[i],
                                  decoration: InputDecoration(
                                    labelText: 'Option ${i + 1}',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _correctIndex == i
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF2E7D32),
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          if (_editingId != null)
                            TextButton(
                              onPressed: _clearForm,
                              child: const Text('Cancel'),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _saving ? null : _saveQuestion,
                            child: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _editingId != null ? 'Update' : 'Save Question',
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Question Bank ──
                if (_selectedClassId != null && _selectedSubjectId != null)
                  StreamBuilder<List<QuizQuestion>>(
                    stream: FirestoreService.instance.streamQuizQuestions(
                      classId: _selectedClassId!,
                      subjectId: _selectedSubjectId!,
                    ),
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<QuizQuestion>> snapshot,
                    ) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final List<QuizQuestion> questions = snapshot.data!;
                      if (questions.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.tintedContainer(),
                          child: const Text(
                            'No questions for this class/subject yet.',
                            style: TextStyle(color: AppTheme.secondaryText),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppTheme.sectionHeader(context, 'Question Bank', icon: Icons.quiz),
                          const SizedBox(height: 4),
                          ...questions.asMap().entries.map(
                            (MapEntry<int, QuizQuestion> entry) {
                              final QuizQuestion question = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: AppTheme.cardDecoration(radius: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          if (question.chapter.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: AppTheme.chapterChip(question.chapter),
                                            ),
                                          Expanded(
                                            child: Text(
                                              question.question,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...question.options.asMap().entries.map(
                                        (MapEntry<int, String> optionEntry) {
                                          final bool isCorrect =
                                              optionEntry.key == question.correctIndex;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 3),
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  isCorrect
                                                      ? Icons.check_circle
                                                      : Icons.circle_outlined,
                                                  size: 16,
                                                  color: isCorrect
                                                      ? const Color(0xFF2E7D32)
                                                      : AppTheme.secondaryText,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    optionEntry.value,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: isCorrect
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                      color: isCorrect
                                                          ? const Color(0xFF2E7D32)
                                                          : AppTheme.darkText,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: <Widget>[
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            color: AppTheme.primaryBlue,
                                            onPressed: () =>
                                                _loadForEdit(question),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18),
                                            color: const Color(0xFFD32F2F),
                                            onPressed: () =>
                                                _deleteQuestion(question.id),
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
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
