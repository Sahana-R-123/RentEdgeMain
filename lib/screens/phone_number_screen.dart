import 'package:flutter/material.dart';
import 'package:flutter_try02/navigation/app_routes.dart';

class PhoneNumberScreen extends StatelessWidget {
  const PhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter your Phone Number',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.otp);
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}