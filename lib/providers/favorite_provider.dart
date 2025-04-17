// lib/providers/favorite_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_try02/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoriteProvider with ChangeNotifier {
  List<Product> _likedProducts = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get likedProducts => _likedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    if (_likedProducts.isEmpty && !_isLoading) {
      await _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final String? favoritesString = prefs.getString('favorites');

      if (favoritesString != null && favoritesString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(favoritesString);
        _likedProducts = jsonList.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      _error = 'Failed to load favorites';
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final String favoritesString = json.encode(
        _likedProducts.map((product) => product.toJson()).toList(),
      );
      await prefs.setString('favorites', favoritesString);
    } catch (e) {
      _error = 'Failed to save favorites';
      debugPrint('Error saving favorites: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isLiked(Product product) {
    return _likedProducts.any((p) => p.id == product.id);
  }

  Future<void> toggleLike(Product product) async {
    try {
      if (isLiked(product)) {
        await unlikeProduct(product);
      } else {
        await likeProduct(product);
      }
    } catch (e) {
      _error = 'Failed to update favorites';
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<void> likeProduct(Product product) async {
    if (!isLiked(product)) {
      _likedProducts.add(product);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> unlikeProduct(Product product) async {
    final initialLength = _likedProducts.length;
    _likedProducts.removeWhere((p) => p.id == product.id);

    if (_likedProducts.length != initialLength) {
      await _saveFavorites();
      notifyListeners();
    }
  }

  void clearFavorites() {
    _likedProducts.clear();
    notifyListeners();
    _saveFavorites(); // Fire and forget
  }
}
