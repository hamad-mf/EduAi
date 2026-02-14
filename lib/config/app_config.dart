class AppConfig {
  AppConfig._();

  // Gemini config is fetched from Firestore:
  // app_config/gemini -> { apiKey: "...", model: "..." }

  // Optional Cloudinary settings for PDF uploads from teacher panel.
  // If these are not set, teacher can still add PDF links manually.
  static const String cloudinaryCloudName = 'dzzjiiwuy';
  static const String cloudinaryUnsignedPreset = 'eduai_pdf_unsigned';

  // Any email in this list will be treated as teacher signup.
  static const List<String> bootstrapAdminEmails = <String>['admin@eduai.com'];

  static const List<String> moodCategories = <String>[
    'Happy',
    'Calm',
    'Neutral',
    'Stressed',
    'Tired',
    'Anxious',
  ];
}
