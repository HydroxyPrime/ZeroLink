import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _storageService = StorageService();
  final _scrollController = ScrollController();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  late final String _chatId = buildChatId(_uid, widget.otherUser.userId);

  @override
  void initState() {
    super.initState();
    // Mark existing unread messages as read on open.
    _chatService.markMessagesAsRead(_chatId, _uid);
  }

  Future<void> _sendText(String text) async {
    await _chatService.sendMessage(
      senderId: _uid,
      receiverId: widget.otherUser.userId,
      text: text,
    );
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final url = await _storageService.pickAndUploadImage(
      chatId: _chatId,
      source: ImageSource.gallery,
    );
    if (url == null) return;
    await _chatService.sendMessage(
      senderId: _uid,
      receiverId: widget.otherUser.userId,
      text: url,
      type: MessageType.image,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: StreamBuilder<UserModel>(
          stream: _chatService.userStream(widget.otherUser.userId),
          builder: (context, snapshot) {
            final user = snapshot.data ?? widget.otherUser;
            final statusText = user.isOnline
                ? 'Active now'
                : (user.lastSeen != null
                    ? 'Last seen ${timeago.format(user.lastSeen!)}'
                    : 'Offline');
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                  child: user.photoUrl.isEmpty
                      ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: user.isOnline ? AppColors.online : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.messageStream(_chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Say hi 👋', style: TextStyle(color: AppColors.textLight)),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    return MessageBubble(message: msg, isMe: msg.senderId == _uid);
                  },
                );
              },
            ),
          ),
          ChatInput(onSend: _sendText, onAttach: _sendImage),
        ],
      ),
    );
  }
}
