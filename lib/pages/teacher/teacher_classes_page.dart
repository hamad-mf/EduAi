import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_service.dart';

class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({super.key, required this.teacher});

  final AppUser teacher;

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _subjectNameController = TextEditingController();
  bool _savingClass = false;
  bool _savingSubject = false;

  @override
  void dispose() {
    _classNameController.dispose();
    _subjectNameController.dispose();
    super.dispose();
  }

  Future<void> _addClass() async {
    final String name = _classNameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    setState(() => _savingClass = true);
    try {
      await FirestoreService.instance.saveClass(name: name);
      _classNameController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _savingClass = false);
      }
    }
  }

  Future<void> _addSubject() async {
    final String name = _subjectNameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    setState(() => _savingSubject = true);
    try {
      await FirestoreService.instance.saveSubject(name: name);
      _subjectNameController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _savingSubject = false);
      }
    }
  }

  Future<void> _toggleSubjectInClass(
    SchoolClass schoolClass,
    String subjectId,
    bool assign,
  ) async {
    try {
      final List<String> updatedIds = List<String>.from(schoolClass.subjectIds);
      if (assign) {
        if (!updatedIds.contains(subjectId)) {
          updatedIds.add(subjectId);
        }
      } else {
        updatedIds.remove(subjectId);
      }
      await FirestoreService.instance.updateClassSubjects(
        classId: schoolClass.id,
        subjectIds: updatedIds,
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

  Future<void> _deleteClass(String classId) async {
    try {
      await FirestoreService.instance.deleteClass(classId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteSubject(String subjectId) async {
    try {
      await FirestoreService.instance.deleteSubject(subjectId);
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
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<SchoolClass>> classSnapshot,
          ) {
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
                    final List<SubjectModel> subjects = subjectSnapshot.data!;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        // ── Add Class ──
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              AppTheme.sectionHeader(context, 'Add Class', icon: Icons.class_outlined),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: _classNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Class name',
                                        prefixIcon: Icon(Icons.school_outlined),
                                        border: OutlineInputBorder(),
                                      ),
                                      onSubmitted: (_) => _addClass(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  FilledButton(
                                    onPressed: _savingClass ? null : _addClass,
                                    child: _savingClass
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Add'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Add Subject ──
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.cardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              AppTheme.sectionHeader(context, 'Add Subject', icon: Icons.book_outlined),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextField(
                                      controller: _subjectNameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Subject name',
                                        prefixIcon: Icon(Icons.auto_stories_outlined),
                                        border: OutlineInputBorder(),
                                      ),
                                      onSubmitted: (_) => _addSubject(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  FilledButton(
                                    onPressed:
                                        _savingSubject ? null : _addSubject,
                                    child: _savingSubject
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Add'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Class List ──
                        AppTheme.sectionHeader(context, 'Classes', icon: Icons.list_alt),
                        const SizedBox(height: 4),
                        if (classes.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.tintedContainer(),
                            child: const Text(
                              'No classes created yet.',
                              style: TextStyle(color: AppTheme.secondaryText),
                            ),
                          )
                        else
                          ...classes.map((SchoolClass schoolClass) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: AppTheme.accentLeftBorder(radius: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            schoolClass.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Color(0xFFD32F2F),
                                          ),
                                          onPressed: () =>
                                              _deleteClass(schoolClass.id),
                                          tooltip: 'Delete class',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children:
                                          subjects.map((SubjectModel subject) {
                                            final bool assigned = schoolClass
                                                .subjectIds
                                                .contains(subject.id);
                                            return FilterChip(
                                              label: Text(subject.name),
                                              selected: assigned,
                                              onSelected: (bool value) =>
                                                  _toggleSubjectInClass(
                                                    schoolClass,
                                                    subject.id,
                                                    value,
                                                  ),
                                            );
                                          }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 20),

                        // ── Subject List ──
                        AppTheme.sectionHeader(context, 'Subjects', icon: Icons.subject),
                        const SizedBox(height: 4),
                        if (subjects.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.tintedContainer(),
                            child: const Text(
                              'No subjects created yet.',
                              style: TextStyle(color: AppTheme.secondaryText),
                            ),
                          )
                        else
                          ...subjects.map((SubjectModel subject) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: AppTheme.cardDecoration(radius: 12),
                                child: Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.auto_stories_outlined,
                                      color: AppTheme.primaryBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        subject.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: Color(0xFFD32F2F),
                                      ),
                                      onPressed: () =>
                                          _deleteSubject(subject.id),
                                      tooltip: 'Delete subject',
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
  }
}
