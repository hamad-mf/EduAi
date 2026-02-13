import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

class MoodEntry {
  MoodEntry({
    required this.id,
    required this.studentId,
    required this.dateLabel,
    required this.mood,
    required this.suggestion,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String dateLabel;
  final String mood;
  final String suggestion;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'dateLabel': dateLabel,
      'mood': mood,
      'suggestion': suggestion,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  static MoodEntry? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return null;
    }

    return MoodEntry(
      id: doc.id,
      studentId: (data['studentId'] as String?) ?? '',
      dateLabel: (data['dateLabel'] as String?) ?? '',
      mood: (data['mood'] as String?) ?? '',
      suggestion: (data['suggestion'] as String?) ?? '',
      createdAt: _readDate(data['createdAt']),
    );
  }
}
