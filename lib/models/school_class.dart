import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

class SchoolClass {
  SchoolClass({
    required this.id,
    required this.name,
    this.subjectIds = const <String>[],
    this.createdAt,
  });

  final String id;
  final String name;
  final List<String> subjectIds;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'subjectIds': subjectIds,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  static SchoolClass? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return null;
    }

    return SchoolClass(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Class',
      subjectIds: (data['subjectIds'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic id) => id.toString())
          .toList(),
      createdAt: _readDate(data['createdAt']),
    );
  }
}
