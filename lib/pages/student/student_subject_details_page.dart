import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../models/study_material.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_service.dart';
import 'student_pdf_viewer_page.dart';

class StudentSubjectDetailsPage extends StatelessWidget {
  const StudentSubjectDetailsPage({
    super.key,
    required this.student,
    required this.schoolClass,
    required this.subject,
  });

  final AppUser student;
  final SchoolClass schoolClass;
  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.pageBackgroundGradient,
        ),
        child: StreamBuilder<List<StudyMaterial>>(
          stream: FirestoreService.instance.streamMaterials(
            classId: schoolClass.id,
            subjectId: subject.id,
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.tintedContainer(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No materials have been uploaded for this subject.',
                            style: TextStyle(color: AppTheme.secondaryText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: materials.length,
              itemBuilder: (BuildContext context, int index) {
                final StudyMaterial material = materials[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(),
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
                                  fontSize: 15,
                                  color: AppTheme.darkText,
                                ),
                              ),
                            ),
                            if (material.chapter.isNotEmpty)
                              AppTheme.chapterChip(material.chapter),
                          ],
                        ),
                        if (material.content.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            material.content,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (material.pdfUrl != null &&
                            material.pdfUrl!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => StudentPdfViewerPage(
                                      title: material.title,
                                      pdfUrl: material.pdfUrl!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                              label: const Text('Open PDF Notes'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
