import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

class ReflectionEntry {
  ReflectionEntry({
    required this.id,
    required this.studentId,
    required this.dateLabel,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String dateLabel;
  final String text;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'dateLabel': dateLabel,
      'text': text,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  static ReflectionEntry? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return null;
    }

    return ReflectionEntry(
      id: doc.id,
      studentId: (data['studentId'] as String?) ?? '',
      dateLabel: (data['dateLabel'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      createdAt: _readDate(data['createdAt']),
    );
  }
}
