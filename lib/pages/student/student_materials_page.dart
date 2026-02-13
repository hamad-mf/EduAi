import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../models/study_material.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_service.dart';

class StudentMaterialsPage extends StatefulWidget {
  const StudentMaterialsPage({super.key, required this.student});

  final AppUser student;

  @override
  State<StudentMaterialsPage> createState() => _StudentMaterialsPageState();
}

class _StudentMaterialsPageState extends State<StudentMaterialsPage> {
  String? _selectedSubjectId;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPdf(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('Could not open PDF.');
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
                final SchoolClass? schoolClass = classes
                    .where(
                      (SchoolClass item) => item.id == widget.student.classId,
                    )
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
                      for (final SubjectModel item in allSubjects)
                        item.id: item,
                    };
                final List<SubjectModel> classSubjects = schoolClass.subjectIds
                    .map((String id) => subjectById[id])
                    .whereType<SubjectModel>()
                    .toList();

                if (classSubjects.isEmpty) {
                  return const Center(
                    child: Text(
                      'No subjects are assigned to your class yet. Ask admin.',
                    ),
                  );
                }

                if (_selectedSubjectId == null ||
                    classSubjects.every(
                      (SubjectModel item) => item.id != _selectedSubjectId,
                    )) {
                  _selectedSubjectId = classSubjects.first.id;
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
                                setState(() => _selectedSubjectId = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedSubjectId != null)
                      StreamBuilder<List<StudyMaterial>>(
                        stream: FirestoreService.instance.streamMaterials(
                          classId: schoolClass.id,
                          subjectId: _selectedSubjectId!,
                        ),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<List<StudyMaterial>> snapshot,
                            ) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final List<StudyMaterial> materials =
                                  snapshot.data!;
                              if (materials.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      'No materials added for this subject yet.',
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: materials.map((
                                  StudyMaterial material,
                                ) {
                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            material.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Chapter: ${material.chapter}'),
                                          const SizedBox(height: 8),
                                          Text(material.content),
                                          if ((material.pdfUrl ?? '')
                                              .isNotEmpty) ...<Widget>[
                                            const SizedBox(height: 10),
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _openPdf(material.pdfUrl!),
                                              icon: const Icon(
                                                Icons.picture_as_pdf,
                                              ),
                                              label: const Text('Open PDF'),
                                            ),
                                          ],
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
