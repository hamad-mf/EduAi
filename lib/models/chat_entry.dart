import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

class ChatEntry {
  ChatEntry({
    required this.id,
    required this.studentId,
    required this.userMessage,
    required this.aiReply,
    this.createdAt,
  });

  final String id;
  final String studentId;
  final String userMessage;
  final String aiReply;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'userMessage': userMessage,
      'aiReply': aiReply,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  static ChatEntry? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return null;
    }

    return ChatEntry(
      id: doc.id,
      studentId: (data['studentId'] as String?) ?? '',
      userMessage: (data['userMessage'] as String?) ?? '',
      aiReply: (data['aiReply'] as String?) ?? '',
      createdAt: _readDate(data['createdAt']),
    );
  }
}
