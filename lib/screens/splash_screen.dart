import 'package:flutter/material.dart';
import 'package:flutter_try02/navigation/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with subtle shadow
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Image.asset(
                'assets/images/sample.jpg',
                width: 120,
                height: 120,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.home,
                  size: 80,
                  color: Color(0xFF6A11CB),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App name with clean typography
            const Text(
              'RentEdge',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),
            // Minimal loading indicator
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Color(0xFFEEEEEE),
                  valueColor: AlwaysStoppedAnimation(Color(0xFF6A11CB)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}