import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

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
  List<String> _uploadedImageUrls = [];
  bool _isSubmitting = false;
  Position? _currentPosition;
  final picker = ImagePicker();

  static const List<String> _availableCategories = [
    'Cycle', 'Accessories', 'Electronics', 'Books', 'Stationery', 'Games',
    'Calculator', 'Laptop', 'Watch', 'Lab Coat', 'Shoes',
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
    _selectedCategory = widget.initialCategory != null && _availableCategories.contains(widget.initialCategory!)
        ? widget.initialCategory!
        : _availableCategories.first;
    _initializeAllControllers();
  }

  void _initializeAllControllers() {
    _controllers['title'] = TextEditingController();
    _controllers['description'] = TextEditingController();
    _controllers['price'] = TextEditingController();

    for (var fields in _categoryFields.values) {
      for (var field in fields) {
        _controllers[field['key']!] = TextEditingController();
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && _uploadedImageUrls.length < 5) {
      final url = await _uploadImageToImgbb(File(pickedFile.path));
      if (url != null) {
        setState(() {
          _uploadedImageUrls.add(url);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image.')),
        );
      }
    } else if (_uploadedImageUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
    }
  }

  Future<String?> _uploadImageToImgbb(File imageFile) async {
    final apiKey = 'f2cbde2f326712f0ac36f47a7a6efa3a';
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(uri, body: {
      'image': base64Image,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['url'];
    } else {
      debugPrint('Image upload failed: ${response.body}');
      return null;
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image.')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fetch your location.')),
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
      Map<String, dynamic> formData = {
        'title': _controllers['title']?.text.trim(),
        'description': _controllers['description']?.text.trim(),
        'price': price,
        'category': _selectedCategory,
        'images': _uploadedImageUrls,
        'location': GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'sellerId': user.uid,
        'sellerName': user.displayName ?? 'Anonymous',
        'sellerEmail': user.email ?? '',
      };

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
      debugPrint('Error submitting form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
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
      appBar: AppBar(title: const Text('Sell Product')),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _availableCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controllers['title'],
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controllers['description'],
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controllers['price'],
                decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ ', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Enter a valid price' : null,
              ),
              ...fields.map((field) => Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: _controllers[field['key']!],
                  decoration: InputDecoration(labelText: field['label'], border: const OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? 'Enter ${field['label']}' : null,
                ),
              )),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._uploadedImageUrls.asMap().entries.map((entry) => Stack(
                    children: [
                      Image.network(entry.value, width: 100, height: 100, fit: BoxFit.cover),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(entry.key),
                          child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      )
                    ],
                  )),
                  if (_uploadedImageUrls.length < 5)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_a_photo, size: 30),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('Get Current Location'),
                onPressed: _getCurrentLocation,
              ),
              if (_currentPosition != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit Listing', style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
