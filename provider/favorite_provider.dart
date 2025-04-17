import 'package:flutter/material.dart';
import 'package:flutter_try02/models/product_model.dart'; // Import Product model

class FavoriteProvider with ChangeNotifier {
  // List to store liked products
  final List<Product> _likedProducts = [];

  // Getter to access liked products
  List<Product> get likedProducts => _likedProducts;

  // Add a product to favorites
  void likeProduct(Product product) {
    if (!_likedProducts.contains(product)) {
      _likedProducts.add(product);
      notifyListeners(); // Notify listeners to update the UI
    }
  }

  // Remove a product from favorites
  void unlikeProduct(Product product) {
    if (_likedProducts.contains(product)) {
      _likedProducts.remove(product);
      notifyListeners(); // Notify listeners to update the UI
    }
  }

  // Check if a product is liked
  bool isLiked(Product product) {
    return _likedProducts.contains(product);
  }
}