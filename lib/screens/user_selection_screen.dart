import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User to Chat'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, isNotEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final data = userDoc.data();

              if (data == null || data is! Map<String, dynamic>) {
                return const SizedBox.shrink();
              }

              final firstName = data['firstName'] ?? 'User';
              final email = data['email'] ?? '';
              final photoUrl = data.containsKey('photoUrl') && data['photoUrl'] != null
                  ? data['photoUrl']
                  : 'https://via.placeholder.com/150';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(photoUrl),
                ),
                title: Text(firstName),
                subtitle: Text(email),
                onTap: () {
                  Navigator.pop(context, {
                    'uid': userDoc.id,
                    'firstName': firstName,
                    'photoUrl': photoUrl,
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
