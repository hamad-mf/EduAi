import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../config/app_theme.dart';
import '../../models/app_user.dart';
import '../../models/chat_entry.dart';
import '../../models/study_material.dart';
import '../../services/chat_api_service.dart';
import '../../services/firestore_service.dart';

class StudentChatPage extends StatefulWidget {
  const StudentChatPage({super.key, required this.student});

  final AppUser student;

  @override
  State<StudentChatPage> createState() => _StudentChatPageState();
}

class _StudentChatPageState extends State<StudentChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _sending = false;
  bool _clearingChats = false;
  bool _chatConfigLoading = true;
  String? _chatConfigError;
  bool _answerOnlyFromMaterials = true;
  final Set<String> _selectedMaterialIds = <String>{};
  final Map<String, String> _pdfTextCache = <String, String>{};
  int _lastRenderedChatCount = 0;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _initializeChatConfig();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatConfig({bool forceRefresh = false}) async {
    setState(() {
      _chatConfigLoading = true;
      _chatConfigError = null;
    });

    try {
      await ChatApiService.instance.loadConfig(forceRefresh: forceRefresh);
      if (!ChatApiService.instance.isConfigured) {
        _chatConfigError =
            ChatApiService.instance.configDebugMessage ??
            'Gemini config missing in Firestore app_config/gemini.';
      }
    } catch (error) {
      _chatConfigError = error.toString();
    } finally {
      if (mounted) {
        setState(() => _chatConfigLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    final String cleanMessage = message
        .replaceFirst('Exception: ', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cleanMessage.isEmpty ? 'Something went wrong.' : cleanMessage,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _scheduleScrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients) {
        return;
      }

      final double target = _chatScrollController.position.maxScrollExtent;
      if (animated) {
        _chatScrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
        return;
      }
      _chatScrollController.jumpTo(target);
    });
  }

  Future<void> _confirmAndClearChats() async {
    if (_clearingChats) {
      return;
    }

    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Chats'),
          content: const Text(
            'Delete all chat messages in this account? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    setState(() => _clearingChats = true);
    try {
      final int deleted = await FirestoreService.instance.clearChats(
        widget.student.id,
      );
      _lastRenderedChatCount = 0;
      _initialScrollDone = false;
      _showMessage(
        deleted == 0 ? 'No chats to clear.' : 'Cleared $deleted chat(s).',
      );
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _clearingChats = false);
      }
    }
  }

  Future<void> _send(List<StudyMaterial> classMaterials) async {
    if (_chatConfigLoading) {
      _showMessage('Loading chat configuration. Please wait.');
      return;
    }
    if (!ChatApiService.instance.isConfigured) {
      await _initializeChatConfig(forceRefresh: true);
      if (!mounted) {
        return;
      }
      if (_chatConfigError != null) {
        _showMessage(_chatConfigError!);
        return;
      }
      if (!ChatApiService.instance.isConfigured) {
        _showMessage(
          ChatApiService.instance.configDebugMessage ??
              'Gemini API key not set in Firestore app_config/gemini.',
        );
        return;
      }
    }

    final String message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    final List<StudyMaterial> availableMaterials = _selectedMaterialIds.isEmpty
        ? classMaterials
        : classMaterials
              .where((StudyMaterial m) => _selectedMaterialIds.contains(m.id))
              .toList();

    setState(() => _sending = true);
    _messageController.clear();
    try {
      String materialContext = '';
      if (_answerOnlyFromMaterials) {
        materialContext = await _buildMaterialContext(availableMaterials);
        if (availableMaterials.isEmpty) {
          _showMessage(
            'No study materials found. Ask your teacher to add materials.',
          );
          return;
        }
        if (materialContext.isEmpty) {
          _showMessage(
            'No extractable text found in selected materials. '
            'Add text notes or use text-based PDFs (not image-only scans).',
          );
          return;
        }
      }

      final List<ChatEntry> history = await FirestoreService.instance
          .getRecentChats(widget.student.id, limit: 6);
      final String reply = await ChatApiService.instance.ask(
        message,
        history: history,
        studyMaterialContext: _answerOnlyFromMaterials ? materialContext : null,
        answerOnlyFromMaterials: _answerOnlyFromMaterials,
        includeModelHistory: _answerOnlyFromMaterials,
      );
      await FirestoreService.instance.saveChat(
        studentId: widget.student.id,
        userMessage: message,
        aiReply: reply,
      );
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<String> _buildMaterialContext(List<StudyMaterial> materials) async {
    if (materials.isEmpty) {
      return '';
    }

    const int maxTotalChars = 42000;
    const int maxPerMaterialChars = 12000;
    final StringBuffer buffer = StringBuffer();
    int usedChars = 0;

    for (int index = 0; index < materials.length; index++) {
      final StudyMaterial material = materials[index];
      final List<String> sections = <String>[];

      final String notes = material.content.trim();
      if (notes.isNotEmpty) {
        sections.add(
          'Notes Text:\n${_prepareContextText(notes, maxPerSectionChars: 2500)}',
        );
      }

      final String pdfUrl = material.pdfUrl?.trim() ?? '';
      if (pdfUrl.isNotEmpty) {
        final String pdfText = await _extractTextFromPdf(
          materialId: material.id,
          pdfUrl: pdfUrl,
        );
        if (pdfText.isNotEmpty) {
          final String moduleHints = _extractModuleHeadings(pdfText);
          if (moduleHints.isNotEmpty) {
            sections.add('Detected Module Headings:\n$moduleHints');
          }
          sections.add(
            'PDF Extract:\n${_prepareContextText(pdfText, maxPerSectionChars: maxPerMaterialChars)}',
          );
        }
      }

      if (sections.isEmpty) {
        continue;
      }

      final String block =
          '[Material ${index + 1}] '
          'Title: ${material.title}\n'
          'Chapter: ${material.chapter}\n'
          '${sections.join('\n\n')}\n\n';

      if (usedChars + block.length > maxTotalChars) {
        break;
      }

      buffer.write(block);
      usedChars += block.length;
    }

    return buffer.toString().trim();
  }

  String _prepareContextText(String text, {required int maxPerSectionChars}) {
    final String normalized = text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    if (normalized.length <= maxPerSectionChars) {
      return normalized;
    }

    final String headingBlock = _extractModuleHeadings(normalized);
    final int reservedForHeadings = headingBlock.isEmpty
        ? 0
        : headingBlock.length.clamp(0, maxPerSectionChars ~/ 3);

    final int remaining = maxPerSectionChars - reservedForHeadings - 60;
    final int prefixLen = (remaining * 0.55).toInt();
    final int suffixLen = remaining - prefixLen;

    final String prefix = normalized.substring(
      0,
      prefixLen.clamp(0, normalized.length),
    );
    final String suffix = normalized.substring(
      (normalized.length - suffixLen).clamp(0, normalized.length),
      normalized.length,
    );

    if (headingBlock.isEmpty) {
      return '$prefix\n\n... [truncated] ...\n\n$suffix';
    }
    return '$prefix\n\n--- Key Headings ---\n$headingBlock\n\n... [truncated] ...\n\n$suffix';
  }

  String _extractModuleHeadings(String text) {
    final List<String> lines = text
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();

    final RegExp modulePattern = RegExp(
      r'\b(module|core functionalities|teacher module|driver module|user module|parent module|student module)\b',
      caseSensitive: false,
    );

    final Set<String> unique = <String>{};
    for (final String line in lines) {
      if (line.length > 160) {
        continue;
      }
      if (modulePattern.hasMatch(line)) {
        unique.add(line.replaceAll(RegExp(r'\s+'), ' '));
      }
      if (unique.length >= 20) {
        break;
      }
    }

    if (unique.isEmpty) {
      return '';
    }

    final List<String> items = unique.toList();
    return List<String>.generate(
      items.length,
      (int index) => '${index + 1}. ${items[index]}',
    ).join('\n');
  }

  Future<String> _extractTextFromPdf({
    required String materialId,
    required String pdfUrl,
  }) async {
    if (_pdfTextCache.containsKey(materialId)) {
      return _pdfTextCache[materialId]!;
    }

    try {
      final http.Response response = await http
          .get(Uri.parse(pdfUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode > 299) {
        _pdfTextCache[materialId] = '';
        return '';
      }

      final List<int> bytes = response.bodyBytes;
      if (bytes.isEmpty || bytes.length > (15 * 1024 * 1024)) {
        _pdfTextCache[materialId] = '';
        return '';
      }

      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String extracted = extractor.extractText();
      document.dispose();

      final String cleaned = extracted
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();

      _pdfTextCache[materialId] = cleaned;
      return cleaned;
    } on TimeoutException {
      _pdfTextCache[materialId] = '';
      return '';
    } catch (_) {
      _pdfTextCache[materialId] = '';
      return '';
    }
  }

  Future<void> _openMaterialSelector(List<StudyMaterial> classMaterials) async {
    final Set<String> tempSelected = <String>{..._selectedMaterialIds};
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Study Materials'),
          content: StatefulBuilder(
            builder:
                (
                  BuildContext context,
                  void Function(void Function()) setDialogState,
                ) {
                  return SizedBox(
                    width: 380,
                    child: classMaterials.isEmpty
                        ? const Text('No materials available.')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: classMaterials.length,
                            itemBuilder: (BuildContext context, int index) {
                              final StudyMaterial material =
                                  classMaterials[index];
                              final bool checked = tempSelected.contains(
                                material.id,
                              );
                              return CheckboxListTile(
                                value: checked,
                                title: Text(material.title),
                                subtitle: Text('Chapter: ${material.chapter}'),
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      tempSelected.add(material.id);
                                    } else {
                                      tempSelected.remove(material.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  );
                },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedMaterialIds.clear());
                Navigator.of(context).pop();
              },
              child: const Text('Use All'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _selectedMaterialIds
                    ..clear()
                    ..addAll(tempSelected);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  // ── Chat Bubble Widgets ──
  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _aiBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F3F8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.darkText,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.student.classId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.tintedContainer(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your class is not assigned yet. Please contact your teacher.',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<StudyMaterial>>(
      stream: FirestoreService.instance.streamClassMaterials(
        classId: widget.student.classId!,
      ),
      builder: (BuildContext context, AsyncSnapshot<List<StudyMaterial>> materialSnapshot) {
        if (!materialSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<StudyMaterial> classMaterials = materialSnapshot.data!;
        classMaterials.sort((StudyMaterial a, StudyMaterial b) {
          final int byChapter = a.chapter.compareTo(b.chapter);
          if (byChapter != 0) {
            return byChapter;
          }
          return a.title.compareTo(b.title);
        });

        final List<StudyMaterial> selectedMaterials =
            _selectedMaterialIds.isEmpty
            ? classMaterials
            : classMaterials
                  .where(
                    (StudyMaterial material) =>
                        _selectedMaterialIds.contains(material.id),
                  )
                  .toList();

        return Column(
          children: <Widget>[
            // ── Config Loading/Error ──
            if (_chatConfigLoading)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.tintedContainer(),
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Loading chat configuration...',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _initializeChatConfig(forceRefresh: true),
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Retry',
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              )
            else if (!ChatApiService.instance.isConfigured ||
                _chatConfigError != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _chatConfigError ??
                          'Gemini API key missing in Firestore app_config/gemini.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _initializeChatConfig(forceRefresh: true),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry Config Load'),
                    ),
                  ],
                ),
              ),

            // ── Controls Card ──
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.cardDecoration(radius: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chat Controls',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: (_clearingChats || _sending)
                            ? null
                            : _confirmAndClearChats,
                        icon: _clearingChats
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Answer only from study materials',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'AI uses material notes and extractable PDF text only.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    value: _answerOnlyFromMaterials,
                    onChanged: (bool value) {
                      setState(() => _answerOnlyFromMaterials = value);
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _selectedMaterialIds.isEmpty
                              ? 'Using all materials (${classMaterials.length})'
                              : 'Selected materials: ${selectedMaterials.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openMaterialSelector(classMaterials),
                        icon: const Icon(Icons.library_books, size: 16),
                        label: const Text('Select'),
                      ),
                    ],
                  ),
                  if (_selectedMaterialIds.isNotEmpty &&
                      selectedMaterials.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedMaterials
                          .take(8)
                          .map(
                            (StudyMaterial material) => Chip(
                              label: Text(
                                material.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // ── Chat Messages ──
            Expanded(
              child: StreamBuilder<List<ChatEntry>>(
                stream: FirestoreService.instance.streamChats(
                  widget.student.id,
                ),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<ChatEntry>> snapshot,
                    ) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final List<ChatEntry> chats = snapshot.data!.reversed
                          .toList();
                      if (chats.isEmpty) {
                        _lastRenderedChatCount = 0;
                        _initialScrollDone = false;
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Ask your first academic doubt.',
                                style: TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final bool hasNewItems =
                          chats.length != _lastRenderedChatCount;
                      if (!_initialScrollDone) {
                        _scheduleScrollToBottom(animated: false);
                        _initialScrollDone = true;
                      } else if (hasNewItems) {
                        _scheduleScrollToBottom(animated: true);
                      }
                      _lastRenderedChatCount = chats.length;

                      return ListView.builder(
                        controller: _chatScrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: chats.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ChatEntry chat = chats[index];
                          final String timestamp = chat.createdAt == null
                              ? ''
                              : DateFormat.yMMMd().add_jm().format(
                                  chat.createdAt!,
                                );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _userBubble(chat.userMessage),
                                const SizedBox(height: 6),
                                _aiBubble(chat.aiReply),
                                if (timestamp.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      timestamp,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.secondaryText,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
              ),
            ),

            // ── Input Bar ──
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                border: Border(
                  top: BorderSide(color: Color(0xFFE8EDF5), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Ask an academic question...',
                            hintStyle: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F8FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppTheme.borderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppTheme.borderLight,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryBlue,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _send(classMaterials),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: _sending ? null : AppTheme.heroGradient,
                          color: _sending ? Colors.grey.shade300 : null,
                          shape: BoxShape.circle,
                          boxShadow: _sending
                              ? null
                              : <BoxShadow>[
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: IconButton(
                          onPressed: _sending
                              ? null
                              : () => _send(classMaterials),
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
