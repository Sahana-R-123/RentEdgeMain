import 'package:flutter/material.dart';
import 'package:flutter_try02/navigation/app_routes.dart';
import 'package:flutter_try02/screens/profile_screen.dart';
import 'package:flutter_try02/widgets/product_card.dart';
import 'package:flutter_try02/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_try02/screens/requests_screen.dart';
import 'package:flutter_try02/screens/product_details_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _screens = [
    const DashboardContent(),
    const SizedBox.shrink(),
    const SizedBox.shrink(),
    const SizedBox.shrink(),
    const RequestsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.chat);
    } else if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.category);
    } else if (index == 3) {
      Navigator.pushNamed(context, AppRoutes.favorites);
    } else if (index == 4) {
      Navigator.pushNamed(context, AppRoutes.requests);
    } else if (index == 5) {
      Navigator.pushNamed(context, AppRoutes.profile).then((_) {
        setState(() => _selectedIndex = 0);
      });
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab =
        !await _navigatorKeys[_selectedIndex].currentState!.maybePop();

        if (isFirstRouteInCurrentTab) {
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
            return false;
          }
        }
        return isFirstRouteInCurrentTab;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RentEdge'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Clear search when back button is pressed
              if (_selectedIndex == 0) {
                final dashboardContent = _screens[0] as DashboardContent;
                dashboardContent.clearSearch();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
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

  void clearSearch() {
    _DashboardContentState().clearSearch();
  }
}

class _DashboardContentState extends State<DashboardContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void clearSearch() {
    setState(() {
      searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or category...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
          ),
        ),
        Expanded(
          child: searchQuery.isNotEmpty
              ? _buildSearchResults()
              : _buildProductGrid(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return WillPopScope(
      onWillPop: () async {
        clearSearch();
        return false;
      },
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
            return const Center(child: Text('No products found.'));
          }

          final products = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title']?.toString().toLowerCase() ?? '';
            final category = data['category']?.toString().toLowerCase() ?? '';
            return title.contains(searchQuery) || category.contains(searchQuery);
          }).toList();

          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No products match your search.'),
              ),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(product['title'] ?? 'Untitled'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${product['price']?.toStringAsFixed(2) ?? '0.00'}'),
                    if (product['details']?.toString().isNotEmpty ?? false)
                      Text(product['details']),
                    if (product['location'] != null)
                      Text(
                        product['location'] is GeoPoint
                            ? 'Location: ${(product['location'] as GeoPoint).latitude.toStringAsFixed(4)}, ${(product['location'] as GeoPoint).longitude.toStringAsFixed(4)}'
                            : product['location'].toString(),
                      ),
                  ],
                ),
                onTap: () {
                  final productObj = Product.fromMap(product);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsPage(product: productObj),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
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
            final images = List<String>.from(data['images'] ?? []);

            return ProductCard(
              product: product,
              images: images,
            );
          },
        );
      },
    );
  }
}