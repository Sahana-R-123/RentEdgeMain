import 'dart:io'; // Add this import for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'package:flutter_try02/providers/user_provider.dart';
import 'package:flutter_try02/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _registeredIdController;
  late TextEditingController _departmentController;
  late TextEditingController _collegeController;
  String? _profileImageUrl;
  File? _newProfileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;

    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _registeredIdController = TextEditingController(text: user?.registeredId ?? '');
    _departmentController = TextEditingController(text: user?.department ?? '');
    _collegeController = TextEditingController(text: user?.college ?? '');
    _profileImageUrl = user?.profileImage;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _registeredIdController.dispose();
    _departmentController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
        ],
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<String?> _uploadImageToImgBB(File imageFile) async {
    try {
      const apiKey = 'f2cbde2f326712f0ac36f47a7a6efa3a'; // Replace with your actual ImgBB API key
      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromBytes(
        'image',
        await imageFile.readAsBytes(),
        contentType: MediaType('image', 'jpeg'),
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (jsonData['success'] == true) {
        return jsonData['data']['url'];
      } else {
        throw Exception('Failed to upload image to ImgBB');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile image')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _newProfileImage != null
                      ? FileImage(_newProfileImage!)
                      : _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                  child: _newProfileImage == null && _profileImageUrl == null
                      ? const Icon(Icons.add_a_photo, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Read-only fields
              _buildReadOnlyField(_registeredIdController, 'Registered ID'),
              const SizedBox(height: 16),
              _buildReadOnlyField(_emailController, 'Email'),
              const SizedBox(height: 16),

              // Editable fields
              Row(
                children: [
                  Expanded(child: _buildEditableField(_firstNameController, 'First Name')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildEditableField(_lastNameController, 'Last Name')),
                ],
              ),
              const SizedBox(height: 16),
              _buildEditableField(_departmentController, 'Department'),
              const SizedBox(height: 16),
              _buildEditableField(_collegeController, 'College'),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      readOnly: true,
      style: TextStyle(color: Colors.grey[600]),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      if (currentUser != null) {
        String? updatedImageUrl = _profileImageUrl;

        // Upload new image if selected
        if (_newProfileImage != null) {
          updatedImageUrl = await _uploadImageToImgBB(_newProfileImage!);
          if (updatedImageUrl == null) {
            // If upload fails, keep the old image
            updatedImageUrl = _profileImageUrl;
          }
        }

        final updatedUser = AppUser(
          id: currentUser.id,
          registeredId: currentUser.registeredId,
          department: _departmentController.text,
          college: _collegeController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: currentUser.email,
          profileImage: updatedImageUrl,
        );

        // Update in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.id)
            .update({
          'firstName': updatedUser.firstName,
          'lastName': updatedUser.lastName,
          'department': updatedUser.department,
          'college': updatedUser.college,
          'profileImageUrl': updatedUser.profileImage,
        });

        userProvider.setUser(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}