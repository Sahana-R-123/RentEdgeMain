import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_try02/providers/favorite_provider.dart';
import 'package:flutter_try02/models/product_model.dart';
import 'package:flutter_try02/screens/dashboard_screen.dart';
import 'package:flutter_try02/screens/product_details_page.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final likedProducts = favoriteProvider.likedProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
            );
          },
        ),
      ),
      body: likedProducts.isEmpty
          ? const Center(
        child: Text(
          'No favorites yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: likedProducts.length,
        itemBuilder: (context, index) {
          final product = likedProducts[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(product: product),
                ),
              );
            },
            child: FavoriteProductItem(product: product),
          );
        },
      ),
    );
  }
}

class FavoriteProductItem extends StatelessWidget {
  final Product product;

  const FavoriteProductItem({
    required this.product,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: true);
    bool isFavorite = favoriteProvider.isLiked(product);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    if (isFavorite) {
                      favoriteProvider.unlikeProduct(product);
                    } else {
                      favoriteProvider.likeProduct(product);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (product.details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                product.details['title'] ?? 'No title',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  product.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}