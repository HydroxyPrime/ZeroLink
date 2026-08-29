import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';
import '../widgets/user_tile.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _searching = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final results = await _chatService.searchUsers(query.trim(), _uid);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ZeroLink', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searching) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No people found', style: TextStyle(color: AppColors.textLight)));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, i) {
        final user = _searchResults[i];
        return UserTile(
          user: user,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
          ),
        );
      },
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.chatListStream(_uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final chats = snapshot.data!;
        if (chats.isEmpty) {
          return const Center(
            child: Text('Search for someone to start chatting', style: TextStyle(color: AppColors.textLight)),
          );
        }
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, i) {
            final chat = chats[i];
            final participants = List<String>.from(chat['participants'] ?? []);
            final otherId = participants.firstWhere((id) => id != _uid, orElse: () => '');
            if (otherId.isEmpty) return const SizedBox.shrink();

            return StreamBuilder<UserModel>(
              stream: _chatService.userStream(otherId),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox.shrink();
                final user = userSnap.data!;
                final updatedAt = chat['updatedAt'];
                final timeStr = updatedAt != null
                    ? DateFormat('h:mm a').format(updatedAt.toDate())
                    : '';
                return ListTile(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                    child: user.photoUrl.isEmpty
                        ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                        : null,
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(chat['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(timeStr, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                );
              },
            );
          },
        );
      },
    );
  }
}
