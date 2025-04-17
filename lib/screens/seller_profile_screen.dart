import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerId;

  const SellerProfileScreen({required this.sellerId, super.key});

  Future<Map<String, dynamic>?> getSellerData() async {
    try {
      if (sellerId.isEmpty) {
        debugPrint('Error: sellerId is empty!');
        return null;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();

      if (!doc.exists) {
        debugPrint('Error: Seller document does not exist');
        return null;
      }

      return doc.data();
    } catch (e) {
      debugPrint('Error fetching seller data: $e');
      return null;
    }
  }

  Widget _buildProfileSection(Map<String, dynamic> data) {
    return Column(
      children: [
        const SizedBox(height: 20),
        if (data['profileImage'] != null)
          CachedNetworkImage(
            imageUrl: data['profileImage'],
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: 60,
              backgroundColor: Colors.transparent,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => const CircleAvatar(
              radius: 60,
              child: Icon(Icons.person, size: 50),
            ),
            errorWidget: (context, url, error) => const CircleAvatar(
              radius: 60,
              child: Icon(Icons.error),
            ),
          )
        else
          const CircleAvatar(
            radius: 60,
            child: Icon(Icons.person, size: 50),
          ),
        const SizedBox(height: 16),
        Text(
          data['firstName']?.toString() ?? 'No name provided',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (data['registeredId'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'ID: ${data['registeredId']}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('Department', data['department']?.toString()),
            const Divider(),
            _buildInfoRow('College', data['college']?.toString()),
            const Divider(),
            _buildInfoRow('Register ID', data['registeredId']?.toString() ?? 'No register ID provided'),
            if (data['contact'] != null) ...[
              const Divider(),
              _buildInfoRow('Contact', data['contact']?.toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getSellerData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load profile\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Seller information not available',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final data = snapshot.data!;
          debugPrint('Fetched data: $data'); // This will help in debugging

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileSection(data),
                const SizedBox(height: 24),
                _buildInfoCard(data),
              ],
            ),
          );
        },
      ),
    );
  }
}