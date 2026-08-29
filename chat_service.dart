import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Real-time stream of messages for a chat, oldest -> newest.
  Stream<List<MessageModel>> messageStream(String chatId) {
    return _db
        .collection(Collections.chats)
        .doc(chatId)
        .collection(Collections.messages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromDoc(d)).toList());
  }

  /// Real-time stream of the current user's chat list, most recent first.
  Stream<List<Map<String, dynamic>>> chatListStream(String currentUserId) {
    return _db
        .collection(Collections.chats)
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'chatId': d.id, ...d.data()}).toList());
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String type = MessageType.text,
  }) async {
    final chatId = buildChatId(senderId, receiverId);
    final chatRef = _db.collection(Collections.chats).doc(chatId);

    final message = MessageModel(
      messageId: '',
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      type: type,
      timestamp: DateTime.now(),
    );

    final batch = _db.batch();

    // Ensure the parent chat doc exists / stays up to date
    batch.set(chatRef, {
      'participants': [senderId, receiverId],
      'lastMessage': type == MessageType.text ? text : '📎 Attachment',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final msgRef = chatRef.collection(Collections.messages).doc();
    batch.set(msgRef, message.toMap());

    await batch.commit();
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final unread = await _db
        .collection(Collections.chats)
        .doc(chatId)
        .collection(Collections.messages)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Simple prefix search on name. For production-scale search,
  /// swap this for Algolia / Typesense.
  Future<List<UserModel>> searchUsers(String query, String excludeUserId) async {
    if (query.trim().isEmpty) return [];
    final snap = await _db
        .collection(Collections.users)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();

    return snap.docs
        .where((d) => d.id != excludeUserId)
        .map((d) => UserModel.fromDoc(d))
        .toList();
  }

  Stream<UserModel> userStream(String userId) {
    return _db
        .collection(Collections.users)
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromDoc(doc));
  }
}
