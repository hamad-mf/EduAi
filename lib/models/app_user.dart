import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, admin }

UserRole roleFromString(String value) {
  return value.toLowerCase() == 'admin' ? UserRole.admin : UserRole.student;
}

String roleToString(UserRole role) {
  return role == UserRole.admin ? 'admin' : 'student';
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? classId;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'role': roleToString(role),
      'classId': classId,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? classId,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      classId: classId ?? this.classId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static AppUser? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return null;
    }
    return AppUser(
      id: doc.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Student',
      email: (data['email'] as String?) ?? '',
      role: roleFromString((data['role'] as String?) ?? 'student'),
      classId: data['classId'] as String?,
      createdAt: _readDate(data['createdAt']),
    );
  }
}
