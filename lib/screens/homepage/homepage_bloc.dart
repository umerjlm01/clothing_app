import 'dart:async';
import 'dart:developer';
import 'package:clothing_app/bloc/bloc.dart';
import 'package:clothing_app/local_notifications/push_notification.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage_models.dart';

class HomepageBloc extends Bloc {
  final BuildContext context;
  final State<StatefulWidget> state;

  HomepageBloc(this.context, this.state) {
    initStream();
  }
  List<Product> _products = [];
  final BehaviorSubject<List<Product>> _productsStream =
  BehaviorSubject<List<Product>>();
  Stream<List<Product>> get productsStream => _productsStream.stream;

  StreamSubscription<List<Map<String, dynamic>>>? _productsSubscription;

  void initStream() {
    final productStream = Supabase.instance.client
        .from(ConstantStrings.productsTable)
        .stream(primaryKey: ['id']);

    _productsSubscription = productStream.listen((data) {
      _products = data.map((json) => Product.fromJson(json)).toList();
      if(!_isDisposed && !_productsStream.isClosed){
      _productsStream.add(_products);}
    }, onError: (error) {
      _productsStream.addError(error);
    });
  }

  Future<void> toggleAddToCart(Product product) async {
    try {
      final client = Supabase.instance.client;
      await client.from(ConstantStrings.cartTable).upsert(
        { 'user_id': client.auth.currentUser!.id, 'product_id': product.id, 'quantity': 1},
        onConflict: 'user_id,product_id',
      );
      final receiverId = (product.id).toString();

      PushNotificationService.instance.trigger(receiverId: receiverId, title: "Added To Cart", body: "Your product has been added to your cart");
    }


    catch (e,t){
      _productsStream.addError(e);
      log('HomepageBloc toggleAddToCart catch $e, \n $t');
    }
  }


  bool _isDisposed = false;
  @override
  void dispose() {
    _isDisposed = true;
    _productsSubscription?.cancel();
    _productsStream.close();
  }
}
