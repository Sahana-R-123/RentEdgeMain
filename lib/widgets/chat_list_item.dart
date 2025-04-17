import 'package:flutter/material.dart';

class ChatListItem extends StatelessWidget {
  final bool isOnline;
  final String imagePath;
  final String title;
  final String subtitle;
  final String trailingText;
  final VoidCallback onTap;
  final int unreadCount;

  const ChatListItem({
    required this.isOnline,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.onTap,
    this.unreadCount = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(imagePath),
          ),
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(trailingText, style: const TextStyle(fontSize: 12)),
          if (unreadCount > 0)
            const SizedBox(height: 4),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
