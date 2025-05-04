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
  bool _isRequestProcessing = false;
  bool _showRequestSent = false;

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
        sellerName = widget.product.sellerName.isNotEmpty
            ? widget.product.sellerName
            : 'Unknown Seller';
        isLoadingSeller = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
      if (doc.exists) {
        setState(() {
          sellerName = doc['firstName'] ?? widget.product.sellerName ?? 'Unknown Seller';
          isLoadingSeller = false;
        });
      } else {
        setState(() {
          sellerName = widget.product.sellerName.isNotEmpty
              ? widget.product.sellerName
              : 'Unknown Seller';
          isLoadingSeller = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seller info: $e');
      setState(() {
        sellerName = widget.product.sellerName.isNotEmpty
            ? widget.product.sellerName
            : 'Unknown Seller';
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

    setState(() {
      _isRequestProcessing = true;
    });

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

      setState(() {
        _showRequestSent = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showRequestSent = false;
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product request sent successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error sending request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send request')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequestProcessing = false;
        });
      }
    }
  }

  Widget _buildCategorySpecificDetails() {
    final product = widget.product;
    final category = product.category.toLowerCase();
    final details = <Widget>[];

    // Add general details first
    if (product.details.isNotEmpty) {
      details.addAll([
        const SizedBox(height: 16),
        const Text('Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...product.details.entries.map(
              (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('${entry.key}: ${entry.value ?? 'Not specified'}',
                style: const TextStyle(fontSize: 16)),
          ),
        ),
      ]);
    }

    // Category-specific fields
    if (category.contains('book') || product.author != null || product.bookTitle != null) {
      details.addAll([
        const SizedBox(height: 16),
        const Text('Book Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (product.bookTitle != null)
          _buildDetailRow('Title', product.bookTitle!),
        if (product.author != null)
          _buildDetailRow('Author', product.author!),
        if (product.condition != null)
          _buildDetailRow('Condition', product.condition!),
      ]);
    }
    else if (category.contains('clothing') || product.size != null || product.brand != null) {
      details.addAll([
        const SizedBox(height: 16),
        const Text('Clothing Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (product.brand != null)
          _buildDetailRow('Brand', product.brand!),
        if (product.size != null)
          _buildDetailRow('Size', product.size!),
        if (product.condition != null)
          _buildDetailRow('Condition', product.condition!),
      ]);
    }
    else if (category.contains('electronic') || product.brand != null || product.model != null) {
      details.addAll([
        const SizedBox(height: 16),
        const Text('Electronic Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (product.brand != null)
          _buildDetailRow('Brand', product.brand!),
        if (product.model != null)
          _buildDetailRow('Model', product.model!),
        if (product.specs != null)
          _buildDetailRow('Specifications', product.specs!),
        if (product.condition != null)
          _buildDetailRow('Condition', product.condition!),
      ]);
    }
    else if (category.contains('game') || product.gameName != null || product.platform != null) {
      details.addAll([
        const SizedBox(height: 16),
        const Text('Game Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (product.gameName != null)
          _buildDetailRow('Game', product.gameName!),
        if (product.platform != null)
          _buildDetailRow('Platform', product.platform!),
        if (product.condition != null)
          _buildDetailRow('Condition', product.condition!),
      ]);
    }

    // Add any remaining category-specific fields
    final remainingFields = [
      if (product.type != null) _buildDetailRow('Type', product.type!),
      if (product.gear != null) _buildDetailRow('Gear', product.gear!),
    ];

    if (remainingFields.isNotEmpty) {
      details.addAll([
        const SizedBox(height: 16),
        const Text('Additional Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...remainingFields,
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final priceFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: product.price.truncateToDouble() == product.price ? 0 : 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            if (product.images.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: product.images.length,
                  itemBuilder: (context, index) {
                    final imagePath = product.images[index];
                    Widget imageWidget;

                    if (imagePath.startsWith('data:image')) {
                      imageWidget = Image.memory(
                        base64Decode(imagePath.split(',').last),
                        fit: BoxFit.contain,
                      );
                    } else if (Uri.tryParse(imagePath)?.isAbsolute == true) {
                      imageWidget = Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image);
                        },
                      );
                    } else {
                      imageWidget = Image.asset(
                        'assets/placeholder.png',
                        fit: BoxFit.contain,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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

            const SizedBox(height: 24),
            // Title and Price
            Text(
              product.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              priceFormat.format(product.price),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),
            // Description
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description.isNotEmpty
                  ? product.description
                  : 'No description available',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            // Location
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _openLocation,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.location != 'Unknown'
                                  ? product.location
                                  : 'Location not specified',
                              style: TextStyle(
                                color: product.location != 'Unknown'
                                    ? Colors.blue
                                    : Colors.grey,
                                decoration: product.location != 'Unknown'
                                    ? TextDecoration.underline
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Category-specific details
            _buildCategorySpecificDetails(),

            // Seller Information
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seller Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    isLoadingSeller
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /*Text(
                              sellerName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),*/
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _navigateToSellerProfile(context),
                              child: Text(
                                'View Profile',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat with Seller'),
                    onPressed: () => _navigateToChat(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _isRequestProcessing
                      ? const Center(child: CircularProgressIndicator())
                      : _showRequestSent
                      ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Request Sent',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                      : OutlinedButton.icon(
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Request Product'),
                    onPressed: () => _requestProduct(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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