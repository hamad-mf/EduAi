import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

class StudyMaterial {
  StudyMaterial({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.chapter,
    required this.title,
    required this.content,
    this.pdfUrl,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String classId;
  final String subjectId;
  final String chapter;
  final String title;
  final String content;
  final String? pdfUrl;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'classId': classId,
      'subjectId': subjectId,
      'chapter': chapter,
      'title': title,
      'content': content,
      'pdfUrl': pdfUrl,
      'createdBy': createdBy,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static StudyMaterial? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return null;
    }

    return StudyMaterial(
      id: doc.id,
      classId: (data['classId'] as String?) ?? '',
      subjectId: (data['subjectId'] as String?) ?? '',
      chapter: (data['chapter'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      pdfUrl: data['pdfUrl'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }
}
