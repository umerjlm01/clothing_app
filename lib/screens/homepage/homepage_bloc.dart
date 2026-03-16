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


  HomepageBloc(this.context, this.state){
    _init();
  }

  final client = Supabase.instance.client;

  List<Product> _products = [];

  /// productId -> quantity
  Map<int,int> _cartMap = {};

  final BehaviorSubject<List<Product>> _productsStream =
  BehaviorSubject<List<Product>>();

  Stream<List<Product>> get productsStream => _productsStream.stream;

  StreamSubscription<List<Map<String,dynamic>>>? _productSubscription;

  bool _isDisposed = false;
  bool animationStarted = false;






  /// Initialize streams
  void _init() {
    _listenProducts();
    _fetchCart();
  }



  /// Listen to product realtime stream
  void _listenProducts() {
    final stream = client
        .from(ConstantStrings.productsTable)
        .stream(primaryKey: ['id']);

    _productSubscription = stream.listen((data) {

      _products = data.map((json) => Product.fromJson(json)).toList();

      _mergeCartState();

    }, onError: (error){
      _productsStream.addError(error);
    });
  }

  /// Fetch cart items
  Future<void> _fetchCart() async {
    try{

      final cartItems = await client
          .from(ConstantStrings.cartTable)
          .select('product_id, quantity')
          .eq('user_id', client.auth.currentUser!.id);

      _cartMap = {
        for (var item in cartItems)
          item['product_id'] as int : item['quantity'] as int
      };

      _mergeCartState();

    }catch(e,t){
      log("fetchCart error $e \n $t");
    }
  }

  /// Merge cart quantities into products
  void _mergeCartState(){

    for(var product in _products){
      final qty = _cartMap[product.id] ?? 0;
      product.quantity = qty;
    }

    if(!_isDisposed && !_productsStream.isClosed){
      _productsStream.add(_products);
    }
  }


  /// Add product to cart
  Future<void> addToCart(Product product) async{
    try{

      await client.from(ConstantStrings.cartTable).upsert({
        'user_id': client.auth.currentUser!.id,
        'product_id': product.id,
        'quantity': 1
      }, onConflict: 'user_id,product_id');

      _cartMap[product.id] = 1;

      _mergeCartState();

    }catch(e,t){
      log("addToCart error $e \n $t");
    }
  }

  /// Increase quantity
  Future<void> increaseQuantity(Product product) async{

    final qty = (_cartMap[product.id] ?? 0) + 1;

    try{

      await client
          .from(ConstantStrings.cartTable)
          .update({'quantity': qty})
          .eq('user_id', client.auth.currentUser!.id)
          .eq('product_id', product.id);

      _cartMap[product.id] = qty;

      _mergeCartState();

    }catch(e,t){
      log("increaseQuantity error $e \n $t");
    }
  }

  /// Decrease quantity
  Future<void> decreaseQuantity(Product product) async{

    final qty = (_cartMap[product.id] ?? 0) - 1;

    try{

      if(qty <= 0){

        await client
            .from(ConstantStrings.cartTable)
            .delete()
            .eq('user_id', client.auth.currentUser!.id)
            .eq('product_id', product.id);

        _cartMap.remove(product.id);

      }else{

        await client
            .from(ConstantStrings.cartTable)
            .update({'quantity': qty})
            .eq('user_id', client.auth.currentUser!.id)
            .eq('product_id', product.id);

        _cartMap[product.id] = qty;

      }

      _mergeCartState();

    }catch(e,t){
      log("decreaseQuantity error $e \n $t");
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




  @override
  void dispose(){

    _isDisposed = true;

    _productSubscription?.cancel();

    _productsStream.close();




  }



}
