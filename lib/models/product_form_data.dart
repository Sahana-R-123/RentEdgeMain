class ProductFormData {
  String brand;
  String title;
  String description;
  double price;
  String location;
  List<String> images;
  Map<String, dynamic> categorySpecificFields;

  ProductFormData({
    required this.brand,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    this.images = const [],
    this.categorySpecificFields = const {},
  });

  factory ProductFormData.fromMap(Map<String, dynamic> map) {
    return ProductFormData(
      brand: map['brand'] is String ? map['brand'] : 'Unknown',
      title: map['title'] is String ? map['title'] : 'No Title',
      description: map['description'] is String ? map['description'] : '',
      price: () {
        final value = map['price'];
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }(),
      location: (() {
        final value = map['location'];
        if (value is String) return value;
        if (value is Map && value.containsKey('latitude') && value.containsKey('longitude')) {
          return '${value['latitude']}, ${value['longitude']}';
        }
        return value?.toString() ?? 'Unknown';
      })(),
      images: (() {
        final value = map['images'];
        if (value is List) return value.map((e) => e.toString()).toList();
        if (value is String) return value.split(',').map((e) => e.trim()).toList();
        return [];
      })(),
      categorySpecificFields: map['categorySpecificFields'] is Map
          ? Map<String, dynamic>.from(map['categorySpecificFields'])
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'images': images,
      'categorySpecificFields': categorySpecificFields,
    };
  }
}
