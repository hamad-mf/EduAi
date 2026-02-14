# EduAI — Full Project Documentation

> **Version:** 1.0.0  
> **Platform:** Flutter (Android, iOS, Web, Windows, macOS, Linux)  
> **Backend:** Firebase (Authentication + Cloud Firestore)  
> **AI Integration:** Google Gemini API  
> **Project Type:** College / Demo Architecture

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [Project Structure](#3-project-structure)
4. [Application Architecture](#4-application-architecture)
5. [Configuration](#5-configuration)
6. [Data Models](#6-data-models)
7. [Firestore Database Design](#7-firestore-database-design)
8. [Firestore Security Rules](#8-firestore-security-rules)
9. [Firestore Composite Indexes](#9-firestore-composite-indexes)
10. [Services Layer](#10-services-layer)
11. [UI Layer — Pages & Screens](#11-ui-layer--pages--screens)
12. [Theming & Design System](#12-theming--design-system)
13. [User Flows](#13-user-flows)
14. [Setup & Deployment Guide](#14-setup--deployment-guide)
15. [Important Notes & Limitations](#15-important-notes--limitations)

---

## 1. Project Overview

**EduAI** is an AI-powered educational mobile application built with **Flutter** and **Firebase**. It serves two distinct user roles:

- **Students** — Access study materials, take quizzes, track their wellbeing, and interact with an AI chatbot for academic help.
- **Admins** — Manage classes, subjects, study materials, quiz questions, view student performance, and configure system settings.

### Key Features

| Feature | Student | Admin |
|---|---|---|
| Email registration & login | ✅ | ✅ |
| Subject-wise study materials (text + PDF) | ✅ (read) | ✅ (CRUD) |
| Chapter-wise random quizzes (MCQ) | ✅ | ✅ (CRUD) |
| Quiz score history & progress | ✅ | ✅ (view all) |
| Daily mood tracking & wellbeing suggestions | ✅ | — |
| Daily reflection journal | ✅ | — |
| AI Chatbot (Gemini API) | ✅ | — |
| Class & subject management | — | ✅ |
| Student management & class assignment | — | ✅ |
| System usage statistics | — | ✅ |
| PDF upload via Cloudinary | — | ✅ |
| Gemini API key management | — | ✅ |

---

## 2. Tech Stack & Dependencies

### Core Framework
- **Flutter** (SDK `^3.9.2`) — Cross-platform UI framework
- **Dart** — Programming language

### Firebase Services
| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | `^3.15.2` | Firebase initialization |
| `firebase_auth` | `^5.7.0` | Email/password authentication |
| `cloud_firestore` | `^5.6.12` | NoSQL cloud database |

### AI & External APIs
| Package | Version | Purpose |
|---|---|---|
| `http` | `^1.5.0` | HTTP client for Gemini API calls |
| `file_picker` | `^10.3.2` | File selection for PDF uploads |

### UI & PDF
| Package | Version | Purpose |
|---|---|---|
| `google_fonts` | `^6.2.1` | Inter font family |
| `syncfusion_flutter_pdfviewer` | `^29.2.11` | In-app PDF viewing |
| `syncfusion_flutter_pdf` | `^29.2.11` | PDF text extraction for AI context |
| `intl` | `^0.20.2` | Date/time formatting |
| `url_launcher` | `^6.3.2` | External URL opening |
| `path_provider` | `^2.1.5` | File system path access |

### Dev Dependencies
| Package | Version | Purpose |
|---|---|---|
| `flutter_lints` | `^5.0.0` | Lint rules |
| `flutter_test` | SDK | Testing framework |

---

## 3. Project Structure

```
EduAi/
├── lib/
│   ├── main.dart                          # Entry point — Firebase init + runApp
│   ├── app.dart                           # MaterialApp + root auth gate
│   ├── firebase_options.dart              # Auto-generated Firebase config
│   │
│   ├── config/
│   │   ├── app_config.dart                # Cloudinary, admin emails, mood list
│   │   ├── app_theme.dart                 # Material 3 theme + reusable widgets
│   │   └── firebase_options_local.dart    # Local/placeholder Firebase config
│   │
│   ├── models/                            # 9 data model classes
│   │   ├── app_user.dart                  # User profile (student/admin role)
│   │   ├── chat_entry.dart                # AI chat message pair
│   │   ├── mood_entry.dart                # Daily mood record
│   │   ├── quiz_attempt.dart              # Quiz attempt result
│   │   ├── quiz_question.dart             # MCQ question (4 options)
│   │   ├── reflection_entry.dart          # Daily journal entry
│   │   ├── school_class.dart              # Class (e.g., Std 6, Std 7)
│   │   ├── study_material.dart            # Study material (text + PDF URL)
│   │   └── subject_model.dart             # Subject (e.g., Maths, Science)
│   │
│   ├── services/                          # 5 singleton services
│   │   ├── auth_service.dart              # Firebase Auth wrapper
│   │   ├── firestore_service.dart         # All Firestore CRUD operations
│   │   ├── chat_api_service.dart          # Gemini API integration
│   │   ├── cloudinary_service.dart        # PDF upload to Cloudinary
│   │   └── wellbeing_service.dart         # Mood → suggestion mapping
│   │
│   └── pages/                             # UI screens
│       ├── auth/
│       │   └── auth_page.dart             # Login / Sign-up screen
│       ├── shared/
│       │   └── loading_page.dart          # Animated loading screen
│       ├── admin/
│       │   ├── admin_shell_page.dart       # Bottom nav shell (5 tabs)
│       │   ├── admin_classes_page.dart     # Class & subject management
│       │   ├── admin_materials_page.dart   # Study material CRUD
│       │   ├── admin_quiz_page.dart        # Quiz question bank CRUD
│       │   ├── admin_students_page.dart    # Student list & class assignment
│       │   ├── admin_usage_page.dart       # System usage statistics
│       │   └── admin_api_settings_page.dart# Gemini API key management
│       └── student/
│           ├── student_shell_page.dart         # Bottom nav shell (5 tabs)
│           ├── student_dashboard_page.dart     # Home dashboard & stats
│           ├── student_materials_page.dart     # Subject list for materials
│           ├── student_subject_details_page.dart # Material viewer per subject
│           ├── student_pdf_viewer_page.dart    # In-app PDF viewer
│           ├── student_quiz_page.dart          # Quiz selection & attempt
│           ├── student_wellbeing_page.dart     # Mood + reflection journal
│           └── student_chat_page.dart          # AI chatbot interface
│
├── android/                               # Android platform config
├── ios/                                   # iOS platform config
├── web/                                   # Web platform config
├── windows/                               # Windows platform config
├── macos/                                 # macOS platform config
├── linux/                                 # Linux platform config
├── assets/                                # App assets
├── docs/                                  # Documentation files
├── firebase.json                          # Firebase project config
├── firestore.rules                        # Firestore security rules
├── firestore.indexes.json                 # Firestore composite indexes
├── pubspec.yaml                           # Flutter package config
└── analysis_options.yaml                  # Dart analysis rules
```

---

## 4. Application Architecture

### Architecture Pattern

The app follows a **Service-Oriented Architecture** with clear separation:

```
┌───────────────────────────────────────────────────────────┐
│                       UI Layer (Pages)                     │
│  ┌──────────┐  ┌───────────┐  ┌───────────┐  ┌─────────┐ │
│  │   Auth   │  │  Student   │  │   Admin   │  │ Shared  │ │
│  │   Page   │  │   Shell    │  │   Shell   │  │ Loading │ │
│  └────┬─────┘  └─────┬─────┘  └─────┬─────┘  └─────────┘ │
│       │              │              │                      │
├───────┴──────────────┴──────────────┴──────────────────────┤
│                    Services Layer (Singletons)              │
│  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌─────────────┐  │
│  │   Auth   │ │ Firestore │ │ Chat API │ │  Cloudinary  │  │
│  │ Service  │ │  Service  │ │ Service  │ │   Service    │  │
│  └────┬─────┘ └─────┬─────┘ └────┬─────┘ └──────┬──────┘  │
│       │             │            │               │         │
├───────┴─────────────┴────────────┴───────────────┴─────────┤
│                    Data Layer (Models)                       │
│  AppUser │ SchoolClass │ SubjectModel │ StudyMaterial │ ... │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                   External Services                          │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐ │
│  │ Firebase Auth │  │  Firestore   │  │   Gemini API      │ │
│  │              │  │  Database    │  │   (Google AI)      │ │
│  └──────────────┘  └──────────────┘  └───────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Detail |
|---|---|
| **State Management** | StreamBuilder/FutureBuilder (no external state library) |
| **Navigation** | Bottom NavigationBar with IndexedStack for tab persistence |
| **Dependency Injection** | Singleton pattern (`ServiceName.instance`) |
| **Auth Flow** | StreamBuilder on `authStateChanges()` → role-based routing |
| **Firebase Storage** | Not used — PDFs hosted on Cloudinary or external URLs |

### App Entry & Root Routing

**`main.dart`** — Initializes Firebase and runs the app:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const EduAiApp());
}
```

**`app.dart`** — Contains the `_RootGate` widget with a 3-layer auth gate:

1. **`StreamBuilder<User?>`** — Listens to Firebase Auth state. If no user → show `AuthPage`.
2. **`FutureBuilder`** — Calls `AuthService.ensureProfile()` to guarantee a Firestore user document exists.
3. **`StreamBuilder<AppUser?>`** — Streams the user's Firestore profile. Routes to `AdminShellPage` if role is `admin`, or `StudentShellPage` if role is `student`.

---

## 5. Configuration

### `lib/config/app_config.dart`

Central configuration file with static constants:

```dart
class AppConfig {
  // Cloudinary settings for optional PDF hosting
  static const String cloudinaryCloudName = 'dzzjiiwuy';
  static const String cloudinaryUnsignedPreset = 'eduai_pdf_unsigned';

  // Emails that auto-become admin on signup
  static const List<String> bootstrapAdminEmails = ['admin@eduai.com'];

  // Available mood categories
  static const List<String> moodCategories = [
    'Happy', 'Calm', 'Neutral', 'Stressed', 'Tired', 'Anxious',
  ];
}
```

| Config | Purpose |
|---|---|
| `cloudinaryCloudName` | Cloudinary account name for PDF uploads |
| `cloudinaryUnsignedPreset` | Unsigned upload preset (no server-side auth needed) |
| `bootstrapAdminEmails` | Emails that are auto-assigned admin role at signup |
| `moodCategories` | Predefined mood options for wellbeing tracking |

### Gemini API Key

The Gemini API key is **not hardcoded** — it is stored in Firestore at `app_config/gemini` and managed through the admin panel's API Settings page:

```
Firestore: app_config/gemini → { apiKey: "...", model: "..." }
```

The default model is `gemini-2.5-flash-lite` if no model is specified.

---

## 6. Data Models

All models are located in `lib/models/` and follow a consistent pattern:
- Immutable fields (all `final`)
- `toMap()` — Converts to Firestore-compatible Map
- `fromDoc()` — Static factory from `DocumentSnapshot`
- Firestore `Timestamp` ↔ `DateTime` conversion via `_readDate()` helper

---

### 6.1 `AppUser`

**File:** `lib/models/app_user.dart`  
**Collection:** `users`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Firebase Auth UID (document ID) |
| `name` | `String` | Display name |
| `email` | `String` | Email address |
| `role` | `UserRole` | Enum: `student` or `admin` |
| `classId` | `String?` | Assigned class ID (students only) |
| `createdAt` | `DateTime?` | Account creation timestamp |

**Role Enum:**
```dart
enum UserRole { student, admin }
```

Includes `copyWith()` for immutable updates. Role is determined at signup by checking if the email is in `AppConfig.bootstrapAdminEmails`.

---

### 6.2 `SchoolClass`

**File:** `lib/models/school_class.dart`  
**Collection:** `classes`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `name` | `String` | Class name (e.g., "Std 6", "Std 7") |
| `subjectIds` | `List<String>` | IDs of assigned subjects |
| `createdAt` | `DateTime?` | Creation timestamp |

---

### 6.3 `SubjectModel`

**File:** `lib/models/subject_model.dart`  
**Collection:** `subjects`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `name` | `String` | Subject name (e.g., "Mathematics") |
| `createdAt` | `DateTime?` | Creation timestamp |

---

### 6.4 `StudyMaterial`

**File:** `lib/models/study_material.dart`  
**Collection:** `materials`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `classId` | `String` | Linked class ID |
| `subjectId` | `String` | Linked subject ID |
| `chapter` | `String` | Chapter name/number |
| `title` | `String` | Material title |
| `content` | `String` | Text content of the material |
| `pdfUrl` | `String?` | Optional PDF URL (Cloudinary or external) |
| `createdBy` | `String?` | Admin UID who created it |
| `createdAt` | `DateTime?` | Creation timestamp |
| `updatedAt` | `DateTime?` | Last update timestamp |

---

### 6.5 `QuizQuestion`

**File:** `lib/models/quiz_question.dart`  
**Collection:** `quiz_questions`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `classId` | `String` | Linked class ID |
| `subjectId` | `String` | Linked subject ID |
| `chapter` | `String` | Chapter name |
| `question` | `String` | Question text |
| `options` | `List<String>` | 4 answer options |
| `correctIndex` | `int` | Index of correct answer (0-3) |
| `createdBy` | `String?` | Admin UID who created it |
| `createdAt` | `DateTime?` | Creation timestamp |

---

### 6.6 `QuizAttempt`

**File:** `lib/models/quiz_attempt.dart`  
**Collection:** `quiz_attempts`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `studentId` | `String` | Student's UID |
| `classId` | `String` | Class ID |
| `subjectId` | `String` | Subject ID |
| `chapter` | `String` | Chapter name |
| `totalQuestions` | `int` | Total questions in the quiz |
| `correctAnswers` | `int` | Number of correct answers |
| `scorePercent` | `double` | Score as percentage |
| `questionIds` | `List<String>` | IDs of questions in this attempt |
| `attemptedAt` | `DateTime?` | Attempt timestamp |

---

### 6.7 `MoodEntry`

**File:** `lib/models/mood_entry.dart`  
**Collection:** `mood_entries`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `studentId` | `String` | Student's UID |
| `dateLabel` | `String` | Formatted date string |
| `mood` | `String` | Selected mood category |
| `suggestion` | `String` | Wellbeing suggestion for this mood |
| `createdAt` | `DateTime?` | Entry timestamp |

---

### 6.8 `ReflectionEntry`

**File:** `lib/models/reflection_entry.dart`  
**Collection:** `reflections`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `studentId` | `String` | Student's UID |
| `dateLabel` | `String` | Formatted date string |
| `text` | `String` | Reflection journal text |
| `createdAt` | `DateTime?` | Entry timestamp |

---

### 6.9 `ChatEntry`

**File:** `lib/models/chat_entry.dart`  
**Collection:** `chats`

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Document ID |
| `studentId` | `String` | Student's UID |
| `userMessage` | `String` | User's message |
| `aiReply` | `String` | AI's response |
| `createdAt` | `DateTime?` | Message timestamp |

---

## 7. Firestore Database Design

### Entity-Relationship Overview

```
┌─────────┐      ┌──────────────┐      ┌──────────────┐
│ classes │ 1──N │ subjectIds[] │──── →│  subjects    │
│         │      │ (in class)   │      │              │
└────┬────┘      └──────────────┘      └──────┬───────┘
     │                                        │
     │ classId                       subjectId │
     ├─────────────────┬──────────────────────┤
     ▼                 ▼                      ▼
┌────────────┐  ┌──────────────┐      ┌──────────────┐
│ materials  │  │quiz_questions│      │   users      │
│(classId,   │  │(classId,     │      │(classId,     │
│ subjectId) │  │ subjectId)   │      │ role)        │
└────────────┘  └──────────────┘      └──────┬───────┘
                                             │ studentId
              ┌──────────┬───────────┬───────┼────────┐
              ▼          ▼           ▼       ▼        ▼
        ┌──────────┐┌──────────┐┌────────┐┌──────┐┌─────────┐
        │  quiz    ││  mood    ││reflect-││chats ││app_     │
        │ attempts ││ entries  ││ ions   ││      ││config   │
        └──────────┘└──────────┘└────────┘└──────┘└─────────┘
```

### Collections Summary

| Collection | Document ID | Key Fields | Owner |
|---|---|---|---|
| `users` | Firebase Auth UID | name, email, role, classId | Self (create), Admin (update) |
| `classes` | Auto-generated | name, subjectIds[] | Admin |
| `subjects` | Auto-generated | name | Admin |
| `materials` | Auto-generated | classId, subjectId, chapter, title, content, pdfUrl | Admin |
| `quiz_questions` | Auto-generated | classId, subjectId, chapter, question, options[], correctIndex | Admin |
| `quiz_attempts` | Auto-generated | studentId, classId, subjectId, chapter, scorePercent | Student (create) |
| `mood_entries` | Auto-generated | studentId, dateLabel, mood, suggestion | Student (create only) |
| `reflections` | Auto-generated | studentId, dateLabel, text | Student (create only) |
| `chats` | Auto-generated | studentId, userMessage, aiReply | Student (create), Admin/Self (delete) |
| `app_config` | Semantic (e.g., `gemini`) | apiKey, model | Admin |

---

## 8. Firestore Security Rules

**File:** `firestore.rules`

The security rules enforce role-based access control using three helper functions:

```javascript
function signedIn()  → request.auth != null
function isSelf(uid) → signedIn() && request.auth.uid == uid
function isAdmin()   → signedIn() && user doc role == 'admin'
```

### Per-Collection Rules

| Collection | Read | Create | Update | Delete |
|---|---|---|---|---|
| `users` | Self or Admin | Self only | Admin only | Admin only |
| `classes` | Any signed-in | Admin only | Admin only | Admin only |
| `subjects` | Any signed-in | Admin only | Admin only | Admin only |
| `app_config` | Any signed-in | Admin only | Admin only | Admin only |
| `materials` | Any signed-in | Admin only | Admin only | Admin only |
| `quiz_questions` | Any signed-in | Admin only | Admin only | Admin only |
| `quiz_attempts` | Admin or Owner | Owner only (verified) | Admin only | Admin only |
| `mood_entries` | Admin or Owner | Owner only (verified) | ❌ Never | ❌ Never |
| `reflections` | Admin or Owner | Owner only (verified) | ❌ Never | ❌ Never |
| `chats` | Admin or Owner | Owner only (verified) | ❌ Never | Admin or Owner |

**Key security features:**
- `quiz_attempts`, `mood_entries`, `reflections`, `chats` — The `create` rule verifies `request.resource.data.studentId == request.auth.uid` to prevent impersonation.
- `mood_entries` and `reflections` are **immutable** once created (no update/delete).
- `chats` can be deleted by the student themselves or by admin.

---

## 9. Firestore Composite Indexes

**File:** `firestore.indexes.json`

Six composite indexes are required for the app's queries:

| Collection | Fields | Purpose |
|---|---|---|
| `materials` | classId ↑, subjectId ↑, chapter ↑ | Stream materials filtered by class + subject, ordered by chapter |
| `quiz_questions` | classId ↑, subjectId ↑, chapter ↑ | Stream quiz questions filtered by class + subject + chapter |
| `quiz_attempts` | studentId ↑, attemptedAt ↓ | Student's quiz history ordered by date (newest first) |
| `mood_entries` | studentId ↑, createdAt ↓ | Student's mood history ordered by date |
| `reflections` | studentId ↑, createdAt ↓ | Student's reflection journal ordered by date |
| `chats` | studentId ↑, createdAt ↓ | Student's chat history ordered by date |

---

## 10. Services Layer

All services use the **Singleton pattern** with a private constructor and a static `instance` field:

```dart
class ServiceName {
  ServiceName._();
  static final ServiceName instance = ServiceName._();
}
```

---

### 10.1 `AuthService`

**File:** `lib/services/auth_service.dart`

Wraps Firebase Authentication with profile management.

| Method | Description |
|---|---|
| `authStateChanges()` | Returns a `Stream<User?>` of Firebase Auth state changes |
| `signIn(email, password)` | Signs in with email/password |
| `signUp(name, email, password)` | Creates account, sets display name, creates Firestore user doc. Assigns admin role if email is in `bootstrapAdminEmails` |
| `signOut()` | Signs out the current user |
| `profileStream(uid)` | Returns a `Stream<AppUser?>` from the `users` Firestore collection |
| `getProfile(uid)` | One-shot fetch of user profile |
| `ensureProfile(firebaseUser)` | Creates a Firestore user document if one doesn't exist (fallback for edge cases) |

**Signup Flow:**
1. Create Firebase Auth account
2. Update display name
3. Check if email is in `bootstrapAdminEmails`
4. Create `users/{uid}` document with appropriate role

---

### 10.2 `FirestoreService`

**File:** `lib/services/firestore_service.dart` (524 lines)

The central data access layer. Provides CRUD operations for all 10 Firestore collections via typed collection references.

#### Collection References
```dart
_users, _classes, _subjects, _materials, _quizQuestions,
_quizAttempts, _moodEntries, _reflections, _chats, _appConfig
```

#### Methods by Domain

**Classes:**
| Method | Returns | Description |
|---|---|---|
| `streamClasses()` | `Stream<List<SchoolClass>>` | Real-time ordered list of all classes |
| `saveClass(id?, name, subjectIds)` | `Future<void>` | Create or update a class |
| `updateClassSubjects(classId, subjectIds)` | `Future<void>` | Update subject assignments |
| `deleteClass(classId)` | `Future<void>` | Delete a class document |

**Subjects:**
| Method | Returns | Description |
|---|---|---|
| `streamSubjects()` | `Stream<List<SubjectModel>>` | Real-time ordered list of all subjects |
| `saveSubject(id?, name)` | `Future<void>` | Create or update a subject |
| `deleteSubject(subjectId)` | `Future<void>` | Delete a subject document |

**Students:**
| Method | Returns | Description |
|---|---|---|
| `assignClassToStudent(studentId, classId)` | `Future<void>` | Assign a class to a student |
| `streamStudents()` | `Stream<List<AppUser>>` | Real-time list of all student users |

**Materials:**
| Method | Returns | Description |
|---|---|---|
| `streamMaterials(classId, subjectId)` | `Stream<List<StudyMaterial>>` | Filtered materials stream |
| `streamClassMaterials(classId)` | `Stream<List<StudyMaterial>>` | All materials for a class |
| `saveMaterial(...)` | `Future<void>` | Create or update a material |
| `deleteMaterial(materialId)` | `Future<void>` | Delete a material |

**Quiz:**
| Method | Returns | Description |
|---|---|---|
| `streamQuizQuestions(classId, subjectId, chapter?)` | `Stream<List<QuizQuestion>>` | Filtered quiz question stream |
| `saveQuizQuestion(...)` | `Future<void>` | Create or update a question |
| `deleteQuizQuestion(questionId)` | `Future<void>` | Delete a question |
| `getRandomQuestions(classId, subjectId, count, chapter?)` | `Future<List<QuizQuestion>>` | Fetch N random questions (shuffled) |
| `saveQuizAttempt(attempt)` | `Future<void>` | Save a quiz attempt result |
| `streamStudentAttempts(studentId)` | `Stream<List<QuizAttempt>>` | Student's quiz history |
| `streamAllAttempts()` | `Stream<List<QuizAttempt>>` | All quiz attempts (admin view) |

**Wellbeing:**
| Method | Returns | Description |
|---|---|---|
| `streamMoodEntries(studentId)` | `Stream<List<MoodEntry>>` | Student's mood history |
| `saveMood(studentId, dateLabel, mood, suggestion)` | `Future<void>` | Save a mood entry |
| `streamReflections(studentId)` | `Stream<List<ReflectionEntry>>` | Student's reflections |
| `saveReflection(studentId, dateLabel, text)` | `Future<void>` | Save a reflection |

**Chat:**
| Method | Returns | Description |
|---|---|---|
| `streamChats(studentId)` | `Stream<List<ChatEntry>>` | Last 50 chat entries (real-time) |
| `getRecentChats(studentId, limit)` | `Future<List<ChatEntry>>` | Recent chats for AI context |
| `saveChat(studentId, userMessage, aiReply)` | `Future<void>` | Save a chat pair |
| `clearChats(studentId)` | `Future<int>` | Batch-delete all chats (400/batch) |

**Config:**
| Method | Returns | Description |
|---|---|---|
| `getGeminiApiKey()` | `Future<String>` | Read Gemini API key from `app_config/gemini` |
| `saveGeminiApiKey(apiKey)` | `Future<void>` | Save API key to Firestore |

**Usage:**
| Method | Returns | Description |
|---|---|---|
| `getUsageCounts()` | `Future<Map<String, int>>` | Count of students, quiz attempts, chats, materials |

---

### 10.3 `ChatApiService`

**File:** `lib/services/chat_api_service.dart` (291 lines)

Integrates Google's Gemini generative AI API for the chatbot feature.

#### Configuration
- API key and model name are loaded from Firestore (`app_config/gemini`)
- Default model: `gemini-2.5-flash-lite`
- Config is loaded once and cached (`_configLoaded` flag)
- Flexible field name matching (supports `apiKey`, `api_key`, `apikey`, `geminiApiKey`)

#### `ask()` Method

The main method that sends a prompt to the Gemini API:

```dart
Future<String> ask(
  String prompt, {
  List<ChatEntry> history,             // Previous conversation history
  String? studyMaterialContext,         // PDF/material text for context
  bool answerOnlyFromMaterials,         // Strict vs normal mode
  bool includeModelHistory,             // Include AI replies in history
})
```

**Two modes of operation:**

| Mode | `answerOnlyFromMaterials` | Behavior |
|---|---|---|
| **Strict** | `true` | Only answers from provided study material context. Temperature: 0.2, Max tokens: 1400 |
| **Normal** | `false` | General tutor mode, answers any question. Temperature: 0.35, Max tokens: 900 |

**System instructions:**
- Strict mode: "Answer strictly from provided study material context only. If the answer is not present, say so."
- Normal mode: "You are a helpful tutor for students. For real-time questions, say you do not have live data."

**Error handling:** Translates API status codes into user-friendly messages (429 → quota, 401/403 → invalid key, 500+ → service unavailable).

**Response normalization:** Strips markdown formatting (`**`, backticks) and collapses extra newlines.

---

### 10.4 `CloudinaryService`

**File:** `lib/services/cloudinary_service.dart` (85 lines)

Handles PDF file uploads to Cloudinary's free plan via unsigned upload preset.

| Method | Description |
|---|---|
| `isConfigured` | Checks if Cloudinary credentials are set (not placeholder values) |
| `pickAndUploadPdf()` | Opens file picker (PDF only), uploads selected file, returns secure URL |
| `uploadPdf(fileName, filePath?, bytes?)` | Low-level upload — supports both byte data and file path |

**Upload endpoint:** `https://api.cloudinary.com/v1_1/{cloudName}/raw/upload`

Returns the `secure_url` from Cloudinary's response, which is then stored in the `StudyMaterial.pdfUrl` field.

---

### 10.5 `WellbeingService`

**File:** `lib/services/wellbeing_service.dart` (25 lines)

A simple mood-to-suggestion mapping service.

| Mood | Suggestion |
|---|---|
| Happy | "Great energy today. Use it to finish one tough chapter." |
| Calm | "Keep your rhythm. Do one revision session and one quiz." |
| Neutral | "Try a 25-minute focus block with no phone distractions." |
| Stressed | "Pause for 5 minutes of deep breathing, then start small." |
| Tired | "Do light review now and attempt harder topics after rest." |
| Anxious | "Write your top 3 worries and convert each into one action step." |
| Default | "Stay consistent with small daily progress." |

---

## 11. UI Layer — Pages & Screens

### 11.1 Authentication

#### `AuthPage` (`lib/pages/auth/auth_page.dart`, 300 lines)

A single page that toggles between **Login** and **Sign Up** modes.

**Fields:**
- `_isLogin` — Toggle between login/signup
- `_nameCtrl`, `_emailCtrl`, `_passwordCtrl` — Text controllers
- `_loading` — Loading state
- `_errorMessage` — Error display

**Behavior:**
- Login: calls `AuthService.signIn(email, password)`
- Sign Up: calls `AuthService.signUp(name, email, password)`
- Errors are caught and displayed inline
- Toggle link at the bottom switches between modes

---

### 11.2 Shared

#### `LoadingPage` (`lib/pages/shared/loading_page.dart`)

A simple animated loading screen with a centered `CircularProgressIndicator` and a customizable label text. Used during auth state transitions.

---

### 11.3 Admin Module

The admin module uses `AdminShellPage` as a container with a bottom navigation bar containing 5 tabs.

#### `AdminShellPage` (`lib/pages/admin/admin_shell_page.dart`, 109 lines)

- 5 tabs: **Classes**, **Materials**, **Quiz**, **Students**, **Usage**
- Uses `IndexedStack` to preserve tab state
- Logout button in the app bar

---

#### `AdminClassesPage` (admin_classes_page.dart, ~16,000 bytes)

**Manages classes and subjects:**
- **Create/edit/delete classes** (e.g., "Std 6", "Std 7", "Std 8")
- **Create/delete subjects** (e.g., "Mathematics", "Science")
- **Assign subjects to classes** via multi-select
- Uses `StreamBuilder` on `FirestoreService.streamClasses()` and `streamSubjects()`

---

#### `AdminMaterialsPage` (admin_materials_page.dart, ~17,000 bytes)

**Manages study materials:**
- Filter by class and subject via dropdowns
- **Add new material** with: title, chapter, content (text), optional PDF URL
- **Upload PDF** to Cloudinary directly from the admin panel
- **Edit/delete** existing materials
- Real-time updates via `StreamBuilder`

---

#### `AdminQuizPage` (admin_quiz_page.dart, ~18,000 bytes)

**Manages quiz question bank:**
- Filter by class, subject, and chapter
- **Add new MCQ questions** with 4 options and correct answer selection
- **Delete** existing questions
- View questions grouped by chapter
- Real-time updates via `StreamBuilder`

---

#### `AdminStudentsPage` (admin_students_page.dart, ~11,000 bytes)

**Manages students:**
- List all registered students
- View student profile details
- **Assign class** to students via dropdown
- View student's quiz performance summary
- Uses `StreamBuilder` on `FirestoreService.streamStudents()`

---

#### `AdminUsagePage` (admin_usage_page.dart, ~7,500 bytes)

**System usage dashboard:**
- Displays counts: total students, quiz attempts, chats, materials
- Uses `FirestoreService.getUsageCounts()`
- Stat cards with icons and formatted numbers

---

#### `AdminApiSettingsPage` (admin_api_settings_page.dart, 218 lines)

**Gemini API key management:**
- View current API key (masked by default, toggleable)
- Edit and save new API key to Firestore `app_config/gemini`
- Reload key from Firestore
- Force-refresh the `ChatApiService` config cache
- Status messages for success/error

---

### 11.4 Student Module

The student module uses `StudentShellPage` as a container with a bottom navigation bar containing 5 tabs.

#### `StudentShellPage` (`lib/pages/student/student_shell_page.dart`, 109 lines)

- 5 tabs: **Home**, **Materials**, **Quiz**, **Mood**, **Chat**
- Uses `IndexedStack` to preserve tab state
- Logout button in the app bar

---

#### `StudentDashboardPage` (student_dashboard_page.dart, 377 lines)

**Home dashboard with:**
- Welcome message with student name
- Assigned class display
- Subject list for the assigned class
- Quiz performance statistics:
  - Total quizzes taken
  - Average score
  - Best score
- Recent quiz attempt history
- Uses multiple `StreamBuilder`s for real-time data

---

#### `StudentMaterialsPage` (student_materials_page.dart, 242 lines)

**Subject browser:**
- Shows subjects assigned to the student's class
- Streams class and subject data
- Taps navigate to `StudentSubjectDetailsPage`

---

#### `StudentSubjectDetailsPage` (student_subject_details_page.dart, ~5,400 bytes)

**Material viewer for a specific subject:**
- Lists all materials grouped by chapter
- Displays text content inline
- "View PDF" button for materials with `pdfUrl`
- Opens `StudentPdfViewerPage` for PDF viewing

---

#### `StudentPdfViewerPage` (student_pdf_viewer_page.dart, ~1,900 bytes)

**In-app PDF viewer:**
- Uses Syncfusion PDF viewer widget
- Receives PDF URL as parameter
- Full-screen PDF reading experience

---

#### `StudentQuizPage` (student_quiz_page.dart, 521 lines)

**Quiz system with three states:**

1. **Quiz Setup** — Select subject and chapter, then start quiz
2. **Quiz In-Progress** — Answer MCQ questions one at a time, navigate between questions
3. **Quiz Results** — Score summary with pass/fail indication

**Quiz flow:**
- Loads subjects and classes from Firestore
- Fetches random questions via `getRandomQuestions()`
- Tracks selected answers per question
- On submit: calculates score, saves `QuizAttempt` to Firestore
- Shows score percentage with color-coded badge (green ≥ 50%, red < 50%)

---

#### `StudentWellbeingPage` (student_wellbeing_page.dart, 394 lines)

**Two sections:**

1. **Mood Tracker:**
   - Select daily mood from predefined categories
   - Get personalized wellbeing suggestion
   - Save mood entry (one per day by date label)
   - View recent mood history

2. **Reflection Journal:**
   - Free-text daily journal entry
   - Save reflection (one per day by date label)
   - View past reflections in reverse chronological order

---

#### `StudentChatPage` (student_chat_page.dart, 947 lines)

**The most complex screen — AI-powered chatbot.**

**Features:**
- Real-time chat with Gemini AI
- Two chat modes:
  - **Normal mode** — General tutor, answers any student question
  - **Strict (Material-based) mode** — Only answers from selected study material context
- **Material selector** — Pick specific study materials to use as AI context
- **PDF text extraction** — Downloads and extracts text from PDFs using Syncfusion, used as AI context
- **Conversation history** — Sends recent chat history to the AI for context-aware responses
- **Clear chat** — Batch delete all chat history
- Chat bubble UI with user/AI differentiation
- Auto-scroll to bottom on new messages
- Loading indicator during AI response
- Error handling with user-friendly messages

**Context preparation:**
- Combines selected material text + extracted PDF text
- Truncates to stay within token limits
- Extracts module headings for structured context

---

## 12. Theming & Design System

**File:** `lib/config/app_theme.dart` (373 lines)

### Color Palette

| Color | Hex | Usage |
|---|---|---|
| `primaryBlue` | `#1565C0` | Primary brand color, buttons, active states |
| `accentBlue` | `#42A5F5` | Secondary accents, gradient endpoints |
| `darkText` | `#1A1A2E` | Primary text color |
| `secondaryText` | `#5C6B8A` | Subtitles, labels, hints |
| `surfaceWhite` | `#FFFFFF` | Card and surface backgrounds |
| `backgroundTint` | `#F5F8FF` | Subtle tinted backgrounds |
| `borderLight` | `#E0E8F5` | Card and input borders |
| `shadowBlue` | `#141565C0` | Card shadow (0.08 opacity blue) |

### Gradients

| Gradient | Colors | Usage |
|---|---|---|
| `pageBackgroundGradient` | White → `#F0F4FF` | Page background |
| `heroGradient` | `#1565C0` → `#42A5F5` | Hero sections, banners |

### Reusable Widget Builders (Static Methods)

| Method | Purpose |
|---|---|
| `cardDecoration(radius)` | White card with shadow |
| `accentLeftBorder(radius)` | Card with blue left accent border |
| `tintedContainer(radius)` | Light blue tinted background |
| `sectionHeader(context, title, icon?)` | Section title with optional icon |
| `statCard(label, value, icon, ...)` | Statistics display card |
| `scoreBadge(percent)` | Color-coded score badge (green/red) |
| `chapterChip(text)` | Blue chip for chapter labels |

### Material 3 Theme

Built with `ThemeData` using `Material 3` (`useMaterial3: true`):
- **Font:** Google Fonts Inter
- **Color Scheme:** Seeded from `primaryBlue`
- **Components themed:** AppBar, Card, Input, Buttons (Filled/Outlined/Text), NavigationBar, Chip, SnackBar, Dialog, Switch, Divider, ProgressIndicator, DropdownMenu

---

## 13. User Flows

### 13.1 Student Registration & Login

```
┌──────────────┐     ┌──────────────┐     ┌──────────┐
│  Auth Page   │────→│ Firebase Auth │────→│ Root Gate│
│ (Email/Pass) │     │   Sign Up    │     │ (Stream) │
└──────────────┘     └──────┬───────┘     └────┬─────┘
                            │                  │
                   Creates user doc      Checks role
                   in Firestore          in /users/{uid}
                            │                  │
                            ▼                  ▼
                     ┌──────────────┐   ┌──────────────┐
                     │ users/{uid}  │   │ Student Shell │
                     │ role:student │   │  Page (Home)  │
                     └──────────────┘   └──────────────┘
```

### 13.2 Student Takes a Quiz

```
┌────────────┐    ┌───────────┐    ┌──────────────┐    ┌────────────┐
│ Select      │───→│  Fetch    │───→│ Answer MCQs  │───→│  Submit    │
│ Subject +   │    │  Random   │    │ (one at a    │    │  & Save    │
│ Chapter     │    │ Questions │    │  time)        │    │  Attempt   │
└─────────────┘    └───────────┘    └──────────────┘    └─────┬──────┘
                                                              │
                                                              ▼
                                                       ┌─────────────┐
                                                       │ Score Result │
                                                       │ (% + badge) │
                                                       └─────────────┘
```

### 13.3 Student Uses AI Chat

```
┌──────────┐    ┌─────────────┐    ┌──────────────┐    ┌──────────┐
│ Type      │───→│ Select Mode │───→│ Build Context│───→│ Gemini   │
│ Message   │    │ (Normal or  │    │ (Materials + │    │ API Call │
│           │    │  Strict)    │    │  PDF text)   │    │          │
└───────────┘    └─────────────┘    └──────────────┘    └────┬─────┘
                                                             │
                ┌────────────────────────────────────────────┘
                ▼
         ┌──────────────┐    ┌────────────────┐
         │ Display Reply │───→│ Save to Chats │
         │ (AI Bubble)   │    │ Collection    │
         └───────────────┘    └────────────────┘
```

### 13.4 Admin Manages Content

```
                    ┌──────────────┐
                    │ Admin Shell  │
                    │ (5 tabs)     │
                    └──────┬───────┘
         ┌─────────┬──────┴──────┬──────────┬──────────┐
         ▼         ▼             ▼          ▼          ▼
    ┌─────────┐┌──────────┐┌─────────┐┌──────────┐┌───────┐
    │ Classes ││Materials ││  Quiz   ││ Students ││ Usage │
    │ CRUD    ││ CRUD +   ││ Question││  List +  ││ Stats │
    │ +Assign ││ PDF Up   ││  Bank   ││ Assign   ││       │
    └─────────┘└──────────┘└─────────┘└──────────┘└───────┘
```

---

## 14. Setup & Deployment Guide

### Prerequisites
- Flutter SDK `^3.9.2`
- Dart SDK (comes with Flutter)
- Firebase account with a project

### Step-by-Step Setup

#### 1. Clone the Repository
```bash
git clone <repository-url>
cd EduAi
```

#### 2. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project (or use existing)
3. Enable **Email/Password Authentication** in Auth → Sign-in method
4. Create a **Cloud Firestore** database (start in test or production mode)

#### 3. Configure Firebase in the App
1. Replace placeholder values in `lib/config/firebase_options_local.dart` with your Firebase project config:
   - `apiKey`
   - `appId`
   - `messagingSenderId`
   - `projectId`
   - `storageBucket`

2. Alternatively, use the Firebase CLI:
   ```bash
   firebase login
   flutterfire configure
   ```

#### 4. Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```

Or copy contents of `firestore.rules` into the Firebase Console → Firestore → Rules tab.

#### 5. Deploy Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```

Or wait for the app to create queries — Firebase will show index creation links in error messages.

#### 6. Set App Configuration

**In `lib/config/app_config.dart`:**
- Set `cloudinaryCloudName` and `cloudinaryUnsignedPreset` (optional, for PDF uploads)
- Set `bootstrapAdminEmails` to the email(s) that should be admin on first signup

**In Firebase Console — Firestore → `app_config/gemini`:**
Create a document with:
```json
{
  "apiKey": "YOUR_GEMINI_API_KEY",
  "model": "gemini-2.5-flash-lite"
}
```

Or set it later via the Admin panel → API Settings page.

#### 7. Install Dependencies & Run
```bash
flutter pub get
flutter run
```

#### 8. Create Admin Account
Sign up with an email listed in `bootstrapAdminEmails`. The account will automatically be assigned the `admin` role.

---

## 15. Important Notes & Limitations

### Architecture Notes

| Item | Detail |
|---|---|
| **Demo architecture** | This is intentionally designed as a college/demo project, not production-grade |
| **No Firebase Storage** | PDFs are hosted externally (Cloudinary or manual URL), not in Firebase Storage |
| **No state management library** | Uses Flutter's built-in `StreamBuilder`/`FutureBuilder` instead of Provider/Bloc/Riverpod |
| **Singleton services** | All services use the singleton pattern — simple but not unit-test friendly |

### Security Considerations

| Issue | Detail |
|---|---|
| **API key in Firestore** | The Gemini API key is stored in Firestore `app_config/gemini`. While more secure than hardcoding, it is readable by any signed-in user (per security rules). For production, use Cloud Functions as a proxy. |
| **Direct API calls** | The Gemini API is called directly from the client app. In production, this should go through a server/Cloud Function to protect the API key. |
| **Cloudinary unsigned preset** | The Cloudinary upload uses an unsigned preset. This is fine for demo purposes but could allow unauthorized uploads in production. |

### Known Limitations

| Limitation | Detail |
|---|---|
| No push notifications | Students are not notified of new materials/quizzes |
| No offline support | App requires internet connectivity for all features |
| No image/media in materials | Study materials only support text + PDF URL |
| Single quiz attempt tracking | No detailed per-question answer tracking (only totals) |
| No admin creation beyond bootstrap | New admins can only be created by adding emails to `bootstrapAdminEmails` before signup |
| Mood/reflection immutability | Once a mood or reflection is saved, it cannot be edited or deleted |
| Chat history limit | AI context uses last 8 messages; full chat stream limited to 50 entries |

---

## File Reference

| File | Lines | Size | Description |
|---|---|---|---|
| `main.dart` | 28 | 614 B | Entry point |
| `app.dart` | 79 | 2.5 KB | Root widget + auth gate |
| `config/app_config.dart` | 24 | 696 B | App constants |
| `config/app_theme.dart` | 373 | 13.4 KB | Theme + design widgets |
| `models/app_user.dart` | 81 | 1.9 KB | User model |
| `models/chat_entry.dart` | 49 | 1.1 KB | Chat model |
| `models/mood_entry.dart` | 53 | 1.3 KB | Mood model |
| `models/quiz_attempt.dart` | 73 | 2.1 KB | Quiz attempt model |
| `models/quiz_question.dart` | 67 | 1.8 KB | Quiz question model |
| `models/reflection_entry.dart` | 49 | 1.1 KB | Reflection model |
| `models/school_class.dart` | 47 | 1.1 KB | Class model |
| `models/study_material.dart` | 69 | 1.8 KB | Material model |
| `models/subject_model.dart` | 37 | 833 B | Subject model |
| `services/auth_service.dart` | 94 | 2.7 KB | Auth service |
| `services/firestore_service.dart` | 524 | 15.6 KB | Firestore CRUD |
| `services/chat_api_service.dart` | 291 | 9.5 KB | Gemini API |
| `services/cloudinary_service.dart` | 85 | 2.5 KB | PDF uploads |
| `services/wellbeing_service.dart` | 25 | 861 B | Mood suggestions |
| `pages/auth/auth_page.dart` | 300 | 12.9 KB | Login/signup |
| `pages/shared/loading_page.dart` | ~80 | 2.8 KB | Loading screen |
| `pages/admin/admin_shell_page.dart` | 109 | 3.3 KB | Admin nav shell |
| `pages/admin/admin_classes_page.dart` | ~400 | 16.0 KB | Class management |
| `pages/admin/admin_materials_page.dart` | ~420 | 16.9 KB | Material management |
| `pages/admin/admin_quiz_page.dart` | ~450 | 18.2 KB | Quiz management |
| `pages/admin/admin_students_page.dart` | ~280 | 11.4 KB | Student management |
| `pages/admin/admin_usage_page.dart` | ~190 | 7.5 KB | Usage stats |
| `pages/admin/admin_api_settings_page.dart` | 218 | 7.7 KB | API key settings |
| `pages/student/student_shell_page.dart` | 109 | 3.3 KB | Student nav shell |
| `pages/student/student_dashboard_page.dart` | 377 | 18.5 KB | Dashboard |
| `pages/student/student_materials_page.dart` | 242 | 11.0 KB | Materials browser |
| `pages/student/student_subject_details_page.dart` | ~140 | 5.4 KB | Subject detail |
| `pages/student/student_pdf_viewer_page.dart` | ~50 | 1.9 KB | PDF viewer |
| `pages/student/student_quiz_page.dart` | 521 | 19.8 KB | Quiz system |
| `pages/student/student_wellbeing_page.dart` | 394 | 13.6 KB | Wellbeing tracker |
| `pages/student/student_chat_page.dart` | 947 | 33.7 KB | AI chatbot |

**Total:** ~37 source files, ~6,200+ lines of Dart code

---

*Documentation generated on 2026-02-14.*
