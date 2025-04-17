import 'package:flutter/material.dart';

class PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Colors.blue[50] : null,
      elevation: isSelected ? 2 : 1,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
        title: Text(title),
        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
        onTap: onTap,
      ),
    );
  }
}