import 'package:cached_network_image/cached_network_image.dart';
import 'package:clothing_app/reusable_widgets/snack_bar_helper.dart';
import 'package:clothing_app/screens/cartpage/cart_bloc.dart';
import 'package:clothing_app/screens/cartpage/cart_models.dart';
import 'package:flutter/material.dart';
import '../../reusable_widgets/app_bar.dart';
import '../../utils/constant_strings.dart';
import '../../utils/constant_variables.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late CartBloc _bloc;

  @override
  void initState() {
    super.initState();
    if (mounted) {
      _bloc = CartBloc(context, this);
    }
  }

  @override
  void dispose() {
    _bloc.dispose();
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return Center(child: Text(ConstantStrings.emptyCart));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
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
                        onPressed: () {_bloc.removeFromCart(item.id);
                          final messenger = SnackBarHelper.showSnackBar(context, '${item.product.title} removed from cart');
                          return messenger;
                          },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

    );
  }
}
