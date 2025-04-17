import 'package:flutter/material.dart';
import 'dashboard_screen.dart'; // Make sure you have this screen

class TransactionSuccessScreen extends StatelessWidget {
  final bool isOwner;
  final String productName;
  final double productPrice;

  const TransactionSuccessScreen({
    required this.isOwner,
    required this.productName,
    required this.productPrice,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Complete'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              Text('Payment Successful!',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 30),
              Text('Product: $productName',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text('Amount: ₹${productPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 30),
              Text(
                  isOwner
                      ? 'You have confirmed receiving the payment.'
                      : 'Your payment has been completed successfully.',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        (route) => false,
                  );
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}