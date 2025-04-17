import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added this import
import '../../providers/user_provider.dart';

class SellProductScreen extends StatefulWidget {
  final String? initialCategory;

  const SellProductScreen({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCategory;
  Map<String, TextEditingController> _controllers = {};
  List<File> _images = [];
  bool _isSubmitting = false;

  Position? _currentPosition;
  final picker = ImagePicker();

  // Define all possible categories here
  static const List<String> _availableCategories = [
    'Cycle',
    'Accessories',
    'Electronics',
    'Books',
    'Stationery',
    'Games',
    'Calculator',
    'Laptop',
    'Watch',
    'Lab Coat',
    'Shoes',
  ];

  final Map<String, List<Map<String, String>>> _categoryFields = {
    'Cycle': [
      {'label': 'Cycle Type', 'key': 'type'},
      {'label': 'Gear Count', 'key': 'gear'},
    ],
    'Accessories': [
      {'label': 'Accessory Type', 'key': 'type'},
      {'label': 'Brand', 'key': 'brand'},
    ],
    'Electronics': [
      {'label': 'Device Type', 'key': 'deviceType'},
      {'label': 'Specifications', 'key': 'specs'},
    ],
    'Books': [
      {'label': 'Book Title', 'key': 'bookTitle'},
      {'label': 'Author', 'key': 'author'},
    ],
    'Stationery': [
      {'label': 'Stationery Type', 'key': 'type'},
      {'label': 'Brand', 'key': 'brand'},
    ],
    'Games': [
      {'label': 'Game Name', 'key': 'gameName'},
      {'label': 'Platform', 'key': 'platform'},
    ],
    'Calculator': [
      {'label': 'Calculator Type', 'key': 'type'},
      {'label': 'Brand', 'key': 'brand'},
    ],
    'Laptop': [
      {'label': 'Brand', 'key': 'brand'},
      {'label': 'Model', 'key': 'model'},
      {'label': 'Specifications', 'key': 'specs'},
    ],
    'Watch': [
      {'label': 'Watch Type', 'key': 'type'},
      {'label': 'Brand', 'key': 'brand'},
    ],
    'Lab Coat': [
      {'label': 'Size', 'key': 'size'},
      {'label': 'Condition', 'key': 'condition'},
    ],
    'Shoes': [
      {'label': 'Shoe Type', 'key': 'type'},
      {'label': 'Size', 'key': 'size'},
      {'label': 'Brand', 'key': 'brand'},
    ],
  };

  @override
  void initState() {
    super.initState();
    // Ensure initial category is valid or default to first available category
    _selectedCategory = widget.initialCategory != null &&
        _availableCategories.contains(widget.initialCategory)
        ? widget.initialCategory!
        : _availableCategories.first;
    _initializeAllControllers();
  }

  void _initializeAllControllers() {
    // Initialize core fields
    _controllers['title'] = TextEditingController();
    _controllers['description'] = TextEditingController();
    _controllers['price'] = TextEditingController();

    // Initialize all category-specific fields
    for (var fields in _categoryFields.values) {
      for (var field in fields) {
        _controllers[field['key']!] = TextEditingController();
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && _images.length < 5) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    } else if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
        return;
      } else if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = position;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location acquired: ${position.latitude}, ${position.longitude}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image.')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get your current location.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // Validate price is a valid number
    final priceText = _controllers['price']?.text.trim() ?? '';
    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Convert images to base64
      List<String> imageBase64 = [];
      for (var image in _images) {
        final bytes = await image.readAsBytes();
        imageBase64.add(base64Encode(bytes));
      }

      // Prepare form data
      Map<String, dynamic> formData = {
        'title': _controllers['title']?.text.trim() ?? '',
        'description': _controllers['description']?.text.trim() ?? '',
        'price': price, // Already parsed as double
        'category': _selectedCategory,
        'images': imageBase64,
        'location': GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        'timestamp': FieldValue.serverTimestamp(),
        'sellerId': user.uid,
        'sellerName': user.displayName ?? 'Anonymous',
        'sellerEmail': user.email ?? '',
      };

      // Add category-specific fields
      for (var field in _categoryFields[_selectedCategory]!) {
        final value = _controllers[field['key']!]?.text.trim();
        if (value != null && value.isNotEmpty) {
          formData[field['key']!] = value;
        }
      }

      await FirebaseFirestore.instance.collection('products').add(formData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product listed successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
      debugPrint('Error details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = _categoryFields[_selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Product'),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _availableCategories
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controllers['title'],
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controllers['description'],
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controllers['price'],
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              ...fields.map((field) => Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: _controllers[field['key']!],
                  decoration: InputDecoration(
                    labelText: field['label'],
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter ${field['label']}'
                      : null,
                ),
              )),
              const SizedBox(height: 16),
              const Text(
                'Product Images (max 5)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.asMap().entries.map((entry) {
                    final index = entry.key;
                    final image = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(image),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  if (_images.length < 5)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 30),
                            Text('Add Image'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('Get Current Location'),
                onPressed: _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_currentPosition != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                        '${_currentPosition!.longitude.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Submit Listing',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}