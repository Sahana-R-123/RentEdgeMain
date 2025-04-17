import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'transaction_success_screen.dart';
import 'payment_method_card.dart';

class RequesterPaymentScreen extends StatefulWidget {
  final String requestId;
  final String productName;
  final double productPrice;
  final String? productImage;
  final String requesterId;
  final String sellerId;

  const RequesterPaymentScreen({
    required this.requestId,
    required this.productName,
    required this.productPrice,
    this.productImage,
    required this.requesterId,
    required this.sellerId,
    super.key,
  });

  @override
  _RequesterPaymentScreenState createState() => _RequesterPaymentScreenState();
}

class _RequesterPaymentScreenState extends State<RequesterPaymentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedPaymentMethod = '';
  bool _cashSelected = false;

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {'firstName': 'Unknown User', 'email': ''};
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return {'firstName': 'Unknown User', 'email': ''};
    }
  }

  Future<void> _launchPaymentIntent(String app) async {
    String url = '';
    String packageName = '';

    switch (app) {
      case 'gpay':
        url =
        'upi://pay?pa=your-upi-id@bank&pn=RentEdge&mc=0000&tn=Payment for ${widget.productName}&am=${widget.productPrice}&cu=INR';
        packageName = 'com.google.android.apps.nbu.paisa.user';
        break;
      case 'paytm':
        url =
        'upi://pay?pa=your-upi-id@paytm&pn=RentEdge&mc=0000&tn=Payment for ${widget.productName}&am=${widget.productPrice}&cu=INR';
        packageName = 'net.one97.paytm';
        break;
    }

    final intent = AndroidIntent(
      action: 'action_view',
      data: url,
      package: packageName,
    );

    try {
      await intent.launch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch $app: $e")),
      );
    }
  }

  Future<void> _completePayment() async {
    try {
      await _firestore.collection('requests').doc(widget.requestId).update({
        'paymentMethod': _selectedPaymentMethod,
        'paymentCompleted': true,
        'paymentDate': FieldValue.serverTimestamp(),
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionSuccessScreen(
            isOwner: false,
            productName: widget.productName,
            productPrice: widget.productPrice,
          ),
        ),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
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
                const Text('Select Payment Method:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                PaymentMethodCard(
                  icon: Icons.account_balance_wallet,
                  title: 'GPay',
                  isSelected: _selectedPaymentMethod == 'gpay',
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 'gpay';
                      _cashSelected = false;
                    });
                    _launchPaymentIntent('gpay');
                  },
                ),
                PaymentMethodCard(
                  icon: Icons.mobile_friendly,
                  title: 'PayTM',
                  isSelected: _selectedPaymentMethod == 'paytm',
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 'paytm';
                      _cashSelected = false;
                    });
                    _launchPaymentIntent('paytm');
                  },
                ),
                PaymentMethodCard(
                  icon: Icons.money,
                  title: 'Cash',
                  isSelected: _cashSelected,
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 'cash';
                      _cashSelected = true;
                    });
                  },
                ),
                if (_cashSelected)
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text('Please pay the amount directly to the seller',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        title: const Text('I have paid the amount in cash'),
                        value: _cashSelected,
                        onChanged: (value) {
                          setState(() {
                            _cashSelected = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: (_selectedPaymentMethod.isNotEmpty &&
                      (_selectedPaymentMethod != 'cash' || _cashSelected))
                      ? _completePayment
                      : null,
                  child: const Text('Complete Payment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
