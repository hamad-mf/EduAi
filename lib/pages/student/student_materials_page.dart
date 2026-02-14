import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_service.dart';
import 'student_subject_details_page.dart';

class StudentMaterialsPage extends StatelessWidget {
  const StudentMaterialsPage({super.key, required this.student});

  final AppUser student;

  @override
  Widget build(BuildContext context) {
    if (student.classId == null) {
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
                    'Your class is not assigned yet. Please contact your teacher.',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                    final SchoolClass? schoolClass = classes
                        .where((SchoolClass item) => item.id == student.classId)
                        .cast<SchoolClass?>()
                        .firstOrNull;

                    if (schoolClass == null) {
                      return const Center(
                        child: Text(
                          'Assigned class not found. Please contact your teacher.',
                        ),
                      );
                    }

                    final Map<String, SubjectModel> subjectById =
                        <String, SubjectModel>{
                          for (final SubjectModel item in allSubjects)
                            item.id: item,
                        };
                    final List<SubjectModel> classSubjects = schoolClass
                        .subjectIds
                        .map((String id) => subjectById[id])
                        .whereType<SubjectModel>()
                        .toList();

                    if (classSubjects.isEmpty) {
                      return const Center(
                        child: Text(
                          'No subjects are assigned to your class yet.',
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        // ── Class Info Card ──
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.cardDecoration(),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3EDFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.school_outlined,
                                  color: AppTheme.primaryBlue,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      schoolClass.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: AppTheme.darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Tap a subject to view chapters and notes',
                                      style: TextStyle(
                                        color: AppTheme.secondaryText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTheme.sectionHeader(context, 'Subjects', icon: Icons.book_outlined),
                        const SizedBox(height: 4),
                        ...classSubjects.asMap().entries.map(
                          (MapEntry<int, SubjectModel> entry) {
                            final SubjectModel subject = entry.value;
                            final List<Color> colors = <Color>[
                              const Color(0xFF1565C0),
                              const Color(0xFF0277BD),
                              const Color(0xFF1976D2),
                              const Color(0xFF0288D1),
                              const Color(0xFF1E88E5),
                            ];
                            final Color iconColor = colors[entry.key % colors.length];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => StudentSubjectDetailsPage(
                                          student: student,
                                          schoolClass: schoolClass,
                                          subject: subject,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: AppTheme.cardDecoration(),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: iconColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.auto_stories_outlined,
                                            color: iconColor,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                subject.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: AppTheme.darkText,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'Open subject details',
                                                style: TextStyle(
                                                  color: AppTheme.secondaryText,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: AppTheme.secondaryText,
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
