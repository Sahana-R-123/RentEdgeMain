import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try02/widgets/chat_list_item.dart';
import 'package:flutter_try02/navigation/app_routes.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Chats"),
        ),
        body: _ChatListWithFilter(
          filter: ChatFilter.all,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}

enum ChatFilter { all, buying, selling }

class _ChatListWithFilter extends StatelessWidget {
  final ChatFilter filter;
  final String currentUserId;

  const _ChatListWithFilter({
    required this.filter,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No chats available'));
        }

        final chats = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final chatData = chat.data() as Map<String, dynamic>;
            final participants = List<String>.from(chatData['participants']);
            final receiverId = participants.firstWhere((id) => id != currentUserId);
            final chatType = chatData.containsKey('type') ? chatData['type'] : 'all';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(receiverId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text('Loading...'));
                }

                final user = userSnapshot.data!;
                final userData = user.data() as Map<String, dynamic>;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('presence')
                      .doc(receiverId)
                      .snapshots(),
                  builder: (context, presenceSnapshot) {
                    final presenceDoc = presenceSnapshot.data;
                    final isOnline = presenceDoc?.exists == true
                        ? (presenceDoc?['online'] ?? false)
                        : false;

                    final imagePath = userData.containsKey('photoUrl') && userData['photoUrl'] != null
                        ? userData['photoUrl']
                        : 'assets/default.jpg';

                    final receiverName = userData['firstName'] ?? 'User';

                    return ChatListItem(
                      imagePath: imagePath,
                      title: receiverName,
                      subtitle: chatData['lastMessage'] ?? 'No messages yet',
                      trailingText: _formatTime(chatData['lastMessageTime']?.toDate()),
                      isOnline: isOnline,
                      unreadCount: 0,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.chatDetail,
                          arguments: {
                            'currentUserId': currentUserId,
                            'receiverId': receiverId,
                            'receiverName': receiverName,
                            'receiverImage': imagePath,
                            'chatType': chatType,
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    if (now.difference(time).inDays < 1) {
      return DateFormat.Hm().format(time);
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.E().format(time);
    } else {
      return DateFormat.yMd().format(time);
    }
  }
}
