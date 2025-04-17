import 'package:flutter/material.dart';
import 'package:flutter_try02/navigation/app_routes.dart';
import 'package:flutter_try02/screens/profile_screen.dart';
import 'package:flutter_try02/widgets/product_card.dart';
import 'package:flutter_try02/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_try02/screens/requests_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // List of screens for the bottom navigation bar
  final List<Widget> _screens = [
    const DashboardContent(), // Home tab (index 0)
    const SizedBox.shrink(), // Placeholder for Chat tab (index 1)
    const SizedBox.shrink(), // Placeholder for Add tab (index 2)
    const SizedBox.shrink(), // Placeholder for Favorites tab (index 3)
    const RequestsScreen(), // Requests tab (index 4)
    const ProfileScreen(), // Profile tab (index 5)
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      // Handle Chat tab click
      Navigator.pushNamed(context, AppRoutes.chat);
    } else if (index == 2) {
      // Handle "+" button click
      Navigator.pushNamed(context, AppRoutes.category);
    } else if (index == 3) {
      // Handle Favorites tab click
      Navigator.pushNamed(context, AppRoutes.favorites);
    }else if (index == 4) {
      // Handle Requests tab click
      Navigator.pushNamed(context, AppRoutes.requests);
    } else if (index == 5) {
      // Handle Profile tab click
      Navigator.pushNamed(context, AppRoutes.profile).then((_) {
        // Reset to Home tab after returning from Profile
        setState(() {
          _selectedIndex = 0;
        });
      });
    } else {
      // Handle Home tab (index 0) or Requests tab (index 4)
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit the app when back button is pressed on Dashboard
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RentEdge'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Handle search button press
                print('Search button pressed');
              },
            ),
          ],
        ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 30),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        ),

        // Display Recommendations if searching
        if (searchQuery.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('products')
                    .where('name', isGreaterThanOrEqualTo: searchQuery)
                    .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  final products = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(product['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product['price']),
                            if (product['details'] != null && product['details'].isNotEmpty)
                              Text(product['details']),
                            Text(product['location']),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

        // Display Product Cards in a Grid
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No products available.'));
              }

              final products = snapshot.data!.docs;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final data = products[index].data() as Map<String, dynamic>;
                  final product = Product.fromMap(data);

                  return ProductCard(
                    product: product,
                    images: product.images,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
