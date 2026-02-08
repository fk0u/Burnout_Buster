import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final Box _chatBox = Hive.box('chatHistory');
  List<Map<dynamic, dynamic>> _allMessages = [];
  List<Map<dynamic, dynamic>> _filteredMessages = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    final rawMessages = _chatBox.get('messages', defaultValue: []);
    // Reverse to show latest first for diary log context,
    // but usually chat is oldest top. For diary, we might want to see "events".
    // Let's just show the history list for now.
    _allMessages =
        List<Map<dynamic, dynamic>>.from(rawMessages).reversed.toList();
    _filterMessages('');
  }

  void _filterMessages(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMessages = _allMessages;
      });
      return;
    }

    setState(() {
      _filteredMessages = _allMessages.where((msg) {
        final text = msg['text'].toString().toLowerCase();
        return text.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary Curhat'),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari curhatan lama...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterMessages,
            ),
          ),
        ),
      ),
      body: _filteredMessages.isEmpty
          ? const Center(
              child: Text(
                'Belum ada history atau gak ketemu.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredMessages.length,
              itemBuilder: (context, index) {
                final msg = _filteredMessages[index];
                final isUser = msg['role'] == 'user';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isUser
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUser
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[700],
                      child: Icon(
                        isUser ? Icons.person : Icons.smart_toy,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        isUser ? 'Elo' : 'Jedo',
                        style: TextStyle(
                            fontSize: 12,
                            color: isUser
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
                    .animate(delay: (index * 50).ms)
                    .slideX(begin: 0.2, end: 0, duration: 400.ms)
                    .fade(duration: 400.ms);
              },
            ),
    );
  }
}
