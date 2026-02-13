import 'package:edu_ai/services/wellbeing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns suggestion for stressed mood', () {
    final String suggestion = WellbeingService.instance.suggestionForMood(
      'Stressed',
    );
    expect(suggestion.isNotEmpty, true);
  });
}
