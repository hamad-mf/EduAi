import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

    final User? firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-create-failed',
        message: 'User could not be created.',
      );
    }

    await firebaseUser.updateDisplayName(name.trim());

    final bool isAdmin = AppConfig.bootstrapAdminEmails
        .map((String value) => value.toLowerCase().trim())
        .contains(email.toLowerCase().trim());

    final AppUser profile = AppUser(
      id: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      role: isAdmin ? UserRole.admin : UserRole.student,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(firebaseUser.uid).set(profile.toMap());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<AppUser?> profileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(AppUser.fromDoc);
  }

  Future<AppUser?> getProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('users')
        .doc(uid)
        .get();
    return AppUser.fromDoc(doc);
  }

  Future<void> ensureProfile(User firebaseUser) async {
    final DocumentReference<Map<String, dynamic>> ref = _db
        .collection('users')
        .doc(firebaseUser.uid);
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    if (doc.exists) {
      return;
    }

    final AppUser fallback = AppUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!.trim()
          : 'Student',
      email: firebaseUser.email ?? '',
      role: UserRole.student,
      createdAt: DateTime.now(),
    );
    await ref.set(fallback.toMap());
  }
}
