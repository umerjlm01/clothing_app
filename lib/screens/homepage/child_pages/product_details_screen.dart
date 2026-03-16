import 'package:cached_network_image/cached_network_image.dart';
import 'package:clothing_app/screens/homepage/homepage_bloc.dart';
import 'package:flutter/material.dart';
import '../../../reusable_widgets/snack_bar_helper.dart';
import '../homepage_models.dart';
import '../../../reusable_widgets/shimmer_loaders.dart';

class ProductDetail extends StatefulWidget {
  final HomepageBloc bloc;
  final Product product; // pass the product instead of just id

  const ProductDetail({super.key, required this.bloc, required this.product});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  late Future<Product> _futureProduct;
  HomepageBloc get _bloc => widget.bloc;

  @override
  void initState() {
    super.initState();
    // Load full product details in background
    _futureProduct = _bloc.getProductDetailsOnce(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product; // immediate data for Hero
    return Scaffold(
      body: Hero(
        tag: product.id,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<Product>(
                future: _futureProduct,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Only show placeholders for details, not the image
                    return ShimmerLoaders.productDetails();
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }

                  final productDetails = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productDetails.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${productDetails.price}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          productDetails.description,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        // size/color widgets etc.
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: FilledButton(
            onPressed: () {
              _bloc.addToCart(product);
              SnackBarHelper.showSnackBar(
                context,
                '${product.title} added to cart',
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                product.quantity == 0 ? 'Add to Cart' : 'Added to cart',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
