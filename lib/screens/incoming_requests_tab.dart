import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'request_list_item.dart';
import 'owner_payment_screen.dart';

class IncomingRequestsTab extends StatelessWidget {
  final String currentUserId;

  const IncomingRequestsTab({required this.currentUserId, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('sellerId', isEqualTo: currentUserId)
          .orderBy('requestDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No incoming requests', style: TextStyle(fontSize: 16)),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final request = snapshot.data!.docs[index];
            final data = request.data() as Map<String, dynamic>;

            if (data.isEmpty) return const SizedBox.shrink();

            return RequestListItem(
              requestId: request.id,
              data: data,
              isIncoming: true,
              currentUserId: currentUserId,
              onAcceptedRequestTap: data['status'] == 'accepted'
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OwnerPaymentScreen(
                      requestId: request.id,
                      productName: data['productName'] ?? 'Unknown Product',
                      productPrice: data['productPrice']?.toDouble() ?? 0.0,
                      productImage: data['productImage'],
                      requesterId: data['requesterId'],
                      sellerId: currentUserId,
                    ),
                  ),
                );
              }
                  : null,
            );
          },
        );
      },
    );
  }
}