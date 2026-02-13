import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

class QuizAttempt {
  QuizAttempt({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.subjectId,
    required this.chapter,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    required this.questionIds,
    this.attemptedAt,
  });

  final String id;
  final String studentId;
  final String classId;
  final String subjectId;
  final String chapter;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final List<String> questionIds;
  final DateTime? attemptedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'classId': classId,
      'subjectId': subjectId,
      'chapter': chapter,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'scorePercent': scorePercent,
      'questionIds': questionIds,
      'attemptedAt': attemptedAt == null
          ? null
          : Timestamp.fromDate(attemptedAt!),
    };
  }

  static QuizAttempt? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return null;
    }

    return QuizAttempt(
      id: doc.id,
      studentId: (data['studentId'] as String?) ?? '',
      classId: (data['classId'] as String?) ?? '',
      subjectId: (data['subjectId'] as String?) ?? '',
      chapter: (data['chapter'] as String?) ?? '',
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (data['correctAnswers'] as num?)?.toInt() ?? 0,
      scorePercent: (data['scorePercent'] as num?)?.toDouble() ?? 0,
      questionIds: (data['questionIds'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic id) => id.toString())
          .toList(),
      attemptedAt: _readDate(data['attemptedAt']),
    );
  }
}
