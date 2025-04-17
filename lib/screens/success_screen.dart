import 'package:flutter/material.dart';
import 'package:flutter_try02/navigation/app_routes.dart'; // Import AppRoutes

class SuccessScreen extends StatelessWidget {
  final String successMessage; // Custom success message
  final String redirectRoute; // Route to redirect to after delay
  final int delayInSeconds; // Custom delay before redirection

  const SuccessScreen({
    super.key,
    required this.successMessage,
    required this.redirectRoute,
    this.delayInSeconds = 2, // Default delay is 2 seconds
  });

  @override
  Widget build(BuildContext context) {
    // Navigate to the specified route after the delay
    Future.delayed(Duration(seconds: delayInSeconds), () {
      Navigator.pushReplacementNamed(context, redirectRoute);
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              successMessage, // Display the custom success message
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Redirecting...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ), // Loading indicator
          ],
        ),
      ),
    );
  }
}