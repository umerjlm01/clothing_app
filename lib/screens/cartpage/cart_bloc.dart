import 'dart:async';
import 'dart:developer';
import 'package:clothing_app/screens/cartpage/cart_models.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../bloc/bloc.dart';

class CartBloc extends Bloc {
  final BuildContext context;
  static CartBloc? instance;
  final State<StatefulWidget> state;

  CartBloc(this.context, this.state) {
    instance = this;
    _initStream();
  }

  final BehaviorSubject<List<CartItem>> _cartStream =
  BehaviorSubject.seeded([]);

  Stream<List<CartItem>> get cartStream => _cartStream.stream;

  Stream<int> get totalQuantityStream =>
      _cartStream.map((list) => list.fold(0, (sum, item) => sum + item.quantity));


  StreamSubscription<List<Map<String, dynamic>>>? _cartSubscription;
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<bool> get isLoadingNotifier => _isLoadingNotifier;


  void _initStream() {
    final supabase = Supabase.instance.client;

    _cartSubscription = supabase
        .from(ConstantStrings.cartTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', supabase.auth.currentUser!.id)
        .listen((_) {

      // Re-fetch on ANY change
      _fetchCart();

    });

    _fetchCart();
  }

  Future<void> _fetchCart() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from(ConstantStrings.cartTable)
          .select('id, quantity, products(*)')
          .eq('user_id', supabase.auth.currentUser!.id).order('created_at', ascending: false);

      final items = (response as List)
          .map((e) => CartItem.fromJson(e))
          .toList();
      if(!_isDisposed && !_cartStream.isClosed){
      _cartStream.add(items);}
    } catch (e, st) {
      log('Cart fetch error', error: e, stackTrace: st);
      _cartStream.addError(e);
    }
  }

  Future<void> removeFromCart(int cartId) async {
    try{
      _isLoadingNotifier.value = true;
    await Supabase.instance.client
        .from(ConstantStrings.cartTable)
        .delete()
        .eq('id', cartId);
    if(!_isDisposed && !_cartStream.isClosed){
    _cartStream.add(_cartStream.value.where((element) => element.id != cartId).toList());}
  }
  catch(e,t){
      log('CartBloc removeFromCart catch $e, \n $t');
  }
    finally{
      _isLoadingNotifier.value = false;
    }
  }

  /// CHANGE QUANTITY (DO NOT touch stream here)
  Future<void> changeQuantity(CartItem item, int quantity) async {
    final supabase = Supabase.instance.client;
    try{
     _isLoadingNotifier.value = true;
    if (quantity <= 0) {
      await supabase
          .from(ConstantStrings.cartTable)
          .delete()
          .eq('id', item.id);

    } else {
      await supabase
          .from(ConstantStrings.cartTable)
          .update({'quantity': quantity})
          .eq('id', item.id);
    }
    _cartStream.add(_cartStream.value);

  }
  catch(e,t) {
    log('CartBloc changeQuantity catch $e, \n $t');
  }
  finally{
      _isLoadingNotifier.value = false;
  }
  }


  double get cartTotal =>
      _cartStream.value.fold(0, (sum, i) => sum + i.total);

  bool _isDisposed = false;
  @override
  void dispose() {
    _isDisposed = true;
    _cartSubscription?.cancel();
    _cartStream.close();
    _isLoadingNotifier.dispose();
  }
}
