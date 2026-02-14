import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/chat_api_service.dart';
import '../../services/firestore_service.dart';

class TeacherApiSettingsPage extends StatefulWidget {
  const TeacherApiSettingsPage({super.key});

  @override
  State<TeacherApiSettingsPage> createState() => _TeacherApiSettingsPageState();
}

class _TeacherApiSettingsPageState extends State<TeacherApiSettingsPage> {
  final TextEditingController _keyController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _obscured = true;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    setState(() {
      _loading = true;
      _statusMessage = '';
    });
    try {
      final String? key = await FirestoreService.instance.getGeminiApiKey();
      _keyController.text = key ?? '';
    } catch (error) {
      _statusMessage = 'Error loading key: $error';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveKey() async {
    setState(() {
      _saving = true;
      _statusMessage = '';
    });
    try {
      await FirestoreService.instance.saveGeminiApiKey(
        _keyController.text.trim(),
      );
      await ChatApiService.instance.loadConfig(forceRefresh: true);
      _statusMessage = 'API key saved successfully.';
    } catch (error) {
      _statusMessage = 'Error: $error';
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _maskApiKey(String value) {
    if (value.isEmpty) {
      return '';
    }
    if (value.length <= 8) {
      return '*' * value.length;
    }
    return '${value.substring(0, 4)}${'*' * (value.length - 8)}${value.substring(value.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Settings')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppTheme.pageBackgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // ── API Key Card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppTheme.sectionHeader(context, 'Gemini API Key', icon: Icons.key_rounded),
                  const SizedBox(height: 4),
                  const Text(
                    'This key is used for AI chat. It is stored in Firestore app_config/gemini.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...<Widget>[
                    // ── Display current key ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: AppTheme.tintedContainer(),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _keyController.text.isEmpty
                                  ? 'No key set'
                                  : _obscured
                                      ? _maskApiKey(_keyController.text)
                                      : _keyController.text,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: _keyController.text.isEmpty
                                    ? AppTheme.secondaryText
                                    : AppTheme.darkText,
                              ),
                            ),
                          ),
                          if (_keyController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                _obscured
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _obscured = !_obscured),
                              tooltip: _obscured ? 'Show key' : 'Hide key',
                              color: AppTheme.primaryBlue,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Edit key ──
                    TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        labelText: 'API Key',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _loadKey,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reload'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _saving ? null : _saveKey,
                          child: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Key'),
                        ),
                      ],
                    ),
                  ],
                  if (_statusMessage.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusMessage.startsWith('Error')
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: _statusMessage.startsWith('Error')
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
