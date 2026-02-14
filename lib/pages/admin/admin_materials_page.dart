import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../models/study_material.dart';
import '../../models/subject_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../student/student_pdf_viewer_page.dart';

class AdminMaterialsPage extends StatefulWidget {
  const AdminMaterialsPage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminMaterialsPage> createState() => _AdminMaterialsPageState();
}

class _AdminMaterialsPageState extends State<AdminMaterialsPage> {
  final TextEditingController _chapterController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _pdfUrlController = TextEditingController();

  String? _selectedClassId;
  String? _selectedSubjectId;
  bool _saving = false;
  bool _uploading = false;
  String? _editingId;

  @override
  void dispose() {
    _chapterController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _pdfUrlController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _chapterController.clear();
    _titleController.clear();
    _contentController.clear();
    _pdfUrlController.clear();
    setState(() => _editingId = null);
  }

  Future<void> _save() async {
    if (_selectedClassId == null || _selectedSubjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select class & subject')));
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await FirestoreService.instance.saveMaterial(
        id: _editingId,
        classId: _selectedClassId!,
        subjectId: _selectedSubjectId!,
        chapter: _chapterController.text.trim(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        pdfUrl: _pdfUrlController.text.trim().isEmpty
            ? null
            : _pdfUrlController.text.trim(),
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

  Future<void> _uploadPdf() async {
    setState(() => _uploading = true);
    try {
      final String url = await CloudinaryService.instance.pickAndUploadPdf();
      _pdfUrlController.text = url;
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _loadForEdit(StudyMaterial material) {
    _chapterController.text = material.chapter;
    _titleController.text = material.title;
    _contentController.text = material.content;
    _pdfUrlController.text = material.pdfUrl ?? '';
    setState(() => _editingId = material.id);
  }

  Future<void> _deleteMaterial(String materialId) async {
    try {
      await FirestoreService.instance.deleteMaterial(materialId);
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
                        _editingId != null ? 'Edit Material' : 'Add Material',
                        icon: Icons.menu_book_outlined,
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
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _contentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pdfUrlController,
                        decoration: const InputDecoration(
                          labelText: 'PDF URL (optional)',
                          prefixIcon: Icon(Icons.picture_as_pdf_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: _uploading ? null : _uploadPdf,
                            icon: _uploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file, size: 18),
                            label: const Text('Upload PDF'),
                          ),
                          const Spacer(),
                          if (_editingId != null)
                            TextButton(
                              onPressed: _clearForm,
                              child: const Text('Cancel'),
                            ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _saving ? null : _save,
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
                                    _editingId != null ? 'Update' : 'Save',
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Materials List ──
                if (_selectedClassId != null && _selectedSubjectId != null)
                  StreamBuilder<List<StudyMaterial>>(
                    stream: FirestoreService.instance.streamMaterials(
                      classId: _selectedClassId!,
                      subjectId: _selectedSubjectId!,
                    ),
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<StudyMaterial>> snapshot,
                    ) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final List<StudyMaterial> materials = snapshot.data!;
                      if (materials.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.tintedContainer(),
                          child: const Text(
                            'No materials for this class/subject yet.',
                            style: TextStyle(color: AppTheme.secondaryText),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppTheme.sectionHeader(context, 'Existing Materials', icon: Icons.library_books),
                          const SizedBox(height: 4),
                          ...materials.map((StudyMaterial material) {
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
                                        Expanded(
                                          child: Text(
                                            material.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (material.chapter.isNotEmpty)
                                          AppTheme.chapterChip(material.chapter),
                                      ],
                                    ),
                                    if (material.content.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 6),
                                      Text(
                                        material.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.secondaryText,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: <Widget>[
                                        if (material.pdfUrl != null &&
                                            material.pdfUrl!.isNotEmpty)
                                          TextButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      StudentPdfViewerPage(
                                                        title: material.title,
                                                        pdfUrl: material.pdfUrl!,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                            label: const Text('View PDF'),
                                          ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          color: AppTheme.primaryBlue,
                                          onPressed: () =>
                                              _loadForEdit(material),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          color: const Color(0xFFD32F2F),
                                          onPressed: () =>
                                              _deleteMaterial(material.id),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
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
