import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_config.dart';
import '../../models/app_user.dart';
import '../../models/mood_entry.dart';
import '../../models/reflection_entry.dart';
import '../../services/firestore_service.dart';
import '../../services/wellbeing_service.dart';

class StudentWellbeingPage extends StatefulWidget {
  const StudentWellbeingPage({super.key, required this.student});

  final AppUser student;

  @override
  State<StudentWellbeingPage> createState() => _StudentWellbeingPageState();
}

class _StudentWellbeingPageState extends State<StudentWellbeingPage> {
  String _selectedMood = AppConfig.moodCategories.first;
  final TextEditingController _reflectionController = TextEditingController();
  bool _savingMood = false;
  bool _savingReflection = false;
  String? _lastSuggestion;

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveMood() async {
    setState(() => _savingMood = true);
    try {
      final String suggestion = WellbeingService.instance.suggestionForMood(
        _selectedMood,
      );
      final String dateLabel = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirestoreService.instance.saveMood(
        studentId: widget.student.id,
        dateLabel: dateLabel,
        mood: _selectedMood,
        suggestion: suggestion,
      );
      setState(() => _lastSuggestion = suggestion);
      _showMessage('Mood saved.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _savingMood = false);
      }
    }
  }

  Future<void> _saveReflection() async {
    final String text = _reflectionController.text.trim();
    if (text.isEmpty) {
      _showMessage('Reflection cannot be empty.');
      return;
    }

    setState(() => _savingReflection = true);
    try {
      final String dateLabel = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirestoreService.instance.saveReflection(
        studentId: widget.student.id,
        dateLabel: dateLabel,
        text: text,
      );
      _reflectionController.clear();
      _showMessage('Reflection saved.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _savingReflection = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Daily Mood',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMood,
                  decoration: const InputDecoration(
                    labelText: 'Select mood',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConfig.moodCategories
                      .map(
                        (String mood) => DropdownMenuItem<String>(
                          value: mood,
                          child: Text(mood),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedMood = value);
                  },
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _savingMood ? null : _saveMood,
                  child: Text(_savingMood ? 'Saving...' : 'Save Mood'),
                ),
                if (_lastSuggestion != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Suggestion: $_lastSuggestion',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Daily Reflection Journal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reflectionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Write your reflection...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _savingReflection ? null : _saveReflection,
                  child: Text(
                    _savingReflection ? 'Saving...' : 'Save Reflection',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Mood History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<MoodEntry>>(
          stream: FirestoreService.instance.streamMoodEntries(
            widget.student.id,
          ),
          builder:
              (BuildContext context, AsyncSnapshot<List<MoodEntry>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final List<MoodEntry> moods = snapshot.data!;
                if (moods.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No mood entries yet.'),
                    ),
                  );
                }
                return Column(
                  children: moods.take(10).map((MoodEntry mood) {
                    return Card(
                      child: ListTile(
                        title: Text('${mood.dateLabel} - ${mood.mood}'),
                        subtitle: Text(mood.suggestion),
                      ),
                    );
                  }).toList(),
                );
              },
        ),
        const SizedBox(height: 12),
        Text(
          'Past Reflections',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ReflectionEntry>>(
          stream: FirestoreService.instance.streamReflections(
            widget.student.id,
          ),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<ReflectionEntry>> snapshot,
              ) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final List<ReflectionEntry> reflections = snapshot.data!;
                if (reflections.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No reflections yet.'),
                    ),
                  );
                }
                return Column(
                  children: reflections.take(20).map((
                    ReflectionEntry reflection,
                  ) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              reflection.dateLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(reflection.text),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
        ),
      ],
    );
  }
}
