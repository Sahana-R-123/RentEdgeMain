import "package:flutter/material.dart";
import 'sell_product_screen.dart'; // Import the SellProductScreen

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCategoryTile(context, 'Calculator'),
          _buildCategoryTile(context, 'Laptop'),
          _buildCategoryTile(context, 'Books'),
          _buildCategoryTile(context, 'Cycle'),
          _buildCategoryTile(context, 'Watch'),
          _buildCategoryTile(context, 'Lab Coat'),
          _buildCategoryTile(context, 'Board Games'),
          _buildCategoryTile(context, 'Stationary'),
          _buildCategoryTile(context, 'Shoes'),
          _buildCategoryTile(context, 'Other Accessories'),
        ],
      ),
    );
  }

  // Helper method to build a category ListTile
  Widget _buildCategoryTile(BuildContext context, String category) {
    return ListTile(
      title: Text(category),
      onTap: () {
        // Navigate to SellProductScreen with the selected category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SellProductScreen(initialCategory: category),
          ),
        );
      },
    );
  }
}