import 'dart:async';
import 'dart:developer';
import 'package:clothing_app/bloc/bloc.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage_models.dart';

class HomepageBloc extends Bloc {
  final BuildContext context;
  final State<StatefulWidget> state;

  HomepageBloc(this.context, this.state) {
    _init();
  }

  final client = Supabase.instance.client;

  List<Product> _products = [];

  /// productId -> quantity
  Map<int, int> _cartMap = {};

  final BehaviorSubject<List<Product>> _productsStream =
      BehaviorSubject<List<Product>>();

  Stream<List<Product>> get productsStream => _productsStream.stream;

  StreamSubscription<List<Map<String, dynamic>>>? _productSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _cartSubscription;
  final ScrollController _scrollController = ScrollController();
  ScrollController get scrollController => _scrollController;


  bool _isDisposed = false;
  bool animationStarted = false;

  /// Initialize streams
  void _init() {
    _listenProducts();
    _listenCart();
  }

  /// Listen to product realtime stream
  void _listenProducts() {
    final stream = client
        .from(ConstantStrings.productsTable)
        .stream(primaryKey: ['id']);

    _productSubscription = stream.listen(
      (data) {
        _products = data.map((json) => Product.fromJson(json)).toList();

        _mergeCartState();
      },
      onError: (error) {
        _productsStream.addError(error);
      },
    );
  }

  /// Listen to cart realtime stream
  void _listenCart() {
    final stream = client
        .from(ConstantStrings.cartTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', client.auth.currentUser!.id);

    _cartSubscription = stream.listen(
      (data) {
        log("HomepageBloc: Cart stream emitted ${data.length} items");

        _cartMap = {
          for (var item in data)
            item['product_id'] as int: item['quantity'] as int,
        };

        _mergeCartState();
      },
      onError: (error) {
        log("HomepageBloc: cart stream error $error");
      },
    );
  }

  /// Merge cart quantities into products
  void _mergeCartState() {
    for (var product in _products) {
      final qty = _cartMap[product.id] ?? 0;
      product.quantity = qty;
    }

    if (!_isDisposed && !_productsStream.isClosed) {
      // Emit a new list reference to ensure StreamBuilder and other listeners detect the change
      _productsStream.add(List.from(_products));
    }
  }

  /// Add product to cart
  Future<void> addToCart(Product product) async {
    try {
      await client.from(ConstantStrings.cartTable).upsert({
        'user_id': client.auth.currentUser!.id,
        'product_id': product.id,
        'quantity': 1,
      }, onConflict: 'user_id,product_id');

      _cartMap[product.id] = 1;

      _mergeCartState();
    } catch (e, t) {
      log("addToCart error $e \n $t");
    }
  }

  /// Increase quantity
  Future<void> increaseQuantity(Product product) async {
    final qty = (_cartMap[product.id] ?? 0) + 1;

    try {
      await client
          .from(ConstantStrings.cartTable)
          .update({'quantity': qty})
          .eq('user_id', client.auth.currentUser!.id)
          .eq('product_id', product.id);

      _cartMap[product.id] = qty;

      _mergeCartState();
    } catch (e, t) {
      log("increaseQuantity error $e \n $t");
    }
  }

  /// Decrease quantity
  Future<void> decreaseQuantity(Product product) async {
    final qty = (_cartMap[product.id] ?? 0) - 1;

    try {
      if (qty <= 0) {
        await client
            .from(ConstantStrings.cartTable)
            .delete()
            .eq('user_id', client.auth.currentUser!.id)
            .eq('product_id', product.id);

        _cartMap.remove(product.id);
      } else {
        await client
            .from(ConstantStrings.cartTable)
            .update({'quantity': qty})
            .eq('user_id', client.auth.currentUser!.id)
            .eq('product_id', product.id);

        _cartMap[product.id] = qty;
      }

      _mergeCartState();
    } catch (e, t) {
      log("decreaseQuantity error $e \n $t");
    }
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      // Only scroll if we aren't already at the top
      if (_scrollController.offset > 0) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500), // Slightly longer for a premium feel
          curve: Curves.easeInOutCubic, // Smoother acceleration/deceleration
        );
      }
    } else {
      log("ScrollController is not attached to any scroll view");
    }
  }

  /////////////////////////Product Details///////////////////////

  Future<Product> getProductDetailsOnce(int productId) async {
    try {
      // Fetch from Supabase
      final response = await client
          .from(ConstantStrings.productsTable)
          .select()
          .eq('id', productId)
          .single();

      // Convert JSON to Product
      final product = Product.fromJson(response);

      return product; // <-- Return the fetched product
    } catch (e, t) {
      log('HomepageBloc getProductDetails catch $e, \n $t');
      // You can throw the error to let FutureBuilder catch it
      throw Exception('Failed to load product');
    }
  }

  Future<void> refresh() async {
    log("HomepageBloc: Refreshing data...");
    _productSubscription?.cancel();
    _cartSubscription?.cancel();
    _init();
    // Give it a moment to fetch the first batch
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _isDisposed = true;

    _productSubscription?.cancel();
    _cartSubscription?.cancel();
    _scrollController.dispose();
    _productsStream.close();
  }
}
