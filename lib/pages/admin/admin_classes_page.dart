import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_service.dart';

class AdminClassesPage extends StatefulWidget {
  const AdminClassesPage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<AdminClassesPage> {
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  bool _savingClass = false;
  bool _savingSubject = false;

  @override
  void dispose() {
    _classController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    final String value = _classController.text.trim();
    if (value.isEmpty) {
      return;
    }

    setState(() => _savingClass = true);
    try {
      await FirestoreService.instance.saveClass(name: value);
      _classController.clear();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _savingClass = false);
      }
    }
  }

  Future<void> _createSubject() async {
    final String value = _subjectController.text.trim();
    if (value.isEmpty) {
      return;
    }

    setState(() => _savingSubject = true);
    try {
      await FirestoreService.instance.saveSubject(name: value);
      _subjectController.clear();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _savingSubject = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _manageClassSubjects(
    SchoolClass schoolClass,
    List<SubjectModel> allSubjects,
  ) async {
    final Set<String> selected = schoolClass.subjectIds.toSet();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Assign Subjects - ${schoolClass.name}'),
          content: StatefulBuilder(
            builder:
                (
                  BuildContext context,
                  void Function(void Function()) setDialogState,
                ) {
                  return SizedBox(
                    width: 320,
                    child: allSubjects.isEmpty
                        ? const Text('No subjects found. Add subjects first.')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: allSubjects.length,
                            itemBuilder: (BuildContext context, int index) {
                              final SubjectModel subject = allSubjects[index];
                              return CheckboxListTile(
                                value: selected.contains(subject.id),
                                title: Text(subject.name),
                                onChanged: (bool? checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selected.add(subject.id);
                                    } else {
                                      selected.remove(subject.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  );
                },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await FirestoreService.instance.updateClassSubjects(
                    classId: schoolClass.id,
                    subjectIds: selected.toList(),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                } catch (error) {
                  if (mounted) {
                    _showMessage(error.toString());
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
                    final Map<String, SubjectModel> subjectById =
                        <String, SubjectModel>{
                          for (final SubjectModel subject in subjects)
                            subject.id: subject,
                        };

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
                                  'Add Class',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _classController,
                                  decoration: const InputDecoration(
                                    hintText: 'Std 6 / Std 7 / Std 8',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton(
                                  onPressed: _savingClass ? null : _createClass,
                                  child: Text(
                                    _savingClass ? 'Saving...' : 'Add Class',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Add Subject',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _subjectController,
                                  decoration: const InputDecoration(
                                    hintText: 'Math / Science / English',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton(
                                  onPressed: _savingSubject
                                      ? null
                                      : _createSubject,
                                  child: Text(
                                    _savingSubject
                                        ? 'Saving...'
                                        : 'Add Subject',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Classes (${classes.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (classes.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No classes created yet.'),
                            ),
                          ),
                        ...classes.map((SchoolClass schoolClass) {
                          final List<String> names = schoolClass.subjectIds
                              .map(
                                (String id) =>
                                    subjectById[id]?.name ?? 'Unknown',
                              )
                              .toList();
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          schoolClass.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _manageClassSubjects(
                                          schoolClass,
                                          subjects,
                                        ),
                                        child: const Text('Assign Subjects'),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          await FirestoreService.instance
                                              .deleteClass(schoolClass.id);
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (names.isEmpty)
                                    const Text('No subjects assigned yet')
                                  else
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: names
                                          .map(
                                            (String name) =>
                                                Chip(label: Text(name)),
                                          )
                                          .toList(),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Text(
                          'Subjects (${subjects.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (subjects.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No subjects created yet.'),
                            ),
                          ),
                        ...subjects.map(
                          (SubjectModel subject) => Card(
                            child: ListTile(
                              title: Text(subject.name),
                              trailing: IconButton(
                                onPressed: () async {
                                  await FirestoreService.instance.deleteSubject(
                                    subject.id,
                                  );
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
            );
          },
    );
  }
}
