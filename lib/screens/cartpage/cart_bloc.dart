import 'dart:async';
import 'dart:developer';
import 'package:clothing_app/local_notifications/navigation_helper.dart';
import 'package:clothing_app/screens/cartpage/cart_models.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:clothing_app/utils/constant_variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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

  final BehaviorSubject<List<CartItem>> _cartStream = BehaviorSubject.seeded(
    [],
  );

  Stream<List<CartItem>> get cartStream => _cartStream.stream;

  Stream<int> get totalQuantityStream => _cartStream.map(
    (list) => list.fold(0, (sum, item) => sum + item.quantity),
  );

  StreamSubscription<List<Map<String, dynamic>>>? _cartSubscription;
  final supabase = Supabase.instance.client;

  void _initStream() {
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
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      final items = (response as List)
          .map((e) => CartItem.fromJson(e))
          .toList();
      if (!_isDisposed && !_cartStream.isClosed) {
        _cartStream.add(items);
      }
    } catch (e, st) {
      log('Cart fetch error', error: e, stackTrace: st);
      _cartStream.addError(e);
    }
  }

  Future<void> removeFromCart(int cartId) async {
    try {
      await Supabase.instance.client
          .from(ConstantStrings.cartTable)
          .delete()
          .eq('id', cartId);
      if (!_isDisposed && !_cartStream.isClosed) {
        _cartStream.add(
          _cartStream.value.where((element) => element.id != cartId).toList(),
        );
      }
    } catch (e, t) {
      log('CartBloc removeFromCart catch $e, \n $t');
    } finally {}
  }

  Future<void> changeQuantity(CartItem item, int quantity) async {
    final supabase = Supabase.instance.client;
    showLoadingDialog(navigatorKey.currentContext!);
    try {
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

      if (!_isDisposed && !_cartStream.isClosed) {
        final currentItems = _cartStream.value;
        if (quantity <= 0) {
          _cartStream.add(currentItems.where((i) => i.id != item.id).toList());
        } else {
          _cartStream.add(
            currentItems.map((i) {
              if (i.id == item.id) {
                return CartItem(
                  id: i.id,
                  quantity: quantity,
                  product: i.product,
                );
              }
              return i;
            }).toList(),
          );
        }
      }
    } catch (e, t) {
      log('CartBloc changeQuantity catch $e, \n $t');
    } finally {
      Navigator.pop(navigatorKey.currentContext!);
    }
  }

  double get cartTotal => _cartStream.value.fold(0, (sum, i) => sum + i.total);

  Future<void> checkout() async {
    final supabase = Supabase.instance.client;
    showLoadingDialog(context);
    try {
      await supabase
          .from(ConstantStrings.cartTable)
          .delete()
          .eq('user_id', supabase.auth.currentUser!.id);

      if (!_isDisposed && !_cartStream.isClosed) {
        _cartStream.add([]);
      }
    } catch (e, t) {
      log('CartBloc checkout catch $e, \n $t');
    } finally {
      Navigator.pop(context);
    }
  }

  void showLoadingDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Lottie.asset(
          'assets/lottie/loading.json',
          width: deviceWidth / 3,
          fit: BoxFit.contain,
          delegates: LottieDelegates(
            values: [
              ValueDelegate.color(const [
                '**',
              ], value: Theme.of(context).primaryColor),
            ],
          ),
          repeat: true,
        ),
      ),
    );
  }

  void showConfirmDialog(BuildContext context, int cartId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Item',
      barrierColor: Colors.black26, // Dim the background
      pageBuilder: (ctx, a1, a2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.white30,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon to give visual context
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Remove Item?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Are you sure you want to delete this item from your cart?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      // Cancel Button (Ghost Style)
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Confirm Button (Solid Red Style)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            removeFromCart(cartId);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Delete",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, a1, a2, child) {
        return Transform.scale(
          scale: a1.value,
          child: FadeTransition(opacity: a1, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  bool _isDisposed = false;
  @override
  void dispose() {
    _isDisposed = true;
    _cartSubscription?.cancel();
    _cartStream.close();
  }
}
