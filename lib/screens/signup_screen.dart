import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_try02/navigation/app_routes.dart';
import 'package:flutter_try02/providers/user_provider.dart';
import 'package:flutter_try02/models/user_model.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  final TextEditingController _registeredIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final option = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Upload Profile Image"),
        content: const Text("Choose an option"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text("Gallery")),
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text("Camera")),
        ],
      ),
    );

    if (option != null) {
      final pickedImage = await picker.pickImage(source: option);
      if (pickedImage != null) {
        setState(() => _profileImage = File(pickedImage.path));
      }
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Send verification email
      await authResult.user!.sendEmailVerification();

      // Save additional user data to Firestore
      final userData = {
        'registeredId': _registeredIdController.text.trim(),
        'department': _departmentController.text.trim(),
        'college': _collegeController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(authResult.user!.uid)
          .set(userData);

      final appUser = AppUser(
        registeredId: _registeredIdController.text,
        department: _departmentController.text,
        college: _collegeController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        profileImage: _profileImage,
      );

      Provider.of<UserProvider>(context, listen: false).setUser(appUser);

      Navigator.pushNamed(
        context,
        AppRoutes.success,
        arguments: {
          'successMessage': 'Sign-up successful! Verification email sent.',
          'redirectRoute': AppRoutes.login,
        },
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Something went wrong")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _registeredIdController.dispose();
    _departmentController.dispose();
    _collegeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null ? const Icon(Icons.add_a_photo, size: 40) : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Tap to upload profile image', style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 20),
            TextFormField(
              controller: _registeredIdController,
              decoration: const InputDecoration(labelText: '10-digit Registered ID'),
              keyboardType: TextInputType.number,
              maxLength: 10,
              validator: (value) {
                if (value == null || value.length != 10) {
                  return 'Registered ID must be exactly 10 digits';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(labelText: 'Department Name'),
              validator: (value) => value!.isEmpty ? 'Enter department name' : null,
            ),
            TextFormField(
              controller: _collegeController,
              decoration: const InputDecoration(labelText: 'College Name'),
              validator: (value) => value!.isEmpty ? 'Enter college name' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) => value!.isEmpty ? 'Enter first name' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) => value!.length < 6 ? 'Min 6 characters' : null,
            ),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
              validator: (value) =>
              value != _passwordController.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _signup,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Up'),
            ),
          ]),
        ),
      ),
    );
  }
}
