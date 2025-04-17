import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class YourListingsScreen extends StatelessWidget {
  const YourListingsScreen({Key? key}) : super(key: key);

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
            Navigator.pushReplacementNamed(context, '/dashboard'); // Adjust this route if needed
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: userId) // ✅ Updated to match Firestore field
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
              final data = products[index].data() as Map<String, dynamic>;

              Widget imageWidget = const Icon(Icons.image_not_supported, size: 40);

              if (data['images'] != null &&
                  data['images'] is List &&
                  data['images'].isNotEmpty) {
                try {
                  final decoded = base64Decode(data['images'][0]);
                  imageWidget = Image.memory(
                    decoded,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  );
                } catch (e) {
                  // If decoding fails, fallback to icon
                  imageWidget = const Icon(Icons.broken_image, size: 40);
                }
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
