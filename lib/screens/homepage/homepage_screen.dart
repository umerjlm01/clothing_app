import 'package:cached_network_image/cached_network_image.dart';
import 'package:clothing_app/reusable_widgets/icon_button.dart';
import 'package:clothing_app/screens/homepage/child_pages/product_details_screen.dart';
import 'package:clothing_app/screens/homepage/homepage_bloc.dart';
import 'package:clothing_app/screens/homepage/homepage_models.dart';
import 'package:clothing_app/screens/homepage/widgets/hero_banner/hero_banner.dart';
import 'package:clothing_app/screens/homepage/widgets/hero_banner/hero_banner_handler.dart';
import 'package:clothing_app/utils/constant_variables.dart';
import 'package:flutter/material.dart';
import '../../reusable_widgets/snack_bar_helper.dart';


class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen>
    with SingleTickerProviderStateMixin {
  late HomepageBloc _bloc;
  late HeroBannerHandler _heroBannerHandler;

  @override
  void initState() {
    super.initState(); // Always call super first
    _bloc = HomepageBloc(context, this);
    _heroBannerHandler = HeroBannerHandler(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.of(context)) {
      // Only trigger animation when page becomes active
      _heroBannerHandler.resetAnimation();
      _heroBannerHandler.animationPlay();
    }
  }


  @override
  void dispose() {
    _bloc.dispose();
    _heroBannerHandler.animationDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // FIX: CustomScrollView must be OUTSIDE StreamBuilder to keep Banner persistent
      body: CustomScrollView(
        cacheExtent: deviceHeight * 2,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. PERSISTENT BANNER
          SliverAppBar(
            // shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
            expandedHeight: deviceHeight * 0.32,
            backgroundColor: Colors.white,
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
    child: HeroBanner(handler: _heroBannerHandler)),

            ),
            floating: true,
            pinned: true,
          ),

          // 2. DATA-DRIVEN GRID
          StreamBuilder<List<Product>>(
            stream: _bloc.productsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final products = snapshot.data ?? [];

              // Trigger Banner Animation once data is ready
              if (products.isNotEmpty && !_bloc.animationStarted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_bloc.animationStarted) {
                    _heroBannerHandler.animationPlay();
                    _bloc.animationStarted = true;
                  }
                });
              }


              if (products.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No products found")),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: deviceWidth / 60),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = products[index];
                      if (index < 6) {
                        return SlideTransition(
                          position: _heroBannerHandler.titleSlide,
                          child: FadeTransition(
                            opacity: _heroBannerHandler.fade,
                            child: productCard(product),
                          ),
                        );
                      }
                      return productCard(product);
                    },
                    childCount: products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                ),
              );
            },
          ),

          // Bottom padding to ensure last items aren't cut off by NavBars
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        ],
      ),
    );
  }


  Widget productCard(Product product) {
    return Padding(padding: EdgeInsetsGeometry.all(deviceWidth / 60),
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

                GestureDetector(
                  onTap: () async {
                    // Precache the image for smooth Hero animation
                    await precacheImage(
                      CachedNetworkImageProvider(product.imageUrl),
                      context,
                    );

                    // Navigate after precaching
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetail(
                          bloc: _bloc,
                          product: product,
                        ),
                      ),
                    );
                  },
                  child: Hero(
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
                        placeholder: (context, url) => Container(
                          height: deviceHeight * 0.13,
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.broken_image),
                      ),
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
                      deviceWidth / 70, deviceHeight / 70, deviceWidth / 70,
                      deviceHeight / 70),
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
                      buildCartControl(product)
                    ],
                  ),
                ),
              ],
            ),


          ),
        ));
  }

  Widget buildCartControl(Product product) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        // Fade + slide animation
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axis: Axis.horizontal,
            child: child,
          ),
        );
      },
      child: product.quantity == 0
          ? AppIconButton(
        key: const ValueKey('addToCartButton'), // important for AnimatedSwitcher
        icon: const Icon(Icons.shopping_cart_outlined),
        onPressed: () {
          _bloc.addToCart(product);
          SnackBarHelper.showSnackBar(
              context, '${product.title} added to cart');
        },
      )
          : Row(
        key: ValueKey('quantityRow_${product.id}'), // unique key per product
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              _bloc.decreaseQuantity(product);
            },
          ),
          Text(product.quantity.toString()),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _bloc.increaseQuantity(product);
            },
          ),
        ],
      ),
    );
  }


}

