import 'package:hive_flutter/hive_flutter.dart';

class ChatSessionModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<Map<dynamic, dynamic>> messages;

  ChatSessionModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages,
    };
  }

  factory ChatSessionModel.fromMap(Map<dynamic, dynamic> map) {
    return ChatSessionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      messages: List<Map<dynamic, dynamic>>.from(map['messages'] ?? []),
    );
  }
}
