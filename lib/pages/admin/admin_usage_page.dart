import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/firestore_service.dart';

class AdminUsagePage extends StatefulWidget {
  const AdminUsagePage({super.key, required this.admin});

  final AppUser admin;

  @override
  State<AdminUsagePage> createState() => _AdminUsagePageState();
}

class _AdminUsagePageState extends State<AdminUsagePage> {
  late Future<Map<String, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = FirestoreService.instance.getUsageCounts();
  }

  void _refresh() {
    setState(() {
      _countsFuture = FirestoreService.instance.getUsageCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _countsFuture,
      builder: (BuildContext context, AsyncSnapshot<Map<String, int>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final Map<String, int> counts = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'System Usage',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _usageCard(
              title: 'Total Students',
              value: counts['students'] ?? 0,
              icon: Icons.people,
            ),
            _usageCard(
              title: 'Total Quiz Attempts',
              value: counts['quizAttempts'] ?? 0,
              icon: Icons.quiz,
            ),
            _usageCard(
              title: 'Total Chat Messages',
              value: counts['chats'] ?? 0,
              icon: Icons.chat,
            ),
            _usageCard(
              title: 'Total Materials',
              value: counts['materials'] ?? 0,
              icon: Icons.menu_book,
            ),
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'These are basic live counters from Firestore collections '
                  'for college project monitoring.',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _usageCard({
    required String title,
    required int value,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        trailing: Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }
}
