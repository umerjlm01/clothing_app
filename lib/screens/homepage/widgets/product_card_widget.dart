import 'package:cached_network_image/cached_network_image.dart';
import 'package:clothing_app/reusable_widgets/icon_button.dart';
import 'package:clothing_app/screens/homepage/child_pages/product_details_screen.dart';
import 'package:clothing_app/screens/homepage/homepage_bloc.dart';
import 'package:clothing_app/screens/homepage/homepage_models.dart';
import 'package:clothing_app/reusable_widgets/snack_bar_helper.dart';
import 'package:clothing_app/utils/constant_variables.dart';
import 'package:flutter/material.dart';
import '../../../reusable_widgets/shimmer_loaders.dart';

class ProductCardWidget extends StatefulWidget {
  final Product product;
  final HomepageBloc bloc;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.bloc,
  });

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    _navigateToDetails();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  Future<void> _navigateToDetails() async {
    // Precache the image for smooth Hero animation
    await precacheImage(
      CachedNetworkImageProvider(widget.product.imageUrl),
      context,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ProductDetail(bloc: widget.bloc, product: widget.product),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: deviceWidth / 60,horizontal: deviceWidth / 200),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: RepaintBoundary(
            child: Card(
              shadowColor: Colors.black26,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(deviceHeight * 0.02),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Hero(
                    tag: product.id,
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(deviceHeight * 0.02),
                      ),
                      child: CachedNetworkImage(
                        height: deviceHeight * 0.13,
                        width: double.infinity,
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => SizedBox(
                          height: deviceHeight * 0.13,
                          width: double.infinity,
                          child: ShimmerLoaders.imagePlaceholder(),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  ),

                  SizedBox(height: deviceHeight / 60),

                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: deviceWidth / 30),
                    child: Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: deviceHeight / 60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Price + Cart
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      deviceWidth / 70,
                      deviceHeight / 70,
                      deviceWidth / 70,
                      deviceHeight / 70,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: deviceWidth / 40,
                            vertical: deviceHeight / 90,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(
                              deviceHeight * 0.02,
                            ),
                          ),
                          child: Text(
                            '\$${product.price}',
                            style: TextStyle(
                              fontSize: deviceHeight / 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildCartControl(product),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartControl(Product product) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOutBack,
      switchOutCurve: Curves.easeInBack,
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: product.quantity == 0
          ? AppIconButton(
              key: const ValueKey('addToCartButton'),
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                widget.bloc.addToCart(product);
                SnackBarHelper.showSnackBar(
                  context,
                  '${product.title} added to cart',
                );
              },
            )
          : Row(
              key: ValueKey('quantityRow_${product.id}'),
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    widget.bloc.decreaseQuantity(product);
                  },
                ),
                Text(
                  product.quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    widget.bloc.increaseQuantity(product);
                  },
                ),
              ],
            ),
    );
  }
}
