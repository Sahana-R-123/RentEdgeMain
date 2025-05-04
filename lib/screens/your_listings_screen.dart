import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class YourListingsScreen extends StatelessWidget {
  const YourListingsScreen({Key? key}) : super(key: key);

  Future<void> _deleteProduct(BuildContext context, String productId) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Your Listings")),
        body: const Center(child: Text("You must be logged in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Listings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No listings yet."));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final data = productDoc.data() as Map<String, dynamic>;
              final productId = productDoc.id;

              Widget imageWidget = const Icon(Icons.image_not_supported, size: 40);

              // ✅ Display image from imgbb-hosted URL
              if (data['images'] != null &&
                  data['images'] is List &&
                  data['images'].isNotEmpty) {
                final imageUrl = data['images'][0];
                imageWidget = Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 40),
                );
              }

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: imageWidget,
                  title: Text(data['title'] ?? 'No title',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Price: ₹${data['price'] ?? 'N/A'}"),
                      if (data['description'] != null)
                        Text("Description: ${data['description']}"),
                      if (data['category'] != null)
                        Text("Category: ${data['category']}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(context, productId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this product?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(context, productId);
              },
            ),
          ],
        );
      },
    );
  }
}
