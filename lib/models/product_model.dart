import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final Map<String, dynamic> details;
  final double price;
  final List<String> images;
  final String location;
  final Map<String, dynamic> categoryDetails;
  final String category;
  final String sellerId;
  final String sellerName;
  final String sellerRegisterId;

  Product({
    required this.id,
    required this.title,
    required this.details,
    required this.price,
    required this.images,
    required this.location,
    required this.categoryDetails,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRegisterId,
  });

  // Existing fromMap factory (unchanged)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      details: map['details'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['details'])
          : <String, dynamic>{},
      price: () {
        final val = map['price'];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
        return 0.0;
      }(),
      images: () {
        final val = map['images'];
        if (val is List) {
          return List<String>.from(val.map((e) => e.toString()));
        }
        if (val is String) {
          return val.split(',').map((e) => e.trim()).toList();
        }
        return <String>[];
      }(),
      location: () {
        final val = map['location'];
        if (val is String) return val;
        if (val is GeoPoint) return '${val.latitude}, ${val.longitude}';
        if (val is Map && val.containsKey('latitude') && val.containsKey('longitude')) {
          return '${val['latitude']}, ${val['longitude']}';
        }
        return 'Unknown';
      }(),
      categoryDetails: map['categoryDetails'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['categoryDetails'])
          : <String, dynamic>{},
      category: map['category'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerRegisterId: map['sellerRegisterId'] ?? '',
    );
  }

  // Existing toMap method (unchanged)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'details': details,
      'price': price,
      'images': images,
      'location': location,
      'categoryDetails': categoryDetails,
      'category': category,
      'sellerId': sellerId,
    };
  }

  // NEW: Add these methods for favorites functionality
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'images': images,
    'location': location,
    'category': category,
    'sellerId': sellerId,
    'details': details,
    'categoryDetails': categoryDetails,
    'sellerName': sellerName,
    'sellerRegisterId': sellerRegisterId,
  };

  // NEW: Factory method for JSON deserialization
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      price: json['price'].toDouble(),
      images: List<String>.from(json['images']),
      location: json['location'],
      category: json['category'],
      sellerId: json['sellerId'],
      details: Map<String, dynamic>.from(json['details']),
      categoryDetails: Map<String, dynamic>.from(json['categoryDetails']),
      sellerName: json['sellerName'],
      sellerRegisterId: json['sellerRegisterId'],
    );
  }

  // NEW: Proper equality comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product && runtimeType == other.runtimeType && id == other.id;

  // NEW: hashCode implementation
  @override
  int get hashCode => id.hashCode;

  // NEW: Helper method to create a copy of the product
  Product copyWith({
    String? id,
    String? title,
    Map<String, dynamic>? details,
    double? price,
    List<String>? images,
    String? location,
    Map<String, dynamic>? categoryDetails,
    String? category,
    String? sellerId,
    String? sellerName,
    String? sellerRegisterId,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      details: details ?? this.details,
      price: price ?? this.price,
      images: images ?? this.images,
      location: location ?? this.location,
      categoryDetails: categoryDetails ?? this.categoryDetails,
      category: category ?? this.category,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerRegisterId: sellerRegisterId ?? this.sellerRegisterId,
    );
  }
}