import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4361EE);
  static const primaryDark = Color(0xFF3A0CA3);
  static const bubbleSent = Color(0xFF4361EE);
  static const bubbleReceived = Color(0xFFF1F3F5);
  static const online = Color(0xFF2ECC71);
  static const offline = Color(0xFF95A5A6);
  static const background = Color(0xFFFAFAFA);
  static const textDark = Color(0xFF1A1A2E);
  static const textLight = Color(0xFF6C757D);
}

class Collections {
  static const users = 'users';
  static const chats = 'chats';
  static const messages = 'messages';
}

class MessageType {
  static const text = 'text';
  static const image = 'image';
  static const file = 'file';
}

class MessageStatus {
  static const sent = 'sent';
  static const delivered = 'delivered';
  static const read = 'read';
}

/// Deterministic chatId so two users always land in the same thread
/// regardless of who initiates.
String buildChatId(String userIdA, String userIdB) {
  final ids = [userIdA, userIdB]..sort();
  return '${ids[0]}_${ids[1]}';
}
