import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../navigation/app_routes.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isEmailVerified = false;

  Future<void> _checkEmailVerification() async {
    // Reload the user to get the latest email verification status
    await _auth.currentUser?.reload();

    // Check if the email is verified
    setState(() {
      _isEmailVerified = _auth.currentUser?.emailVerified ?? false;
    });

    if (_isEmailVerified) {
      // Navigate to the home screen or dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  void initState() {
    super.initState();
    // Check email verification status when the screen loads
    _checkEmailVerification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'A verification email has been sent to your email address.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (!_isEmailVerified)
              ElevatedButton(
                onPressed: _checkEmailVerification,
                child: const Text('Check Verification Status'),
              ),
            if (_isEmailVerified)
              const Text(
                'Email verified! You can now proceed to the app.',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}