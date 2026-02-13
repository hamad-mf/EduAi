class WellbeingService {
  WellbeingService._();

  static final WellbeingService instance = WellbeingService._();

  String suggestionForMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return 'Great energy today. Use it to finish one tough chapter.';
      case 'calm':
        return 'Keep your rhythm. Do one revision session and one quiz.';
      case 'neutral':
        return 'Try a 25-minute focus block with no phone distractions.';
      case 'stressed':
        return 'Pause for 5 minutes of deep breathing, then start small.';
      case 'tired':
        return 'Do light review now and attempt harder topics after rest.';
      case 'anxious':
        return 'Write your top 3 worries and convert each into one action step.';
      default:
        return 'Stay consistent with small daily progress.';
    }
  }
}
