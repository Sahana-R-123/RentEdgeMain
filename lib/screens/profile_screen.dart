import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_try02/navigation/app_routes.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'report_issue_screen.dart';
import 'rental_details_screen.dart';
import 'your_listings_screen.dart'; // import the listings screen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              _buildHeaderSection(context, user.profileImage),
              const SizedBox(height: 20),
              Text('Registered ID: ${user.registeredId}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Department: ${user.department}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('College: ${user.college}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Name: ${user.firstName} ${user.lastName}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Email: ${user.email}', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text("Your Listings"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const YourListingsScreen()),
                  );
                },
              ),
            ] else ...[
              const Text('No user data available'),
            ],
            const SizedBox(height: 32),
            _buildRentalHistorySection(context),
            const SizedBox(height: 32),
            _buildSupportSection(context),
            const SizedBox(height: 32),
            _buildLogoutSection(context),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppRoutes.pushAndRemoveUntil(context, AppRoutes.login);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, File? profileImage) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              print('Edit Profile Picture');
            },
            child: CircleAvatar(
              radius: 50,
              backgroundImage: profileImage != null
                  ? FileImage(profileImage)
                  : const AssetImage('assets/profile_picture.jpg') as ImageProvider,
              child: const Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.edit, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.editProfile);
            },
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalHistorySection(BuildContext context) {
    List<Map<String, dynamic>> rentals = [
      {
        'title': 'Rental 1',
        'duration': 'January 2023 - March 2023',
        'productImage': 'assets/product1.jpg',
        'productName': 'Canon EOS R5',
        'ownerName': 'John Doe',
        'hoursRented': '48 hours',
        'amountPaid': '\$120',
        'rating': 4,
      },
      {
        'title': 'Rental 2',
        'duration': 'April 2023 - Present',
        'productImage': 'assets/product2.jpg',
        'productName': 'Sony A7 IV',
        'ownerName': 'Jane Smith',
        'hoursRented': '72 hours',
        'amountPaid': '\$180',
        'rating': 5,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rental History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (rentals.isNotEmpty)
          ...rentals.map((rental) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(rental['title'] ?? 'No Title'),
            subtitle: Text(rental['duration'] ?? 'No Duration'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RentalDetailsScreen(rentalData: rental),
                ),
              );
            },
          )).toList()
        else
          const Text('No rental history available'),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Support & Help', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.report_problem),
          title: const Text('Report an Issue'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReportIssueScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Logout & Account Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Log Out'),
          onTap: () {
            _showLogoutConfirmation(context);
          },
        ),
      ],
    );
  }
}
