import '../../screens/homepage/homepage_models.dart';

/// Raw DB row (matches Supabase table)
class CartRow {
  final int id;
  final int quantity;

  CartRow({
    required this.id,
    required this.quantity,
  });
}

/// UI-ready cart item (cart + product)
class CartItem {
  final int id;
  final int quantity;
  final Product product;

  CartItem({
    required this.id,
    required this.quantity,
    required this.product,
  });

  double get total => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      quantity: json['quantity'],
      product: Product.fromJson(json['products']),
    );
  }
}
