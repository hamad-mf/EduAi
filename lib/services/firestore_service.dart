import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/chat_entry.dart';
import '../models/mood_entry.dart';
import '../models/quiz_attempt.dart';
import '../models/quiz_question.dart';
import '../models/reflection_entry.dart';
import '../models/school_class.dart';
import '../models/study_material.dart';
import '../models/subject_model.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _classes =>
      _db.collection('classes');
  CollectionReference<Map<String, dynamic>> get _subjects =>
      _db.collection('subjects');
  CollectionReference<Map<String, dynamic>> get _materials =>
      _db.collection('materials');
  CollectionReference<Map<String, dynamic>> get _quizQuestions =>
      _db.collection('quiz_questions');
  CollectionReference<Map<String, dynamic>> get _quizAttempts =>
      _db.collection('quiz_attempts');
  CollectionReference<Map<String, dynamic>> get _moodEntries =>
      _db.collection('mood_entries');
  CollectionReference<Map<String, dynamic>> get _reflections =>
      _db.collection('reflections');
  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  Stream<List<SchoolClass>> streamClasses() {
    return _classes
        .orderBy('name')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(SchoolClass.fromDoc)
              .whereType<SchoolClass>()
              .toList(),
        );
  }

  Future<void> saveClass({
    String? id,
    required String name,
    List<String> subjectIds = const <String>[],
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = id == null || id.isEmpty
        ? _classes.doc()
        : _classes.doc(id);
    final bool isCreate = id == null || id.isEmpty;

    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name.trim(),
      'subjectIds': subjectIds,
      'updatedAt': Timestamp.now(),
    };
    if (isCreate) {
      payload['createdAt'] = Timestamp.now();
    }
    await ref.set(payload, SetOptions(merge: true));
  }

  Future<void> updateClassSubjects({
    required String classId,
    required List<String> subjectIds,
  }) async {
    await _classes.doc(classId).update(<String, dynamic>{
      'subjectIds': subjectIds,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteClass(String classId) async {
    await _classes.doc(classId).delete();
  }

  Stream<List<SubjectModel>> streamSubjects() {
    return _subjects
        .orderBy('name')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(SubjectModel.fromDoc)
              .whereType<SubjectModel>()
              .toList(),
        );
  }

  Future<void> saveSubject({String? id, required String name}) async {
    final DocumentReference<Map<String, dynamic>> ref = id == null || id.isEmpty
        ? _subjects.doc()
        : _subjects.doc(id);
    final bool isCreate = id == null || id.isEmpty;

    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name.trim(),
      'updatedAt': Timestamp.now(),
    };
    if (isCreate) {
      payload['createdAt'] = Timestamp.now();
    }
    await ref.set(payload, SetOptions(merge: true));
  }

  Future<void> deleteSubject(String subjectId) async {
    await _subjects.doc(subjectId).delete();
  }

  Future<void> assignClassToStudent({
    required String studentId,
    required String classId,
  }) async {
    await _users.doc(studentId).set(<String, dynamic>{
      'classId': classId,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Stream<List<StudyMaterial>> streamMaterials({
    required String classId,
    required String subjectId,
  }) {
    return _materials
        .where('classId', isEqualTo: classId)
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('chapter')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(StudyMaterial.fromDoc)
              .whereType<StudyMaterial>()
              .toList(),
        );
  }

  Future<void> saveMaterial({
    String? id,
    required String classId,
    required String subjectId,
    required String chapter,
    required String title,
    required String content,
    String? pdfUrl,
    required String createdBy,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = id == null || id.isEmpty
        ? _materials.doc()
        : _materials.doc(id);
    final bool isCreate = id == null || id.isEmpty;

    final Map<String, dynamic> payload = <String, dynamic>{
      'classId': classId,
      'subjectId': subjectId,
      'chapter': chapter.trim(),
      'title': title.trim(),
      'content': content.trim(),
      'pdfUrl': pdfUrl?.trim().isEmpty == true ? null : pdfUrl?.trim(),
      'createdBy': createdBy,
      'updatedAt': Timestamp.now(),
    };
    if (isCreate) {
      payload['createdAt'] = Timestamp.now();
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  Future<void> deleteMaterial(String materialId) async {
    await _materials.doc(materialId).delete();
  }

  Stream<List<QuizQuestion>> streamQuizQuestions({
    required String classId,
    required String subjectId,
    String? chapter,
  }) {
    Query<Map<String, dynamic>> query = _quizQuestions
        .where('classId', isEqualTo: classId)
        .where('subjectId', isEqualTo: subjectId);

    if (chapter != null && chapter.trim().isNotEmpty) {
      query = query.where('chapter', isEqualTo: chapter.trim());
    }

    return query
        .orderBy('chapter')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(QuizQuestion.fromDoc)
              .whereType<QuizQuestion>()
              .toList(),
        );
  }

  Future<void> saveQuizQuestion({
    String? id,
    required String classId,
    required String subjectId,
    required String chapter,
    required String question,
    required List<String> options,
    required int correctIndex,
    required String createdBy,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = id == null || id.isEmpty
        ? _quizQuestions.doc()
        : _quizQuestions.doc(id);
    final bool isCreate = id == null || id.isEmpty;

    final Map<String, dynamic> payload = <String, dynamic>{
      'classId': classId,
      'subjectId': subjectId,
      'chapter': chapter.trim(),
      'question': question.trim(),
      'options': options.map((String option) => option.trim()).toList(),
      'correctIndex': correctIndex,
      'createdBy': createdBy,
      'updatedAt': Timestamp.now(),
    };
    if (isCreate) {
      payload['createdAt'] = Timestamp.now();
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  Future<void> deleteQuizQuestion(String questionId) async {
    await _quizQuestions.doc(questionId).delete();
  }

  Future<List<QuizQuestion>> getRandomQuestions({
    required String classId,
    required String subjectId,
    required int count,
    String? chapter,
  }) async {
    Query<Map<String, dynamic>> query = _quizQuestions
        .where('classId', isEqualTo: classId)
        .where('subjectId', isEqualTo: subjectId);

    if (chapter != null && chapter.trim().isNotEmpty) {
      query = query.where('chapter', isEqualTo: chapter.trim());
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
    final List<QuizQuestion> allQuestions = snapshot.docs
        .map(QuizQuestion.fromDoc)
        .whereType<QuizQuestion>()
        .toList();
    allQuestions.shuffle(Random());
    if (allQuestions.length <= count) {
      return allQuestions;
    }
    return allQuestions.take(count).toList();
  }

  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    final DocumentReference<Map<String, dynamic>> ref = _quizAttempts.doc();
    await ref.set(attempt.toMap());
  }

  Stream<List<QuizAttempt>> streamStudentAttempts(String studentId) {
    return _quizAttempts
        .where('studentId', isEqualTo: studentId)
        .orderBy('attemptedAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(QuizAttempt.fromDoc)
              .whereType<QuizAttempt>()
              .toList(),
        );
  }

  Stream<List<QuizAttempt>> streamAllAttempts() {
    return _quizAttempts
        .orderBy('attemptedAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(QuizAttempt.fromDoc)
              .whereType<QuizAttempt>()
              .toList(),
        );
  }

  Stream<List<MoodEntry>> streamMoodEntries(String studentId) {
    return _moodEntries
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(MoodEntry.fromDoc)
              .whereType<MoodEntry>()
              .toList(),
        );
  }

  Future<void> saveMood({
    required String studentId,
    required String dateLabel,
    required String mood,
    required String suggestion,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _moodEntries.doc();
    await ref.set(<String, dynamic>{
      'studentId': studentId,
      'dateLabel': dateLabel,
      'mood': mood,
      'suggestion': suggestion,
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<ReflectionEntry>> streamReflections(String studentId) {
    return _reflections
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(ReflectionEntry.fromDoc)
              .whereType<ReflectionEntry>()
              .toList(),
        );
  }

  Future<void> saveReflection({
    required String studentId,
    required String dateLabel,
    required String text,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _reflections.doc();
    await ref.set(<String, dynamic>{
      'studentId': studentId,
      'dateLabel': dateLabel,
      'text': text.trim(),
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<ChatEntry>> streamChats(String studentId) {
    return _chats
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(ChatEntry.fromDoc)
              .whereType<ChatEntry>()
              .toList(),
        );
  }

  Future<void> saveChat({
    required String studentId,
    required String userMessage,
    required String aiReply,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _chats.doc();
    await ref.set(<String, dynamic>{
      'studentId': studentId,
      'userMessage': userMessage.trim(),
      'aiReply': aiReply.trim(),
      'createdAt': Timestamp.now(),
    });
  }

  Stream<List<AppUser>> streamStudents() {
    return _users
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs.map(AppUser.fromDoc).whereType<AppUser>().toList(),
        );
  }

  Future<Map<String, int>> getUsageCounts() async {
    final QuerySnapshot<Map<String, dynamic>> studentSnapshot = await _users
        .where('role', isEqualTo: 'student')
        .get();
    final QuerySnapshot<Map<String, dynamic>> attemptSnapshot =
        await _quizAttempts.get();
    final QuerySnapshot<Map<String, dynamic>> chatSnapshot = await _chats.get();
    final QuerySnapshot<Map<String, dynamic>> materialSnapshot =
        await _materials.get();

    return <String, int>{
      'students': studentSnapshot.docs.length,
      'quizAttempts': attemptSnapshot.docs.length,
      'chats': chatSnapshot.docs.length,
      'materials': materialSnapshot.docs.length,
    };
  }
}
