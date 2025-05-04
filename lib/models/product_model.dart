import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final Map<String, dynamic> details;
  final double price;
  final List<String> images;
  final String location;
  final Map<String, dynamic> categoryDetails;
  final String category;
  final String sellerId;
  final String sellerName;
  final String sellerRegisterId;

  // New optional fields (category-specific)
  final String? author;
  final String? bookTitle;
  final String? condition;
  final String? size;
  final String? brand;
  final String? model;
  final String? specs;
  final String? type;
  final String? gameName;
  final String? platform;
  final String? gear;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.details,
    required this.price,
    required this.images,
    required this.location,
    required this.categoryDetails,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRegisterId,
    this.author,
    this.bookTitle,
    this.condition,
    this.size,
    this.brand,
    this.model,
    this.specs,
    this.type,
    this.gameName,
    this.platform,
    this.gear,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
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
        if (val is List) return List<String>.from(val.map((e) => e.toString()));
        if (val is String) return val.split(',').map((e) => e.trim()).toList();
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
      author: map['author'],
      bookTitle: map['bookTitle'],
      condition: map['condition'],
      size: map['size'],
      brand: map['brand'],
      model: map['model'],
      specs: map['specs'],
      type: map['type'],
      gameName: map['gameName'],
      platform: map['platform'],
      gear: map['gear'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'details': details,
      'price': price,
      'images': images,
      'location': location,
      'categoryDetails': categoryDetails,
      'category': category,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerRegisterId': sellerRegisterId,
      'author': author,
      'bookTitle': bookTitle,
      'condition': condition,
      'size': size,
      'brand': brand,
      'model': model,
      'specs': specs,
      'type': type,
      'gameName': gameName,
      'platform': platform,
      'gear': gear,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory Product.fromJson(Map<String, dynamic> json) => Product.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  Product copyWith({
    String? id,
    String? title,
    String? description,
    Map<String, dynamic>? details,
    double? price,
    List<String>? images,
    String? location,
    Map<String, dynamic>? categoryDetails,
    String? category,
    String? sellerId,
    String? sellerName,
    String? sellerRegisterId,
    String? author,
    String? bookTitle,
    String? condition,
    String? size,
    String? brand,
    String? model,
    String? specs,
    String? type,
    String? gameName,
    String? platform,
    String? gear,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      details: details ?? this.details,
      price: price ?? this.price,
      images: images ?? this.images,
      location: location ?? this.location,
      categoryDetails: categoryDetails ?? this.categoryDetails,
      category: category ?? this.category,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerRegisterId: sellerRegisterId ?? this.sellerRegisterId,
      author: author ?? this.author,
      bookTitle: bookTitle ?? this.bookTitle,
      condition: condition ?? this.condition,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      specs: specs ?? this.specs,
      type: type ?? this.type,
      gameName: gameName ?? this.gameName,
      platform: platform ?? this.platform,
      gear: gear ?? this.gear,
    );
  }
}