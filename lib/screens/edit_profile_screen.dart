import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_try02/providers/user_provider.dart';
import 'package:flutter_try02/models/user_model.dart';

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
  File? _profileImage;

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
    _profileImage = user?.profileImage;
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
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
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
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                  child: _profileImage == null
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
                  child: const Text('Save Profile'),
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

  void _saveProfile() {
    if (_formKey.currentState!.validate() && _profileImage != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          department: _departmentController.text,
          college: _collegeController.text,
          profileImage: _profileImage!,
        );

        userProvider.setUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } else if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile image')),
      );
    }
  }
}