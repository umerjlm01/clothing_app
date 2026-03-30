import 'package:cached_network_image/cached_network_image.dart';
import 'package:clothing_app/screens/cartpage/cart_bloc.dart';
import 'package:clothing_app/screens/cartpage/cart_models.dart';
import 'package:clothing_app/screens/cartpage/checkout_success_screen.dart';
import 'package:clothing_app/animations/animation_handler.dart';
import 'package:flutter/material.dart';
import '../../reusable_widgets/app_bar.dart';
import '../../utils/constant_strings.dart';
import '../../utils/constant_variables.dart';
import '../../reusable_widgets/shimmer_loaders.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  late CartBloc _bloc;
  late AnimationHandler _animationHandler;



  @override
  void initState() {
    super.initState();
    if (mounted) {
      _bloc = CartBloc(context, this);
      _animationHandler = AnimationHandler(vsync: this);
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.of(context)) {
      // Only trigger animation when page becomes active
      _animationHandler.resetAnimation();
      _animationHandler.animationPlay();
    }
  }

  @override
  void dispose() {
    _bloc.dispose();
    _animationHandler.animationDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(preferredSize: Size.fromHeight(deviceHeight / 15), child: CustomAppBar(
          icon: const Icon(Icons.menu),
          title: Text(ConstantStrings.cart, style: TextStyle(fontWeight: FontWeight.bold),),
          centerTitle: true,
          elevation: 0,
        ),),
      body: StreamBuilder<List<CartItem>>(
            stream: _bloc.cartStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ShimmerLoaders.list();
              }

              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }

              final items = snapshot.data!;

              if (items.isEmpty) {
                return Center(child: Text(ConstantStrings.emptyCart));
              }


              return ListView.builder(
                padding: EdgeInsets.only(bottom: deviceHeight / 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  return SlideTransition(position: _animationHandler.titleSlide,
                  child: FadeTransition(
                    opacity: _animationHandler.fade,
                    child: Card(
                      child: ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: item.product.imageUrl,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                        title: Text(item.product.title),
                        subtitle: Text('\$${item.total.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () =>
                                  _bloc.changeQuantity(item, item.quantity + 1),
                            ),
                            Text(item.quantity.toString()),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () =>
                                  _bloc.changeQuantity(item, item.quantity - 1),
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _bloc.showConfirmDialog(context, item.id),
                            ),
                          ],
                        ),
                      ),
                    ),),
                  );
                },
              );
            },
          ),
      bottomNavigationBar: StreamBuilder<List<CartItem>>(
        stream: _bloc.cartStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "\$${_bloc.cartTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _bloc.checkout();
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutSuccessScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Checkout",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
