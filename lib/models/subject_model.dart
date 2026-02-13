import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

class SubjectModel {
  SubjectModel({required this.id, required this.name, this.createdAt});

  final String id;
  final String name;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  static SubjectModel? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return null;
    }

    return SubjectModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      createdAt: _readDate(data['createdAt']),
    );
  }
}
