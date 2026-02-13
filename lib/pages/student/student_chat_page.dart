import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/chat_entry.dart';
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
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    _messageController.clear();
    try {
      final String reply = await ChatApiService.instance.ask(message);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (!ChatApiService.instance.isConfigured)
          const Card(
            margin: EdgeInsets.all(12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Set Gemini API key in app_config.dart to enable chatbot.',
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<ChatEntry>>(
            stream: FirestoreService.instance.streamChats(widget.student.id),
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
                    return const Center(
                      child: Text('Ask your first academic doubt.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: chats.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ChatEntry chat = chats[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'You',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(chat.userMessage),
                              const Divider(height: 18),
                              const Text(
                                'AI',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(chat.aiReply),
                              const SizedBox(height: 8),
                              Text(
                                chat.createdAt == null
                                    ? ''
                                    : DateFormat.yMMMd().add_jm().format(
                                        chat.createdAt!,
                                      ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ask an academic question...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  child: Text(_sending ? '...' : 'Send'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
