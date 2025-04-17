import 'package:flutter/material.dart';
import 'package:flutter_try02/models/product_model.dart';
import 'package:flutter_try02/screens/seller_profile_screen.dart';
import 'package:flutter_try02/navigation/app_routes.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({required this.product, super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String sellerName = '';
  String sellerId = '';
  bool isLoadingSeller = true;

  @override
  void initState() {
    super.initState();
    sellerId = widget.product.sellerId;
    _fetchSellerName();
  }

  Future<void> _fetchSellerName() async {
    if (sellerId.isEmpty) {
      debugPrint('Error: sellerId is empty!');
      setState(() {
        sellerName = 'Unknown Seller';
        isLoadingSeller = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
      if (doc.exists) {
        setState(() {
          sellerName = doc['firstName'] ?? 'Unknown Seller';
          isLoadingSeller = false;
        });
      } else {
        setState(() {
          sellerName = 'Unknown Seller';
          isLoadingSeller = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller info: $e');
      setState(() {
        sellerName = 'Unknown Seller';
        isLoadingSeller = false;
      });
    }
  }

  Future<void> _launchMapsUrl(Uri url) async {
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch maps')),
        );
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening maps')),
      );
    }
  }

  void _openLocation() async {
    if (widget.product.location.isEmpty ||
        widget.product.location == 'Unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    if (widget.product.location.contains(',')) {
      final coords = widget.product.location.split(',');
      if (coords.length == 2) {
        try {
          final lat = double.parse(coords[0].trim());
          final lng = double.parse(coords[1].trim());
          final url = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
          );
          await _launchMapsUrl(url);
          return;
        } catch (e) {
          debugPrint('Error parsing coordinates: $e');
        }
      }
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.product.location)}',
    );
    await _launchMapsUrl(url);
  }

  void _navigateToChat(BuildContext context) async {
    if (sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller information not available')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    DocumentSnapshot? existingChat;
    for (var doc in chatQuery.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(sellerId)) {
        existingChat = doc;
        break;
      }
    }

    if (existingChat == null) {
      final newChatRef = await FirebaseFirestore.instance.collection('chats').add({
        'participants': [currentUser.uid, sellerId],
        'lastMessage': 'Started chat about ${widget.product.title}',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'type': 'buying',
        'productId': widget.product.id,
        'productName': widget.product.title,
        'productImage': widget.product.images.isNotEmpty ? widget.product.images[0] : null,
      });
      existingChat = await newChatRef.get();
    }

    Navigator.pushNamed(
      context,
      AppRoutes.chatDetail,
      arguments: {
        'currentUserId': currentUser.uid,
        'receiverId': sellerId,
        'receiverName': sellerName,
        'receiverImage': 'assets/default.jpg',
        'chatType': 'buying',
        'productId': widget.product.id,
        'productName': widget.product.title,
        'productImage': widget.product.images.isNotEmpty ? widget.product.images[0] : null,
      },
    );
  }

  void _navigateToSellerProfile(BuildContext context) {
    if (sellerId.isEmpty) {
      debugPrint('Error: sellerId is empty when trying to navigate!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller profile unavailable')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellerProfileScreen(sellerId: sellerId),
      ),
    );
  }

  Future<void> _requestProduct(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to request products')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Product'),
        content: const Text('Are you sure you want to request this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('requests').add({
                  'productId': widget.product.id,
                  'productName': widget.product.title,
                  'productImage': widget.product.images.isNotEmpty
                      ? widget.product.images[0]
                      : null,
                  'productPrice': widget.product.price,
                  'requesterId': currentUser.uid,
                  'sellerId': sellerId,
                  'status': 'pending',
                  'requestDate': FieldValue.serverTimestamp(),
                  'lastUpdated': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product request sent successfully!')),
                );
              } catch (e) {
                debugPrint('Error sending request: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to send request')),
                );
              }
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.images.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: product.images.length,
                  itemBuilder: (context, index) {
                    final imagePath = product.images[index];
                    Widget imageWidget;

                    if (imagePath.startsWith('data:image')) {
                      imageWidget = Image.memory(
                        base64Decode(imagePath.split(',').last),
                        width: 300,
                        fit: BoxFit.cover,
                      );
                    } else if (Uri.tryParse(imagePath)?.isAbsolute == true) {
                      imageWidget = Image.network(
                        imagePath,
                        width: 300,
                        fit: BoxFit.cover,
                      );
                    } else {
                      imageWidget = Image.asset(
                        'assets/placeholder.png',
                        width: 300,
                        fit: BoxFit.cover,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageWidget,
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),

            const SizedBox(height: 16),
            Text(product.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('₹${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: Colors.green)),
            const SizedBox(height: 16),
            Text(product.details['description'] ?? 'No description available',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _openLocation,
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      product.location != 'Unknown'
                          ? 'View on Google Maps'
                          : 'Location not specified',
                      style: TextStyle(
                        fontSize: 16,
                        color: product.location != 'Unknown'
                            ? Colors.blue
                            : Colors.grey,
                        decoration: product.location != 'Unknown'
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            if (product.categoryDetails.isNotEmpty) ...[
              const Text('Product Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...product.categoryDetails.entries.map(
                    (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('${entry.key}: ${entry.value ?? 'Not specified'}',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const Text('Seller Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            isLoadingSeller
                ? const CircularProgressIndicator()
                : Text(sellerName, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _navigateToSellerProfile(context),
              child: const Text('View Profile', style: TextStyle(fontSize: 14, color: Colors.blue)),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _navigateToChat(context),
                    child: const Text('Chat with Seller'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _requestProduct(context),
                    child: const Text('Request Product'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
