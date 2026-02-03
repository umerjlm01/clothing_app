class Product {
  final int id;
  final String title;
  final double price;
  final String imageUrl;
  final String description;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.createdAt,
  });

  /// Convert Supabase JSON → Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convert Product → JSON (for insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'image_url': imageUrl,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
