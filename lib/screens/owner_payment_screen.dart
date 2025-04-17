import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_success_screen.dart';

class OwnerPaymentScreen extends StatefulWidget {
  final String requestId;
  final String productName;
  final double productPrice;
  final String? productImage;
  final String requesterId;
  final String sellerId;

  const OwnerPaymentScreen({
    required this.requestId,
    required this.productName,
    required this.productPrice,
    this.productImage,
    required this.requesterId,
    required this.sellerId,
    super.key,
  });

  @override
  _OwnerPaymentScreenState createState() => _OwnerPaymentScreenState();
}

class _OwnerPaymentScreenState extends State<OwnerPaymentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _paymentReceived = false;

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {'firstName': 'Unknown User', 'email': ''};
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return {'firstName': 'Unknown User', 'email': ''};
    }
  }

  Future<void> _completeTransaction() async {
    try {
      await _firestore.collection('requests').doc(widget.requestId).update({
        'status': 'completed',
        'paymentReceived': true,
        'completionDate': FieldValue.serverTimestamp(),
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionSuccessScreen(
            isOwner: true,
            productName: widget.productName,
            productPrice: widget.productPrice,
          ),
        ),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payment Receipt'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          _getUserData(widget.requesterId),
          _getUserData(widget.sellerId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requesterData = snapshot.data?[0] as Map<String, dynamic>;
          final sellerData = snapshot.data?[1] as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: widget.productImage != null
                      ? Image.network(
                    widget.productImage!,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.image, size: 200),
                ),
                const SizedBox(height: 20),
                Text(widget.productName,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text('₹${widget.productPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge),
                const Divider(height: 30),
                Text('Buyer: ${requesterData['firstName']}',
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 10),
                Text('Seller: ${sellerData['firstName']}',
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 30),
                const Text('Have you received the payment?',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('Yes, I have received the payment'),
                  value: _paymentReceived,
                  onChanged: (value) {
                    setState(() {
                      _paymentReceived = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Complete Transaction'),
                  onPressed: _paymentReceived ? _completeTransaction : null,
                  style: ElevatedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
