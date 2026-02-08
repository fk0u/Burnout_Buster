import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:provider/provider.dart';
// import 'package:hive_flutter/hive_flutter.dart'; // Unused
import '../services/ai_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Removed: late Box _chatBox;
  // Removed: List<Map<dynamic, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Messages loaded by AIService
    // _scrollToBottom() called after build
  }

  // Removed: _loadMessages()

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact(); // Haptic feedback

    final text = _textController.text;
    _textController.clear();

    // Send to AI Service (which handles updating state and persistence)
    final aiService = Provider.of<AIService>(context, listen: false);
    await aiService.sendMessage(text);

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // Watch AIService
    final aiService = Provider.of<AIService>(context);
    final messages = aiService.currentMessages;

    // Auto-scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jedo (AI Temen Curhat)'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              aiService.startNewSession();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesi curhat baru dimulai!')));
            },
            tooltip: 'Sesi Baru',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada chat. Sapa Jedo dong!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF10B981)
                                : const Color(0xFF334155),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isUser
                                  ? const Radius.circular(12)
                                  : const Radius.circular(0),
                              bottomRight: isUser
                                  ? const Radius.circular(0)
                                  : const Radius.circular(12),
                            ),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                            .animate()
                            .fade(duration: 400.ms)
                            .slideX(
                                begin: isUser ? 1 : -1,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutQuad)
                            .scale(
                              duration: 400.ms,
                              alignment: isUser
                                  ? Alignment.bottomRight
                                  : Alignment.bottomLeft,
                            ),
                      );
                    },
                  ),
          ),
          if (aiService.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const TypingIndicator(),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16).copyWith(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Curhat sini...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF334155),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 4),
          _buildDot(200),
          const SizedBox(width: 4),
          _buildDot(400),
        ],
      ),
    ).animate().fade().scale(
          alignment: Alignment.bottomLeft,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildDot(int delay) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
            delay: delay.ms,
            duration: 600.ms,
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0))
        .fade(delay: delay.ms, duration: 600.ms, begin: 0.5, end: 1.0);
  }
}
