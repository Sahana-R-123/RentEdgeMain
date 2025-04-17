import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';



class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  final String chatType;
  final String? productId;
  final String? productName;
  final String? productImage;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
    required this.chatType,
    this.productId,
    this.productName,
    this.productImage,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String currentUserId;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  late StreamSubscription _typingSubscription;
  late StreamSubscription _presenceSubscription;
  bool _isReceiverOnline = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _setupTypingListener();
    _setupPresenceListener();
    _updateUserPresence(true);
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingSubscription.cancel();
    _presenceSubscription.cancel();
    _updateUserPresence(false);
    super.dispose();
  }

  void _setupTypingListener() {
    _typingSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(_getChatId())
        .collection('typing')
        .doc(widget.receiverId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _otherUserTyping = snapshot.exists && snapshot['typing'] == true;
        });
      }
    });
  }

  void _setupPresenceListener() {
    _presenceSubscription = FirebaseFirestore.instance
        .collection('presence')
        .doc(widget.receiverId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _isReceiverOnline = snapshot.exists && snapshot['online'] == true;
        });
      }
    });
  }

  Future<void> _updateUserPresence(bool online) async {
    await FirebaseFirestore.instance
        .collection('presence')
        .doc(currentUserId)
        .set({
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _updateTypingStatus(bool typing) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_getChatId())
        .collection('typing')
        .doc(currentUserId)
        .set({'typing': typing});
  }

  String _getChatId() {
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort();
    return ids.join('_');
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    // Update typing status to false
    _updateTypingStatus(false);

    try {
      final messageData = {
        'senderId': currentUserId,
        'receiverId': widget.receiverId,
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'text',
      };

      // Add to both users' chat collections for easier querying
      final batch = FirebaseFirestore.instance.batch();

      // Add to sender's chat collection
      final senderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(widget.receiverId)
          .collection('messages')
          .doc();

      // Add to receiver's chat collection
      final receiverRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .collection('chats')
          .doc(currentUserId)
          .collection('messages')
          .doc(senderRef.id);

      batch.set(senderRef, messageData);
      batch.set(receiverRef, messageData);

      // Update last message in chat metadata
      final chatMetadataRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(_getChatId());

      batch.set(chatMetadataRef, {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [currentUserId, widget.receiverId],
        'type': widget.chatType,
        if (widget.productId != null) 'productId': widget.productId,
        if (widget.productName != null) 'productName': widget.productName,
        if (widget.productImage != null) 'productImage': widget.productImage,
      }, SetOptions(merge: true));

      await batch.commit();

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

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

  Future<void> _markMessagesAsRead() async {
    try {
      final unreadMessages = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('chats')
          .doc(widget.receiverId)
          .collection('messages')
          .where('senderId', isEqualTo: widget.receiverId)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Widget _buildProductInfoCard() {
    if (widget.productId == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (widget.productImage != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(widget.productImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re chatting about:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    widget.productName ?? 'Product',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(widget.receiverImage),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverName),
                Text(
                  _isReceiverOnline ? 'Online' : 'Offline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _isReceiverOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Add additional options here
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProductInfoCard(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .collection('chats')
                  .doc(widget.receiverId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No messages yet'),
                        const SizedBox(height: 8),
                        Text(
                          'Start chatting with ${widget.receiverName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                // Scroll to bottom when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUserId;
                    return _buildMessageBubble(
                      text: msg['message'],
                      isMe: isMe,
                      time: msg['timestamp']?.toDate(),
                      isRead: msg['read'] ?? false,
                    );
                  },
                );
              },
            ),
          ),
          if (_otherUserTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.receiverName} is typing...',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (text) {
                      if (text.trim().isNotEmpty) {
                        if (!_isTyping) {
                          _isTyping = true;
                          _updateTypingStatus(true);
                        }
                      } else {
                        if (_isTyping) {
                          _isTyping = false;
                          _updateTypingStatus(false);
                        }
                      }
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    DateTime? time,
    required bool isRead,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe
                      ? const Radius.circular(12)
                      : const Radius.circular(0),
                  bottomRight: isMe
                      ? const Radius.circular(0)
                      : const Radius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (time != null)
                    Text(
                      DateFormat.jm().format(time),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  if (isMe) const SizedBox(width: 4),
                  if (isMe)
                    Icon(
                      isRead ? Icons.done_all : Icons.done,
                      size: 16,
                      color: isRead ? Colors.blue : Colors.grey,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}