import 'package:flutter/material.dart';
import 'package:flutter_try02/navigation/app_routes.dart';

class RentalDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> rentalData;

  const RentalDetailsScreen({super.key, required this.rentalData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(rentalData['title'] ?? 'Rental Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Center(
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(rentalData['productImage'] ?? 'assets/default_product.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Product Name
            Text(
              rentalData['productName'] ?? 'Product Name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Rental Period
            _buildDetailRow('Rental Period:', rentalData['duration'] ?? 'N/A'),
            const SizedBox(height: 8),

            // Owner Name
            _buildDetailRow('Owner:', rentalData['ownerName'] ?? 'N/A'),
            const SizedBox(height: 8),

            // Hours Rented
            _buildDetailRow('Hours Rented:', rentalData['hoursRented'] ?? 'N/A'),
            const SizedBox(height: 8),

            // Amount Paid
            _buildDetailRow('Amount Paid:', rentalData['amountPaid'] ?? 'N/A'),
            const SizedBox(height: 16),

            // Rating Section
            const Text(
              'Your Rating:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildRatingStars(rentalData['rating'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 30,
        );
      }),
    );
  }
}