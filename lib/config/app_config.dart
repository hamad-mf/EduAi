class AppConfig {
  AppConfig._();

  // Add your Gemini API key here for direct client-side calls.
  // College/demo only. Do not use this approach in production apps.
  static const String geminiApiKey = 'AIzaSyBy_Zf9kOMAjb42TrNO_-w9QhF4tOTzXOY';
  static const String geminiModel = 'gemini-2.5-flash';

  // Optional Cloudinary settings for PDF uploads from admin panel.
  // If these are not set, admin can still add PDF links manually.
  static const String cloudinaryCloudName = 'dzzjiiwuy';
  static const String cloudinaryUnsignedPreset = 'eduai_pdf_unsigned';

  // Any email in this list will be created as admin on signup.
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
