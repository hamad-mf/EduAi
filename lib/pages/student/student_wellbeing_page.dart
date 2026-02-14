import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/app_config.dart';
import '../../config/app_theme.dart';
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
  final TextEditingController _reflectionController = TextEditingController();
  String? _selectedMood;
  bool _savingMood = false;
  bool _savingReflection = false;
  String? _suggestion;

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  void _onMoodChanged(String? mood) {
    setState(() {
      _selectedMood = mood;
      _suggestion = mood == null
          ? null
          : WellbeingService.instance.suggestionForMood(mood);
    });
  }

  String get _dateLabel => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _saveMood() async {
    if (_selectedMood == null) {
      return;
    }
    setState(() => _savingMood = true);
    try {
      await FirestoreService.instance.saveMood(
        studentId: widget.student.id,
        dateLabel: _dateLabel,
        mood: _selectedMood!,
        suggestion: _suggestion ?? '',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedMood = null;
        _suggestion = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mood saved!')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _savingMood = false);
      }
    }
  }

  Future<void> _saveReflection() async {
    final String text = _reflectionController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _savingReflection = true);
    try {
      await FirestoreService.instance.saveReflection(
        studentId: widget.student.id,
        dateLabel: _dateLabel,
        text: text,
      );
      if (!mounted) {
        return;
      }
      _reflectionController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reflection saved!')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _savingReflection = false);
      }
    }
  }

  static const Map<String, String> _moodEmojis = <String, String>{
    'Happy': '😊',
    'Calm': '😌',
    'Neutral': '😐',
    'Stressed': '😰',
    'Tired': '😴',
    'Anxious': '😟',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        // ── Mood Card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppTheme.sectionHeader(context, 'How are you feeling?', icon: Icons.self_improvement),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMood,
                decoration: const InputDecoration(
                  labelText: 'Select your mood',
                  prefixIcon: Icon(Icons.mood_outlined),
                  border: OutlineInputBorder(),
                ),
                items: AppConfig.moodCategories.map((String mood) {
                  final String emoji = _moodEmojis[mood] ?? '🙂';
                  return DropdownMenuItem<String>(
                    value: mood,
                    child: Text('$emoji  $mood'),
                  );
                }).toList(),
                onChanged: _onMoodChanged,
              ),
              if (_suggestion != null) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.tintedContainer(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _suggestion!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.darkText,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_savingMood || _selectedMood == null) ? null : _saveMood,
                  icon: _savingMood
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Log Mood'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Journal Card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppTheme.sectionHeader(context, 'Daily Reflection', icon: Icons.edit_note),
              const SizedBox(height: 8),
              TextField(
                controller: _reflectionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write about your day...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _savingReflection ? null : _saveReflection,
                  icon: _savingReflection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Reflection'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Mood History ──
        AppTheme.sectionHeader(context, 'Mood History', icon: Icons.timeline),
        const SizedBox(height: 4),
        StreamBuilder<List<MoodEntry>>(
          stream: FirestoreService.instance.streamMoodEntries(
            widget.student.id,
          ),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<MoodEntry>> snapshot,
          ) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<MoodEntry> entries = snapshot.data!;
            if (entries.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.tintedContainer(),
                child: const Text(
                  'No mood entries yet. Start by logging your mood today!',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
              );
            }

            return Column(
              children: entries.map((MoodEntry entry) {
                final String emoji = _moodEmojis[entry.mood] ?? '🙂';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppTheme.cardDecoration(radius: 12),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3EDFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.mood,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (entry.createdAt != null)
                                Text(
                                  DateFormat.yMMMd().add_jm().format(entry.createdAt!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondaryText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),

        // ── Reflection History ──
        AppTheme.sectionHeader(context, 'Reflections', icon: Icons.history),
        const SizedBox(height: 4),
        StreamBuilder<List<ReflectionEntry>>(
          stream: FirestoreService.instance.streamReflections(
            widget.student.id,
          ),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<ReflectionEntry>> snapshot,
          ) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<ReflectionEntry> entries = snapshot.data!;
            if (entries.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.tintedContainer(),
                child: const Text(
                  'No reflections yet.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
              );
            }

            return Column(
              children: entries.map((ReflectionEntry entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppTheme.cardDecoration(radius: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (entry.createdAt != null)
                          Text(
                            DateFormat.yMMMd().add_jm().format(entry.createdAt!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          entry.text,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.darkText,
                            height: 1.4,
                          ),
                        ),
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
