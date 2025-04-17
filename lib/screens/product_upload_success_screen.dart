import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import 'your_listings_screen.dart';

class ProductUploadSuccessScreen extends StatelessWidget {
  const ProductUploadSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Successful'),
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Product is Live!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your item has been successfully listed on the marketplace.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Clear entire navigation stack and go to dashboard
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.dashboard,
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Optional: Add functionality to view the listing
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const YourListingsScreen()),
                  );
                },
                child: const Text('View your listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}