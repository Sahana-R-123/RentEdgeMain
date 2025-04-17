import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'owner_payment_screen.dart';
import 'requester_payment_screen.dart';

class RequestListItem extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;
  final bool isIncoming;
  final String currentUserId;
  final VoidCallback? onAcceptedRequestTap;

  const RequestListItem({
    required this.requestId,
    required this.data,
    required this.isIncoming,
    required this.currentUserId,
    this.onAcceptedRequestTap,
    super.key,
  });

  Future<void> _updateRequestStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating request: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data() ?? {'firstName': 'Unknown User', 'email': ''};
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return {'firstName': 'Unknown User', 'email': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = data['requestDate'] as Timestamp?;
    final date = timestamp != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate())
        : 'Unknown date';

    final otherUserId = isIncoming ? data['requesterId'] : data['sellerId'];

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(otherUserId),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data ?? {'firstName': 'Loading...'};

        return Dismissible(
          key: Key(requestId),
          direction: isIncoming && data['status'] == 'pending'
              ? DismissDirection.horizontal
              : DismissDirection.none,
          confirmDismiss: (direction) async {
            try {
              if (direction == DismissDirection.endToStart) {
                await _updateRequestStatus('rejected');
                return true;
              } else if (direction == DismissDirection.startToEnd) {
                await _updateRequestStatus('accepted');
                return true;
              }
              return false;
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update: ${e.toString()}')),
              );
              return false;
            }
          },
          onDismissed: (direction) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Request ${direction == DismissDirection.startToEnd ? 'accepted' : 'rejected'}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          background: Container(
            color: Colors.green,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.close, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: InkWell(
              onTap: data['status'] == 'accepted' && onAcceptedRequestTap != null
                  ? onAcceptedRequestTap
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    data['productImage'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                title: Text(data['productName'] ?? 'Unknown Product'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${data['productPrice']?.toStringAsFixed(2) ?? '0.00'}'),
                    Text('Status: ${data['status'] ?? 'pending'}'),
                    Text(isIncoming
                        ? 'From: ${userData['firstName'] ?? 'Unknown User'}'
                        : 'To: ${userData['firstName'] ?? 'Unknown User'}'),
                    Text(date),
                  ],
                ),
                trailing: isIncoming && data['status'] == 'pending'
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await _updateRequestStatus('accepted');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request accepted')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await _updateRequestStatus('rejected');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request rejected')),
                        );
                      },
                    ),
                  ],
                )
                    : _getStatusIcon(data['status']),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _getStatusIcon(String? status) {
    switch (status) {
      case 'accepted':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'rejected':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.access_time, color: Colors.orange);
    }
  }
}