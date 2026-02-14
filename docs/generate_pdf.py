"""
EduAI Project Documentation — PDF Generator
Uses fpdf2 to produce a properly structured, professional PDF.
Run:  python docs/generate_pdf.py
"""

from fpdf import FPDF
import os, textwrap, re

# ── Paths ─────────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_PDF = os.path.join(SCRIPT_DIR, "EduAI_Project_Documentation.pdf")

# ── Colour palette ────────────────────────────────────────────────────────
PRIMARY   = (21, 101, 192)   # #1565C0
ACCENT    = (66, 165, 245)   # #42A5F5
DARK      = (26, 26, 46)     # #1A1A2E
SECONDARY = (92, 107, 138)   # #5C6B8A
WHITE     = (255, 255, 255)
LIGHT_BG  = (245, 248, 255)  # #F5F8FF
BORDER    = (224, 232, 245)  # #E0E8F5
TABLE_HEAD = (220, 232, 255) # #DCE8FF
CODE_BG   = (245, 247, 250)
GREEN     = (46, 125, 50)
RED       = (211, 47, 47)


class DocPDF(FPDF):
    """Custom PDF class with header/footer and convenience methods."""

    # Map of common Unicode chars to Latin-1 safe replacements
    _UNICODE_MAP = str.maketrans({
        '\u2014': '-',   # em-dash
        '\u2013': '-',   # en-dash
        '\u2018': "'",   # left single quote
        '\u2019': "'",   # right single quote
        '\u201c': '"',   # left double quote
        '\u201d': '"',   # right double quote
        '\u2026': '...', # ellipsis
        '\u2022': '-',   # bullet
        '\u2192': '->',  # right arrow
        '\u2190': '<-',  # left arrow
        '\u2265': '>=',  # >=
        '\u2264': '<=',  # <=
        '\u2260': '!=',  # !=
        '\u00a0': ' ',   # non-breaking space
    })

    def __init__(self):
        super().__init__(orientation="P", unit="mm", format="A4")
        self.set_auto_page_break(auto=True, margin=20)
        self._toc_entries: list[tuple[int, str, int]] = []  # (level, title, page)

    @staticmethod
    def _safe(text: str) -> str:
        """Replace non-Latin-1 characters so Helvetica core font works."""
        text = text.translate(DocPDF._UNICODE_MAP)
        # Drop anything else that can't encode to latin-1
        return text.encode('latin-1', errors='replace').decode('latin-1')

    # Auto-sanitize all text output — override normalize_text instead
    def normalize_text(self, text):
        text = self._safe(str(text))
        return super().normalize_text(text)

    # ── Header / Footer ──────────────────────────────────────────────────
    def header(self):
        if self.page_no() == 1:
            return  # cover page - no header
        self.set_font("Helvetica", "B", 9)
        self.set_text_color(*SECONDARY)
        self.cell(0, 6, "EduAI - Project Documentation", align="L")
        self.set_draw_color(*BORDER)
        self.line(10, 14, 200, 14)
        self.ln(8)

    def footer(self):
        if self.page_no() == 1:
            return
        self.set_y(-15)
        self.set_font("Helvetica", "", 8)
        self.set_text_color(*SECONDARY)
        self.cell(0, 10, f"Page {self.page_no() - 1}", align="C")

    # ── Cover page ────────────────────────────────────────────────────────
    def cover_page(self):
        self.add_page()
        # Blue hero band
        self.set_fill_color(*PRIMARY)
        self.rect(0, 0, 210, 100, "F")
        self.set_fill_color(*ACCENT)
        self.rect(0, 95, 210, 8, "F")

        self.set_y(25)
        self.set_font("Helvetica", "B", 36)
        self.set_text_color(*WHITE)
        self.cell(0, 18, "EduAI", align="C", new_x="LMARGIN", new_y="NEXT")

        self.set_font("Helvetica", "", 14)
        self.cell(0, 10, "AI-Powered Educational Learning Platform", align="C", new_x="LMARGIN", new_y="NEXT")
        self.ln(6)
        self.set_font("Helvetica", "", 11)
        self.cell(0, 8, "Flutter  |  Firebase  |  Gemini AI", align="C", new_x="LMARGIN", new_y="NEXT")

        self.set_y(120)
        self.set_text_color(*DARK)
        self.set_font("Helvetica", "", 11)
        info_lines = [
            ("Version", "1.0.0"),
            ("Platform", "Android, iOS, Web, Windows, macOS, Linux"),
            ("Backend", "Firebase Auth + Cloud Firestore"),
            ("AI", "Google Gemini API (gemini-2.5-flash-lite)"),
            ("Type", "College / Demo Architecture"),
            ("Date", "February 2026"),
        ]
        for label, value in info_lines:
            self.set_font("Helvetica", "B", 11)
            self.set_text_color(*PRIMARY)
            self.cell(45, 8, f"{label}:", align="R")
            self.set_font("Helvetica", "", 11)
            self.set_text_color(*DARK)
            self.cell(0, 8, f"  {value}", align="L", new_x="LMARGIN", new_y="NEXT")

        self.set_y(195)
        self.set_font("Helvetica", "B", 12)
        self.set_text_color(*PRIMARY)
        self.cell(0, 8, "PROJECT DOCUMENTATION", align="C", new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(*PRIMARY)
        self.line(70, self.get_y(), 140, self.get_y())

    # ── Convenience helpers ───────────────────────────────────────────────
    def _check_space(self, h: float = 20):
        """Add page if remaining space is less than h mm."""
        if self.get_y() + h > self.h - 20:
            self.add_page()

    def section_title(self, level: int, title: str, numbered: str = ""):
        """Print a section heading. level 1 = chapter, 2 = section, 3 = sub."""
        display = f"{numbered}  {title}" if numbered else title
        self._toc_entries.append((level, display, self.page_no()))

        if level == 1:
            self.add_page()
            self.set_fill_color(*PRIMARY)
            self.rect(10, self.get_y() - 2, 190, 12, "F")
            self.set_font("Helvetica", "B", 16)
            self.set_text_color(*WHITE)
            self.cell(0, 10, f"  {display}", new_x="LMARGIN", new_y="NEXT")
            self.ln(6)
        elif level == 2:
            self._check_space(18)
            self.ln(4)
            self.set_draw_color(*PRIMARY)
            self.set_line_width(0.6)
            self.line(10, self.get_y(), 200, self.get_y())
            self.ln(2)
            self.set_font("Helvetica", "B", 13)
            self.set_text_color(*PRIMARY)
            self.cell(0, 8, display, new_x="LMARGIN", new_y="NEXT")
            self.ln(2)
        else:
            self._check_space(14)
            self.ln(3)
            self.set_font("Helvetica", "B", 11)
            self.set_text_color(*ACCENT)
            self.cell(0, 7, display, new_x="LMARGIN", new_y="NEXT")
            self.ln(1)

    def body_text(self, text: str, bold: bool = False):
        self.set_font("Helvetica", "B" if bold else "", 10)
        self.set_text_color(*DARK)
        self._check_space(8)
        self.set_x(10)  # reset to left margin
        self.multi_cell(0, 5.5, text)
        self.ln(1)

    def bullet(self, text: str, indent: int = 0):
        self._check_space(8)
        x = 14 + indent * 6
        self.set_x(x)
        self.set_font("Helvetica", "", 10)
        self.set_text_color(*DARK)
        self.cell(4, 5.5, "-")
        # Wrap long lines
        max_w = 190 - (x - 10) - 4
        self.multi_cell(max_w, 5.5, text)
        self.set_x(10)  # reset to left margin

    def code_block(self, text: str, lang: str = ""):
        self._check_space(16)
        self.ln(2)
        self.set_fill_color(*CODE_BG)
        self.set_draw_color(*BORDER)
        self.set_font("Courier", "", 8.5)
        self.set_text_color(*DARK)
        lines = text.strip().split("\n")
        start_y = self.get_y()
        for line in lines:
            self._check_space(5)
            self.set_x(14)
            self.cell(182, 4.5, line, fill=True, new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

    def table(self, headers: list[str], rows: list[list[str]], col_widths: list[float] | None = None):
        """Draw a table with header row and data rows."""
        self._check_space(20)
        self.ln(2)
        n = len(headers)
        if col_widths is None:
            total = 190
            col_widths = [total / n] * n

        # Header
        self.set_font("Helvetica", "B", 9)
        self.set_fill_color(*TABLE_HEAD)
        self.set_text_color(*PRIMARY)
        self.set_draw_color(*BORDER)
        for i, h in enumerate(headers):
            self.cell(col_widths[i], 7, f" {h}", border=1, fill=True)
        self.ln()

        # Rows
        self.set_font("Helvetica", "", 9)
        self.set_text_color(*DARK)
        fill = False
        for row in rows:
            max_lines = 1
            cell_texts = []
            for i, cell in enumerate(row):
                wrapped = self._wrap_text(cell, col_widths[i] - 2)
                cell_texts.append(wrapped)
                max_lines = max(max_lines, len(wrapped))
            row_h = max_lines * 5

            self._check_space(row_h + 2)
            if fill:
                self.set_fill_color(250, 251, 255)
            else:
                self.set_fill_color(*WHITE)
            y_start = self.get_y()
            for i, texts in enumerate(cell_texts):
                x_start = self.get_x() if i == 0 else sum(col_widths[:i]) + 10
                self.set_xy(x_start, y_start)
                self.cell(col_widths[i], row_h, "", border=1, fill=True)
                for j, t in enumerate(texts):
                    self.set_xy(x_start + 1, y_start + j * 5)
                    self.cell(col_widths[i] - 2, 5, t)
            self.set_y(y_start + row_h)
            fill = not fill
        self.ln(3)

    def _wrap_text(self, text: str, max_w: float) -> list[str]:
        self.set_font("Helvetica", "", 9)
        if self.get_string_width(text) <= max_w:
            return [text]
        words = text.split()
        lines = []
        current = ""
        for w in words:
            test = f"{current} {w}".strip()
            if self.get_string_width(test) <= max_w:
                current = test
            else:
                if current:
                    lines.append(current)
                current = w
        if current:
            lines.append(current)
        return lines if lines else [text[:40] + "..."]

    def key_value(self, key: str, value: str):
        self._check_space(8)
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(*PRIMARY)
        self.cell(50, 6, f"{key}:")
        self.set_font("Helvetica", "", 10)
        self.set_text_color(*DARK)
        self.multi_cell(0, 6, value)

    def note_box(self, text: str, color=PRIMARY):
        self._check_space(16)
        self.ln(2)
        self.set_fill_color(color[0], color[1], color[2])
        self.rect(10, self.get_y(), 3, 12, "F")
        self.set_x(16)
        self.set_font("Helvetica", "I", 9)
        self.set_text_color(*SECONDARY)
        self.multi_cell(178, 5, text)
        self.ln(2)

    # ── Table of Contents ────────────────────────────────────────────────
    def insert_toc_placeholder(self):
        """Remember where to insert TOC later."""
        self._toc_page_start = self.page_no()

    def build_toc(self):
        """Generate TOC page (call after all content is added)."""
        # We'll insert TOC as page 2
        self.add_page()
        self.set_font("Helvetica", "B", 18)
        self.set_text_color(*PRIMARY)
        self.cell(0, 12, "Table of Contents", align="C", new_x="LMARGIN", new_y="NEXT")
        self.ln(8)

        for level, title, page in self._toc_entries:
            if level > 2:
                continue  # skip sub-subsections
            indent = (level - 1) * 8
            self.set_x(14 + indent)
            if level == 1:
                self.set_font("Helvetica", "B", 11)
                self.set_text_color(*PRIMARY)
            else:
                self.set_font("Helvetica", "", 10)
                self.set_text_color(*DARK)
            title_clean = title[:80]
            self.cell(0, 6.5, f"{title_clean}", new_x="LMARGIN", new_y="NEXT")


# ══════════════════════════════════════════════════════════════════════════
#  BUILD THE DOCUMENT
# ══════════════════════════════════════════════════════════════════════════
def build_document():
    pdf = DocPDF()

    # ── Cover ─────────────────────────────────────────────────────────────
    pdf.cover_page()

    # ══════════════════════════════════════════════════════════════════════
    # 1. PROJECT OVERVIEW
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Project Overview", "1.")

    pdf.body_text(
        "EduAI is an AI-powered educational mobile application built with Flutter and Firebase. "
        "It serves two distinct user roles: Students and Admins."
    )
    pdf.body_text(
        "Students can access study materials, take quizzes, track their wellbeing, and interact "
        "with an AI chatbot powered by Google's Gemini API for academic help."
    )
    pdf.body_text(
        "Admins can manage classes, subjects, study materials, quiz questions, view student "
        "performance, and configure system settings including the Gemini API key."
    )

    pdf.section_title(2, "Feature Matrix")
    pdf.table(
        ["Feature", "Student", "Admin"],
        [
            ["Email registration & login", "Yes", "Yes"],
            ["Subject-wise study materials (text + PDF)", "Read", "Full CRUD"],
            ["Chapter-wise random quizzes (MCQ)", "Attempt", "Full CRUD"],
            ["Quiz score history & progress", "Own", "View all"],
            ["Daily mood tracking & wellbeing tips", "Yes", "--"],
            ["Daily reflection journal", "Yes", "--"],
            ["AI Chatbot (Gemini API)", "Yes", "--"],
            ["Class & subject management", "--", "Yes"],
            ["Student management & class assignment", "--", "Yes"],
            ["System usage statistics dashboard", "--", "Yes"],
            ["PDF upload via Cloudinary", "--", "Yes"],
            ["Gemini API key management", "--", "Yes"],
        ],
        [90, 50, 50],
    )

    # ══════════════════════════════════════════════════════════════════════
    # 2. TECH STACK & DEPENDENCIES
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Tech Stack & Dependencies", "2.")

    pdf.section_title(2, "Core Framework")
    pdf.bullet("Flutter (SDK ^3.9.2) — Cross-platform UI framework")
    pdf.bullet("Dart — Programming language")

    pdf.section_title(2, "Firebase Services")
    pdf.table(
        ["Package", "Version", "Purpose"],
        [
            ["firebase_core", "^3.15.2", "Firebase initialization"],
            ["firebase_auth", "^5.7.0", "Email/password authentication"],
            ["cloud_firestore", "^5.6.12", "NoSQL cloud database"],
        ],
        [55, 35, 100],
    )

    pdf.section_title(2, "AI & External APIs")
    pdf.table(
        ["Package", "Version", "Purpose"],
        [
            ["http", "^1.5.0", "HTTP client for Gemini API calls"],
            ["file_picker", "^10.3.2", "File selection for PDF uploads"],
        ],
        [55, 35, 100],
    )

    pdf.section_title(2, "UI & PDF Libraries")
    pdf.table(
        ["Package", "Version", "Purpose"],
        [
            ["google_fonts", "^6.2.1", "Inter font family"],
            ["syncfusion_flutter_pdfviewer", "^29.2.11", "In-app PDF viewing"],
            ["syncfusion_flutter_pdf", "^29.2.11", "PDF text extraction for AI context"],
            ["intl", "^0.20.2", "Date/time formatting"],
            ["url_launcher", "^6.3.2", "External URL opening"],
            ["path_provider", "^2.1.5", "File system path access"],
        ],
        [65, 35, 90],
    )

    # ══════════════════════════════════════════════════════════════════════
    # 3. PROJECT STRUCTURE
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Project Structure", "3.")
    pdf.body_text("The project follows a clean, layered architecture with clear separation of concerns:")

    pdf.code_block(
        "EduAi/\n"
        "  lib/\n"
        "    main.dart                    # Entry point\n"
        "    app.dart                     # MaterialApp + auth gate\n"
        "    firebase_options.dart        # Firebase config\n"
        "    config/\n"
        "      app_config.dart            # App constants\n"
        "      app_theme.dart             # Theme + design widgets\n"
        "      firebase_options_local.dart # Local Firebase config\n"
        "    models/                      # 9 data model classes\n"
        "      app_user.dart              # User profile\n"
        "      chat_entry.dart            # Chat message pair\n"
        "      mood_entry.dart            # Mood record\n"
        "      quiz_attempt.dart          # Quiz result\n"
        "      quiz_question.dart         # MCQ question\n"
        "      reflection_entry.dart      # Journal entry\n"
        "      school_class.dart          # Class (Std 6, 7, 8)\n"
        "      study_material.dart        # Material (text + PDF)\n"
        "      subject_model.dart         # Subject\n"
        "    services/                    # 5 singleton services\n"
        "      auth_service.dart          # Firebase Auth\n"
        "      firestore_service.dart     # Firestore CRUD\n"
        "      chat_api_service.dart      # Gemini API\n"
        "      cloudinary_service.dart    # PDF upload\n"
        "      wellbeing_service.dart     # Mood suggestions\n"
        "    pages/\n"
        "      auth/auth_page.dart        # Login / Signup\n"
        "      shared/loading_page.dart   # Loading screen\n"
        "      admin/                     # 7 admin screens\n"
        "      student/                   # 8 student screens"
    )

    # ══════════════════════════════════════════════════════════════════════
    # 4. APPLICATION ARCHITECTURE
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Application Architecture", "4.")

    pdf.section_title(2, "Architecture Pattern")
    pdf.body_text(
        "The app follows a Service-Oriented Architecture with three layers: "
        "UI (Pages), Services (Singletons), and Data (Models), backed by external services."
    )

    pdf.table(
        ["Layer", "Components", "Responsibility"],
        [
            ["UI Layer", "17 page widgets", "User interface, navigation, state display"],
            ["Service Layer", "5 singleton services", "Business logic, API calls, data access"],
            ["Data Layer", "9 model classes", "Data structures, serialization"],
            ["External", "Firebase, Gemini, Cloudinary", "Auth, database, AI, file hosting"],
        ],
        [40, 55, 95],
    )

    pdf.section_title(2, "Key Design Decisions")
    pdf.table(
        ["Decision", "Implementation"],
        [
            ["State Management", "StreamBuilder / FutureBuilder (no external library)"],
            ["Navigation", "Bottom NavigationBar with IndexedStack for tab persistence"],
            ["Dependency Injection", "Singleton pattern (ServiceName.instance)"],
            ["Auth Flow", "StreamBuilder on authStateChanges() -> role-based routing"],
            ["File Storage", "Cloudinary (not Firebase Storage) for PDFs"],
        ],
        [55, 135],
    )

    pdf.section_title(2, "App Entry & Root Routing")
    pdf.body_text(
        "main.dart initializes Firebase and runs EduAiApp. "
        "app.dart contains _RootGate with a 3-layer authentication gate:"
    )
    pdf.bullet("Layer 1: StreamBuilder<User?> — Firebase Auth state. No user -> AuthPage.")
    pdf.bullet("Layer 2: FutureBuilder — ensureProfile() creates Firestore doc if missing.")
    pdf.bullet("Layer 3: StreamBuilder<AppUser?> — Streams profile. Admin -> AdminShell, Student -> StudentShell.")

    # ══════════════════════════════════════════════════════════════════════
    # 5. CONFIGURATION
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Configuration", "5.")

    pdf.section_title(2, "App Configuration (app_config.dart)")
    pdf.table(
        ["Config Key", "Value / Default", "Purpose"],
        [
            ["cloudinaryCloudName", "dzzjiiwuy", "Cloudinary account for PDF uploads"],
            ["cloudinaryUnsignedPreset", "eduai_pdf_unsigned", "Unsigned upload preset"],
            ["bootstrapAdminEmails", "['admin@eduai.com']", "Auto-admin emails at signup"],
            ["moodCategories", "Happy, Calm, Neutral, ...", "Predefined mood options (6 total)"],
        ],
        [55, 55, 80],
    )

    pdf.section_title(2, "Gemini API Configuration")
    pdf.body_text(
        "The Gemini API key is stored in Firestore at app_config/gemini (not hardcoded). "
        "Fields: apiKey (required), model (optional, default: gemini-2.5-flash-lite). "
        "Managed via Admin panel -> API Settings page."
    )

    # ══════════════════════════════════════════════════════════════════════
    # 6. DATA MODELS
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Data Models", "6.")

    pdf.body_text(
        "All 9 models in lib/models/ follow a consistent pattern: immutable final fields, "
        "toMap() for Firestore serialization, static fromDoc() factory from DocumentSnapshot, "
        "and Timestamp <-> DateTime conversion via _readDate() helper."
    )

    # AppUser
    pdf.section_title(2, "AppUser")
    pdf.body_text("File: lib/models/app_user.dart  |  Collection: users")
    pdf.table(
        ["Field", "Type", "Description"],
        [
            ["id", "String", "Firebase Auth UID (document ID)"],
            ["name", "String", "Display name"],
            ["email", "String", "Email address"],
            ["role", "UserRole", "Enum: student or admin"],
            ["classId", "String?", "Assigned class ID (students only)"],
            ["createdAt", "DateTime?", "Account creation timestamp"],
        ],
        [30, 35, 125],
    )
    pdf.body_text("Role is determined at signup by checking if email is in bootstrapAdminEmails. Includes copyWith() method for immutable updates.")

    # SchoolClass
    pdf.section_title(2, "SchoolClass")
    pdf.body_text("File: lib/models/school_class.dart  |  Collection: classes")
    pdf.table(
        ["Field", "Type", "Description"],
        [
            ["id", "String", "Document ID"],
            ["name", "String", "Class name (e.g., Std 6, Std 7)"],
            ["subjectIds", "List<String>", "IDs of assigned subjects"],
            ["createdAt", "DateTime?", "Creation timestamp"],
        ],
        [30, 40, 120],
    )

    # SubjectModel
    pdf.section_title(2, "SubjectModel")
    pdf.body_text("File: lib/models/subject_model.dart  |  Collection: subjects")
    pdf.table(
        ["Field", "Type", "Description"],
        [
            ["id", "String", "Document ID"],
            ["name", "String", "Subject name (e.g., Mathematics)"],
            ["createdAt", "DateTime?", "Creation timestamp"],
        ],
        [30, 40, 120],
    )

    # StudyMaterial
    pdf.section_title(2, "StudyMaterial")
    pdf.body_text("File: lib/models/study_material.dart  |  Collection: materials")
    pdf.table(
        ["Field", "Type", "Description"],
        [
            ["id", "String", "Document ID"],
            ["classId", "String", "Linked class ID"],
            ["subjectId", "String", "Linked subject ID"],
            ["chapter", "String", "Chapter name/number"],
            ["title", "String", "Material title"],
            ["content", "String", "Text content body"],
            ["pdfUrl", "String?", "Optional PDF URL (Cloudinary/external)"],
            ["createdBy", "String?", "Admin UID who created it"],
            ["createdAt", "DateTime?", "Creation timestamp"],
            ["updatedAt", "DateTime?", "Last update timestamp"],
        ],
        [30, 35, 125],
    )

    # QuizQuestion
    pdf.section_title(2, "QuizQuestion")
    pdf.body_text("File: lib/models/quiz_question.dart  |  Collection: quiz_questions")
    pdf.table(
        ["Field", "Type", "Description"],
        [
            ["id", "String", "Document ID"],
            ["classId", "String", "Linked class ID"],
            ["subjectId", "String", "Linked subject ID"],
            ["chapter", "String", "Chapter name"],
            ["question", "String", "Question text"],
            ["options", "List<String>", "4 answer options"],
            ["correctIndex", "int", "Index of correct answer (0-3)"],
            ["createdBy", "String?", "Admin UID who created it"],
            ["createdAt", "DateTime?", "Creation timestamp"],
        ],
        [30, 40, 120],
    )

    # QuizAttempt
    pdf.section_title(2, "QuizAttempt")
    pdf.body_text("File: lib/models/quiz_attempt.dart  |  Collection: quiz_attempts")
    pdf.table(
        ["Field", "Type", "Description"],
        [
            ["id", "String", "Document ID"],
            ["studentId", "String", "Student's UID"],
            ["classId", "String", "Class ID"],
            ["subjectId", "String", "Subject ID"],
            ["chapter", "String", "Chapter name"],
            ["totalQuestions", "int", "Total questions in the quiz"],
            ["correctAnswers", "int", "Number of correct answers"],
            ["scorePercent", "double", "Score as percentage"],
            ["questionIds", "List<String>", "IDs of questions in this attempt"],
            ["attemptedAt", "DateTime?", "Attempt timestamp"],
        ],
        [35, 40, 115],
    )

    # MoodEntry
    pdf.section_title(2, "MoodEntry")
    pdf.body_text("File: lib/models/mood_entry.dart  |  Collection: mood_entries")
    pdf.table(
        ["Field", "Type", "Description"],
        [
            ["id", "String", "Document ID"],
            ["studentId", "String", "Student's UID"],
            ["dateLabel", "String", "Formatted date string"],
            ["mood", "String", "Selected mood category"],
            ["suggestion", "String", "Wellbeing suggestion for this mood"],
            ["createdAt", "DateTime?", "Entry timestamp"],
        ],
        [30, 35, 125],
    )

    # ReflectionEntry
    pdf.section_title(2, "ReflectionEntry")
    pdf.body_text("File: lib/models/reflection_entry.dart  |  Collection: reflections")
    pdf.table(
        ["Field", "Type", "Description"],
        [
            ["id", "String", "Document ID"],
            ["studentId", "String", "Student's UID"],
            ["dateLabel", "String", "Formatted date string"],
            ["text", "String", "Reflection journal text"],
            ["createdAt", "DateTime?", "Entry timestamp"],
        ],
        [30, 35, 125],
    )

    # ChatEntry
    pdf.section_title(2, "ChatEntry")
    pdf.body_text("File: lib/models/chat_entry.dart  |  Collection: chats")
    pdf.table(
        ["Field", "Type", "Description"],
        [
            ["id", "String", "Document ID"],
            ["studentId", "String", "Student's UID"],
            ["userMessage", "String", "User's message"],
            ["aiReply", "String", "AI's response"],
            ["createdAt", "DateTime?", "Message timestamp"],
        ],
        [30, 35, 125],
    )

    # ══════════════════════════════════════════════════════════════════════
    # 7. FIRESTORE DATABASE DESIGN
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Firestore Database Design", "7.")

    pdf.body_text(
        "The app uses 10 Firestore collections. The entity relationships form a hierarchical "
        "structure: Classes contain subjects, materials and quiz questions are linked to both "
        "a class and subject. Student activity records (quiz attempts, mood entries, reflections, "
        "chats) reference the student via studentId."
    )

    pdf.section_title(2, "Collections Summary")
    pdf.table(
        ["Collection", "Doc ID", "Key Fields", "Owner"],
        [
            ["users", "Auth UID", "name, email, role, classId", "Self / Admin"],
            ["classes", "Auto", "name, subjectIds[]", "Admin"],
            ["subjects", "Auto", "name", "Admin"],
            ["materials", "Auto", "classId, subjectId, chapter, title", "Admin"],
            ["quiz_questions", "Auto", "classId, subjectId, chapter, question", "Admin"],
            ["quiz_attempts", "Auto", "studentId, scorePercent", "Student"],
            ["mood_entries", "Auto", "studentId, mood, suggestion", "Student"],
            ["reflections", "Auto", "studentId, text", "Student"],
            ["chats", "Auto", "studentId, userMessage, aiReply", "Student"],
            ["app_config", "Semantic", "apiKey, model", "Admin"],
        ],
        [35, 25, 85, 45],
    )

    # ══════════════════════════════════════════════════════════════════════
    # 8. FIRESTORE SECURITY RULES
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Firestore Security Rules", "8.")

    pdf.body_text("File: firestore.rules — Role-based access control using three helper functions:")
    pdf.bullet("signedIn() — Checks request.auth != null")
    pdf.bullet("isSelf(uid) — Checks if request user matches document owner UID")
    pdf.bullet("isAdmin() — Checks if user's Firestore role field is 'admin'")

    pdf.section_title(2, "Access Control Matrix")
    pdf.table(
        ["Collection", "Read", "Create", "Update", "Delete"],
        [
            ["users", "Self/Admin", "Self", "Admin", "Admin"],
            ["classes", "Signed-in", "Admin", "Admin", "Admin"],
            ["subjects", "Signed-in", "Admin", "Admin", "Admin"],
            ["app_config", "Signed-in", "Admin", "Admin", "Admin"],
            ["materials", "Signed-in", "Admin", "Admin", "Admin"],
            ["quiz_questions", "Signed-in", "Admin", "Admin", "Admin"],
            ["quiz_attempts", "Admin/Owner", "Owner*", "Admin", "Admin"],
            ["mood_entries", "Admin/Owner", "Owner*", "NEVER", "NEVER"],
            ["reflections", "Admin/Owner", "Owner*", "NEVER", "NEVER"],
            ["chats", "Admin/Owner", "Owner*", "NEVER", "Admin/Owner"],
        ],
        [33, 33, 40, 42, 42],
    )
    pdf.note_box("* Owner create rules verify request.resource.data.studentId == request.auth.uid to prevent impersonation.")

    # ══════════════════════════════════════════════════════════════════════
    # 9. FIRESTORE COMPOSITE INDEXES
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Firestore Composite Indexes", "9.")

    pdf.body_text("File: firestore.indexes.json — Six composite indexes required for the app's queries:")
    pdf.table(
        ["Collection", "Fields", "Purpose"],
        [
            ["materials", "classId ASC, subjectId ASC, chapter ASC", "Materials filtered by class+subject"],
            ["quiz_questions", "classId ASC, subjectId ASC, chapter ASC", "Questions filtered by class+subject"],
            ["quiz_attempts", "studentId ASC, attemptedAt DESC", "Student's quiz history by date"],
            ["mood_entries", "studentId ASC, createdAt DESC", "Student's mood history by date"],
            ["reflections", "studentId ASC, createdAt DESC", "Student's reflections by date"],
            ["chats", "studentId ASC, createdAt DESC", "Student's chat history by date"],
        ],
        [35, 80, 75],
    )

    # ══════════════════════════════════════════════════════════════════════
    # 10. SERVICES LAYER
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Services Layer", "10.")

    pdf.body_text(
        "All services use the Singleton pattern: private constructor + static instance field. "
        "This provides global access without dependency injection frameworks."
    )

    # AuthService
    pdf.section_title(2, "AuthService")
    pdf.body_text("File: lib/services/auth_service.dart (94 lines) — Wraps Firebase Authentication.")
    pdf.table(
        ["Method", "Returns", "Description"],
        [
            ["authStateChanges()", "Stream<User?>", "Firebase Auth state stream"],
            ["signIn(email, password)", "Future<void>", "Email/password sign in"],
            ["signUp(name, email, password)", "Future<void>", "Create account + Firestore user doc"],
            ["signOut()", "Future<void>", "Sign out current user"],
            ["profileStream(uid)", "Stream<AppUser?>", "Real-time user profile stream"],
            ["getProfile(uid)", "Future<AppUser?>", "One-shot profile fetch"],
            ["ensureProfile(user)", "Future<void>", "Create profile doc if missing"],
        ],
        [50, 45, 95],
    )
    pdf.body_text("Signup flow: Create Firebase Auth account -> Update display name -> Check bootstrapAdminEmails -> Create users/{uid} document with role.")

    # FirestoreService
    pdf.section_title(2, "FirestoreService")
    pdf.body_text("File: lib/services/firestore_service.dart (524 lines) — Central data access layer with CRUD for all 10 collections.")

    pdf.section_title(3, "Class & Subject Methods")
    pdf.table(
        ["Method", "Description"],
        [
            ["streamClasses()", "Real-time ordered list of all classes"],
            ["saveClass(id?, name, subjectIds)", "Create or update a class"],
            ["updateClassSubjects(classId, subjectIds)", "Update subject assignments"],
            ["deleteClass(classId)", "Delete a class document"],
            ["streamSubjects()", "Real-time ordered list of all subjects"],
            ["saveSubject(id?, name)", "Create or update a subject"],
            ["deleteSubject(subjectId)", "Delete a subject document"],
        ],
        [75, 115],
    )

    pdf.section_title(3, "Material Methods")
    pdf.table(
        ["Method", "Description"],
        [
            ["streamMaterials(classId, subjectId)", "Filtered materials stream"],
            ["streamClassMaterials(classId)", "All materials for a class"],
            ["saveMaterial(...)", "Create or update a material"],
            ["deleteMaterial(materialId)", "Delete a material"],
        ],
        [75, 115],
    )

    pdf.section_title(3, "Quiz Methods")
    pdf.table(
        ["Method", "Description"],
        [
            ["streamQuizQuestions(classId, subjectId, chapter?)", "Filtered question stream"],
            ["saveQuizQuestion(...)", "Create or update a question"],
            ["deleteQuizQuestion(questionId)", "Delete a question"],
            ["getRandomQuestions(classId, subjectId, count, ch?)", "Fetch N random questions"],
            ["saveQuizAttempt(attempt)", "Save quiz result"],
            ["streamStudentAttempts(studentId)", "Student's quiz history"],
            ["streamAllAttempts()", "All quiz attempts (admin)"],
        ],
        [80, 110],
    )

    pdf.section_title(3, "Wellbeing & Chat Methods")
    pdf.table(
        ["Method", "Description"],
        [
            ["streamMoodEntries(studentId)", "Student's mood history"],
            ["saveMood(studentId, dateLabel, mood, suggestion)", "Save mood entry"],
            ["streamReflections(studentId)", "Student's reflections"],
            ["saveReflection(studentId, dateLabel, text)", "Save reflection"],
            ["streamChats(studentId)", "Last 50 chat entries (real-time)"],
            ["getRecentChats(studentId, limit)", "Recent chats for AI context"],
            ["saveChat(studentId, userMessage, aiReply)", "Save chat pair"],
            ["clearChats(studentId)", "Batch-delete all chats (400/batch)"],
        ],
        [80, 110],
    )

    # ChatApiService
    pdf.section_title(2, "ChatApiService")
    pdf.body_text("File: lib/services/chat_api_service.dart (291 lines) — Google Gemini AI integration.")

    pdf.body_text(
        "Configuration: API key and model loaded from Firestore app_config/gemini. "
        "Supports flexible field name matching (apiKey, api_key, apikey, geminiApiKey). "
        "Default model: gemini-2.5-flash-lite."
    )

    pdf.section_title(3, "ask() Method — Two Modes")
    pdf.table(
        ["Parameter", "Strict Mode", "Normal Mode"],
        [
            ["answerOnlyFromMaterials", "true", "false"],
            ["Behavior", "Only answers from provided context", "General tutor, any question"],
            ["Temperature", "0.2 (more focused)", "0.35 (more creative)"],
            ["Max Output Tokens", "1400", "900"],
            ["System Instruction", "Answer from context only", "Helpful tutor for students"],
        ],
        [50, 70, 70],
    )

    pdf.body_text(
        "The method accepts conversation history (List<ChatEntry>), optional study material context text, "
        "and sends the full payload to the Gemini API. Errors are translated to user-friendly messages."
    )

    # CloudinaryService
    pdf.section_title(2, "CloudinaryService")
    pdf.body_text("File: lib/services/cloudinary_service.dart (85 lines) — PDF upload to Cloudinary free tier.")
    pdf.bullet("pickAndUploadPdf() — Opens file picker (PDF only), uploads, returns secure URL")
    pdf.bullet("uploadPdf(fileName, filePath?, bytes?) — Low-level upload, supports byte data and file path")
    pdf.bullet("Upload endpoint: https://api.cloudinary.com/v1_1/{cloudName}/raw/upload")

    # WellbeingService
    pdf.section_title(2, "WellbeingService")
    pdf.body_text("File: lib/services/wellbeing_service.dart (25 lines) — Mood-to-suggestion mapping.")
    pdf.table(
        ["Mood", "Suggestion"],
        [
            ["Happy", "Great energy today. Use it to finish one tough chapter."],
            ["Calm", "Keep your rhythm. Do one revision session and one quiz."],
            ["Neutral", "Try a 25-minute focus block with no phone distractions."],
            ["Stressed", "Pause for 5 minutes of deep breathing, then start small."],
            ["Tired", "Do light review now and attempt harder topics after rest."],
            ["Anxious", "Write your top 3 worries and convert each into one action step."],
        ],
        [30, 160],
    )

    # ══════════════════════════════════════════════════════════════════════
    # 11. UI LAYER — PAGES & SCREENS
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "UI Layer — Pages & Screens", "11.")

    pdf.section_title(2, "Authentication")
    pdf.section_title(3, "AuthPage (auth_page.dart, 300 lines)")
    pdf.body_text(
        "A single page toggling between Login and Sign Up modes. Fields: _isLogin toggle, "
        "text controllers for name/email/password, loading state, error display. "
        "Login calls AuthService.signIn(), Signup calls AuthService.signUp()."
    )

    pdf.section_title(2, "Shared")
    pdf.section_title(3, "LoadingPage (loading_page.dart)")
    pdf.body_text("Animated loading screen with CircularProgressIndicator and customizable label. Used during auth transitions.")

    pdf.section_title(2, "Admin Module (7 Screens)")

    pdf.section_title(3, "AdminShellPage (109 lines)")
    pdf.body_text("Bottom navigation shell with 5 tabs: Classes, Materials, Quiz, Students, Usage. Uses IndexedStack for tab persistence.")

    pdf.section_title(3, "AdminClassesPage (~16 KB)")
    pdf.body_text(
        "Manages classes (Std 6, 7, 8, etc.) and subjects. Create/edit/delete classes, "
        "create/delete subjects, assign subjects to classes via multi-select. Real-time StreamBuilder updates."
    )

    pdf.section_title(3, "AdminMaterialsPage (~17 KB)")
    pdf.body_text(
        "Study material CRUD. Filter by class and subject. Add material with title, chapter, "
        "content text, optional PDF URL. Includes Cloudinary PDF upload button. Edit/delete existing materials."
    )

    pdf.section_title(3, "AdminQuizPage (~18 KB)")
    pdf.body_text(
        "Quiz question bank management. Filter by class, subject, chapter. "
        "Add MCQ questions with 4 options and correct answer. Delete existing questions."
    )

    pdf.section_title(3, "AdminStudentsPage (~11 KB)")
    pdf.body_text("List all students, view profiles, assign classes via dropdown, view quiz performance summary.")

    pdf.section_title(3, "AdminUsagePage (~7.5 KB)")
    pdf.body_text("System usage dashboard with stat cards: total students, quiz attempts, chats, materials.")

    pdf.section_title(3, "AdminApiSettingsPage (218 lines)")
    pdf.body_text("Gemini API key management: view (masked/unmasked), edit, save to Firestore, reload, force-refresh ChatApiService config cache.")

    pdf.section_title(2, "Student Module (8 Screens)")

    pdf.section_title(3, "StudentShellPage (109 lines)")
    pdf.body_text("Bottom navigation shell with 5 tabs: Home, Materials, Quiz, Mood, Chat. Uses IndexedStack.")

    pdf.section_title(3, "StudentDashboardPage (377 lines)")
    pdf.body_text(
        "Home dashboard: welcome message, assigned class display, subject list, "
        "quiz stats (total quizzes, average score, best score), recent quiz history."
    )

    pdf.section_title(3, "StudentMaterialsPage (242 lines)")
    pdf.body_text("Subject browser showing subjects assigned to student's class. Tapping navigates to StudentSubjectDetailsPage.")

    pdf.section_title(3, "StudentSubjectDetailsPage (~5.4 KB)")
    pdf.body_text("Material viewer per subject. Lists materials grouped by chapter. Displays text inline, PDF button for materials with pdfUrl.")

    pdf.section_title(3, "StudentPdfViewerPage (~1.9 KB)")
    pdf.body_text("Full-screen in-app PDF viewing using Syncfusion PDF viewer widget.")

    pdf.section_title(3, "StudentQuizPage (521 lines)")
    pdf.body_text(
        "Three-state quiz system: (1) Setup — select subject/chapter, (2) In-Progress — "
        "answer MCQs one at a time, (3) Results — score with pass/fail badge (green >= 50%, red < 50%). "
        "Fetches random questions, saves QuizAttempt on submit."
    )

    pdf.section_title(3, "StudentWellbeingPage (394 lines)")
    pdf.body_text(
        "Two sections: (1) Mood Tracker — select daily mood from categories, get personalized "
        "suggestion, view history. (2) Reflection Journal — free-text daily entry, view past reflections."
    )

    pdf.section_title(3, "StudentChatPage (947 lines) — Most Complex Screen")
    pdf.body_text(
        "AI-powered chatbot with: real-time Gemini chat, two modes (Normal general tutor / "
        "Strict material-based), material selector for context, PDF text extraction via Syncfusion, "
        "conversation history for context-aware responses, batch chat clear, bubble UI with "
        "user/AI differentiation, auto-scroll, loading indicators, and error handling."
    )

    # ══════════════════════════════════════════════════════════════════════
    # 12. THEMING & DESIGN SYSTEM
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Theming & Design System", "12.")

    pdf.body_text("File: lib/config/app_theme.dart (373 lines) — Material 3 theme built with Google Fonts Inter.")

    pdf.section_title(2, "Color Palette")
    pdf.table(
        ["Name", "Hex Code", "Usage"],
        [
            ["primaryBlue", "#1565C0", "Primary brand, buttons, active states"],
            ["accentBlue", "#42A5F5", "Secondary accents, gradient endpoints"],
            ["darkText", "#1A1A2E", "Primary text color"],
            ["secondaryText", "#5C6B8A", "Subtitles, labels, hints"],
            ["surfaceWhite", "#FFFFFF", "Card and surface backgrounds"],
            ["backgroundTint", "#F5F8FF", "Subtle tinted backgrounds"],
            ["borderLight", "#E0E8F5", "Card and input borders"],
        ],
        [40, 35, 115],
    )

    pdf.section_title(2, "Reusable Widget Builders")
    pdf.table(
        ["Method", "Purpose"],
        [
            ["cardDecoration(radius)", "White card with blue shadow"],
            ["accentLeftBorder(radius)", "Card with blue left accent border"],
            ["tintedContainer(radius)", "Light blue tinted background"],
            ["sectionHeader(context, title, icon?)", "Section title with optional icon"],
            ["statCard(label, value, icon, ...)", "Statistics display card"],
            ["scoreBadge(percent)", "Color-coded score badge (green/red)"],
            ["chapterChip(text)", "Blue chip for chapter labels"],
        ],
        [65, 125],
    )

    pdf.section_title(2, "Themed Components")
    pdf.body_text(
        "The Material 3 theme configures: AppBar, Card, InputDecoration, Buttons (Filled/Outlined/Text), "
        "NavigationBar, Chip, SnackBar, Dialog, Switch, Divider, ProgressIndicator, and DropdownMenu — "
        "all using the blue palette with consistent border radius (10-16px) and elevation settings."
    )

    # ══════════════════════════════════════════════════════════════════════
    # 13. USER FLOWS
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "User Flows", "13.")

    pdf.section_title(2, "Student Registration & Login")
    pdf.bullet("Student opens app -> AuthPage (login/signup toggle)")
    pdf.bullet("Signup: AuthService.signUp() creates Firebase Auth account + Firestore user doc")
    pdf.bullet("Root gate streams auth state -> streams profile -> routes to StudentShellPage")

    pdf.section_title(2, "Student Takes a Quiz")
    pdf.bullet("Step 1: Select subject and chapter on Quiz page")
    pdf.bullet("Step 2: App fetches N random questions from Firestore")
    pdf.bullet("Step 3: Student answers MCQs one at a time with navigation")
    pdf.bullet("Step 4: Submit -> calculate score -> save QuizAttempt -> show results with badge")

    pdf.section_title(2, "Student Uses AI Chat")
    pdf.bullet("Step 1: Type message in chat input")
    pdf.bullet("Step 2: Optionally select study materials for context (Strict mode)")
    pdf.bullet("Step 3: App builds context (material text + extracted PDF text)")
    pdf.bullet("Step 4: Sends prompt + history + context to Gemini API")
    pdf.bullet("Step 5: Display AI reply in chat bubble, save to Firestore")

    pdf.section_title(2, "Admin Manages Content")
    pdf.bullet("Admin logs in -> Root gate routes to AdminShellPage (5 tabs)")
    pdf.bullet("Classes tab: Add/edit/delete classes, create/delete subjects, assign subjects to classes")
    pdf.bullet("Materials tab: Add materials with text + optional PDF (Cloudinary upload)")
    pdf.bullet("Quiz tab: Add MCQ questions with 4 options and correct answer")
    pdf.bullet("Students tab: View students, assign classes, check performance")

    # ══════════════════════════════════════════════════════════════════════
    # 14. SETUP & DEPLOYMENT GUIDE
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Setup & Deployment Guide", "14.")

    pdf.section_title(2, "Prerequisites")
    pdf.bullet("Flutter SDK ^3.9.2 (includes Dart)")
    pdf.bullet("Firebase account with a project")
    pdf.bullet("Google Gemini API key (free tier available)")
    pdf.bullet("Cloudinary account (optional, for PDF hosting)")

    pdf.section_title(2, "Step-by-Step Setup")
    pdf.body_text("Step 1: Clone the repository", bold=True)
    pdf.code_block("git clone <repository-url>\ncd EduAi")

    pdf.body_text("Step 2: Create Firebase project", bold=True)
    pdf.bullet("Go to Firebase Console (https://console.firebase.google.com)")
    pdf.bullet("Enable Email/Password Authentication in Auth > Sign-in method")
    pdf.bullet("Create Cloud Firestore database")

    pdf.body_text("Step 3: Configure Firebase in the app", bold=True)
    pdf.bullet("Replace placeholders in lib/config/firebase_options_local.dart")
    pdf.bullet("Alternatively: firebase login && flutterfire configure")

    pdf.body_text("Step 4: Deploy Firestore rules & indexes", bold=True)
    pdf.code_block("firebase deploy --only firestore:rules\nfirebase deploy --only firestore:indexes")

    pdf.body_text("Step 5: Set app configuration", bold=True)
    pdf.bullet("In app_config.dart: set cloudinaryCloudName, cloudinaryUnsignedPreset, bootstrapAdminEmails")
    pdf.bullet("In Firestore app_config/gemini: create doc with apiKey and model fields")

    pdf.body_text("Step 6: Install dependencies & run", bold=True)
    pdf.code_block("flutter pub get\nflutter run")

    pdf.body_text("Step 7: Create admin account", bold=True)
    pdf.body_text("Sign up with an email listed in bootstrapAdminEmails. The account will auto-receive the admin role.")

    # ══════════════════════════════════════════════════════════════════════
    # 15. IMPORTANT NOTES & LIMITATIONS
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "Important Notes & Limitations", "15.")

    pdf.section_title(2, "Architecture Notes")
    pdf.table(
        ["Item", "Detail"],
        [
            ["Demo architecture", "Intentionally college/demo, not production-grade"],
            ["No Firebase Storage", "PDFs hosted on Cloudinary or external URLs"],
            ["No state management lib", "Uses built-in StreamBuilder/FutureBuilder"],
            ["Singleton services", "Simple but not unit-test friendly"],
        ],
        [50, 140],
    )

    pdf.section_title(2, "Security Considerations")
    pdf.table(
        ["Issue", "Detail"],
        [
            ["API key in Firestore", "Readable by signed-in users; use Cloud Functions in production"],
            ["Direct API calls", "Gemini called from client; should proxy via server in production"],
            ["Unsigned uploads", "Cloudinary preset allows uploads without auth; fine for demo"],
        ],
        [50, 140],
    )

    pdf.section_title(2, "Known Limitations")
    pdf.table(
        ["Limitation", "Detail"],
        [
            ["No push notifications", "Students not notified of new content"],
            ["No offline support", "Requires internet for all features"],
            ["No image/media materials", "Only text + PDF URL supported"],
            ["No per-question tracking", "Only total scores saved, not individual answers"],
            ["Admin creation", "Only via bootstrapAdminEmails before signup"],
            ["Immutable mood/reflections", "Cannot edit or delete once saved"],
            ["Chat history limit", "AI context: last 8 messages; stream: last 50"],
        ],
        [55, 135],
    )

    # ══════════════════════════════════════════════════════════════════════
    # FILE REFERENCE
    # ══════════════════════════════════════════════════════════════════════
    pdf.section_title(1, "File Reference", "16.")

    pdf.table(
        ["File", "Lines", "Description"],
        [
            ["main.dart", "28", "Entry point"],
            ["app.dart", "79", "Root widget + auth gate"],
            ["config/app_config.dart", "24", "App constants"],
            ["config/app_theme.dart", "373", "Theme + design widgets"],
            ["models/app_user.dart", "81", "User model"],
            ["models/chat_entry.dart", "49", "Chat model"],
            ["models/mood_entry.dart", "53", "Mood model"],
            ["models/quiz_attempt.dart", "73", "Quiz attempt model"],
            ["models/quiz_question.dart", "67", "Quiz question model"],
            ["models/reflection_entry.dart", "49", "Reflection model"],
            ["models/school_class.dart", "47", "Class model"],
            ["models/study_material.dart", "69", "Material model"],
            ["models/subject_model.dart", "37", "Subject model"],
            ["services/auth_service.dart", "94", "Auth service"],
            ["services/firestore_service.dart", "524", "Firestore CRUD"],
            ["services/chat_api_service.dart", "291", "Gemini API"],
            ["services/cloudinary_service.dart", "85", "PDF uploads"],
            ["services/wellbeing_service.dart", "25", "Mood suggestions"],
            ["pages/auth/auth_page.dart", "300", "Login/signup"],
            ["pages/shared/loading_page.dart", "~80", "Loading screen"],
            ["pages/admin/ (7 files)", "~1,600", "Admin module"],
            ["pages/student/ (8 files)", "~3,000", "Student module"],
        ],
        [60, 25, 105],
    )

    pdf.body_text("Total: ~37 source files, ~6,200+ lines of Dart code.", bold=True)

    # ── Build TOC ─────────────────────────────────────────────────────────
    # We move the TOC page to be page 2 by building it, then reordering pages
    toc_entries = pdf._toc_entries.copy()
    pdf.add_page()
    pdf.set_fill_color(*PRIMARY)
    pdf.rect(0, 0, 210, 14, "F")
    pdf.set_y(22)
    pdf.set_font("Helvetica", "B", 20)
    pdf.set_text_color(*PRIMARY)
    pdf.cell(0, 12, "Table of Contents", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(6)

    for level, title, page in toc_entries:
        if level > 2:
            continue
        indent = (level - 1) * 8
        pdf.set_x(16 + indent)
        if level == 1:
            pdf.set_font("Helvetica", "B", 11)
            pdf.set_text_color(*PRIMARY)
        else:
            pdf.set_font("Helvetica", "", 10)
            pdf.set_text_color(*DARK)
        pdf.cell(0, 7, title[:85], new_x="LMARGIN", new_y="NEXT")

    # ── Save ──────────────────────────────────────────────────────────────
    pdf.output(OUTPUT_PDF)
    print(f"\nPDF generated successfully: {OUTPUT_PDF}")
    print(f"Total pages: {len(pdf.pages) - 1}")


if __name__ == "__main__":
    build_document()
