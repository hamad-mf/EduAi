import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.chapter,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String classId;
  final String subjectId;
  final String chapter;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? createdBy;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'classId': classId,
      'subjectId': subjectId,
      'chapter': chapter,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'createdBy': createdBy,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  static QuizQuestion? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return null;
    }

    return QuizQuestion(
      id: doc.id,
      classId: (data['classId'] as String?) ?? '',
      subjectId: (data['subjectId'] as String?) ?? '',
      chapter: (data['chapter'] as String?) ?? '',
      question: (data['question'] as String?) ?? '',
      options: (data['options'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic option) => option.toString())
          .toList(),
      correctIndex: (data['correctIndex'] as num?)?.toInt() ?? 0,
      createdBy: data['createdBy'] as String?,
      createdAt: _readDate(data['createdAt']),
    );
  }
}
