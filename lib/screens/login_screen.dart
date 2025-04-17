import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:flutter_try02/navigation/app_routes.dart';
import 'package:flutter_try02/providers/user_provider.dart';
import 'package:flutter_try02/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Firebase Auth Sign In
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        // Step 2: Fetch user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
         // final userModel = UserModel.fromMap(userData);
          final userModel = AppUser.fromMap(userData);

          // Step 3: Set user data in Provider
          Provider.of<UserProvider>(context, listen: false).setUser(userModel);

          // Step 4: Navigate to Dashboard
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        } else {
          throw FirebaseAuthException(
              code: 'user-data-missing',
              message: 'User data not found in Firestore.');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Sign In to Continue',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || !value.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 10),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) =>
                  value == null || value.length < 6 ? 'Enter a valid password' : null,
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Add reset password navigation or logic here
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign In'),
                ),

                const SizedBox(height: 10),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.signup);
                    },
                    child: const Text(
                      'Don\'t have an account? Create new account',
                      style: TextStyle(color: Colors.purple),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
