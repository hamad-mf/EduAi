import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../models/study_material.dart';
import '../../models/subject_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';

class AdminMaterialsPage extends StatefulWidget {
  const AdminMaterialsPage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminMaterialsPage> createState() => _AdminMaterialsPageState();
}

class _AdminMaterialsPageState extends State<AdminMaterialsPage> {
  String? _selectedClassId;
  String? _selectedSubjectId;
  final TextEditingController _chapterController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _pdfUrlController = TextEditingController();

  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _chapterController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _pdfUrlController.dispose();
    super.dispose();
  }

  Future<void> _uploadPdf() async {
    setState(() => _uploading = true);
    try {
      final String url = await CloudinaryService.instance.pickAndUploadPdf();
      _pdfUrlController.text = url;
      _showMessage('PDF uploaded successfully.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _saveMaterial() async {
    if (_selectedClassId == null || _selectedSubjectId == null) {
      _showMessage('Select class and subject first.');
      return;
    }
    if (_chapterController.text.trim().isEmpty ||
        _titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showMessage('Chapter, title, and content are required.');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.saveMaterial(
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
        chapter: _chapterController.text.trim(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        pdfUrl: _pdfUrlController.text.trim(),
        createdBy: widget.admin.id,
      );
      _chapterController.clear();
      _titleController.clear();
      _contentController.clear();
      _pdfUrlController.clear();
      _showMessage('Material saved.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('Could not open PDF link.');
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
                    final List<SubjectModel> allSubjects =
                        subjectSnapshot.data!;
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
                        .where(
                          (SchoolClass item) => item.id == _selectedClassId,
                        )
                        .cast<SchoolClass?>()
                        .firstOrNull;

                    final List<SubjectModel> classSubjects =
                        selectedClass == null
                        ? <SubjectModel>[]
                        : selectedClass.subjectIds
                              .map((String id) => subjectById[id])
                              .whereType<SubjectModel>()
                              .toList();

                    if (classSubjects.isNotEmpty &&
                        (_selectedSubjectId == null ||
                            classSubjects.every(
                              (SubjectModel item) =>
                                  item.id != _selectedSubjectId,
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
                                  'Add Study Material',
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
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _contentController,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    labelText: 'Material text / notes',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _pdfUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'PDF URL (optional)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    FilledButton(
                                      onPressed: _saving ? null : _saveMaterial,
                                      child: Text(
                                        _saving ? 'Saving...' : 'Save Material',
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _uploading ? null : _uploadPdf,
                                      icon: const Icon(Icons.upload_file),
                                      label: Text(
                                        _uploading
                                            ? 'Uploading...'
                                            : 'Upload PDF (Cloudinary)',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Existing Materials',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (_selectedClassId == null ||
                            _selectedSubjectId == null)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Select class and subject to view materials.',
                              ),
                            ),
                          )
                        else
                          StreamBuilder<List<StudyMaterial>>(
                            stream: FirestoreService.instance.streamMaterials(
                              classId: _selectedClassId!,
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
                                        child: Text('No materials added yet.'),
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: materials.map((
                                      StudyMaterial material,
                                    ) {
                                      final String contentPreview =
                                          material.content.length > 140
                                          ? '${material.content.substring(0, 140)}...'
                                          : material.content;
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
                                                      material.title,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      await FirestoreService
                                                          .instance
                                                          .deleteMaterial(
                                                            material.id,
                                                          );
                                                    },
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                'Chapter: ${material.chapter}',
                                              ),
                                              const SizedBox(height: 6),
                                              Text(contentPreview),
                                              if ((material.pdfUrl ?? '')
                                                  .isNotEmpty) ...<Widget>[
                                                const SizedBox(height: 8),
                                                OutlinedButton.icon(
                                                  onPressed: () => _openLink(
                                                    material.pdfUrl!,
                                                  ),
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
