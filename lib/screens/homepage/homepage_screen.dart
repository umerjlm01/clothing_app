import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:clothing_app/screens/homepage/widgets/product_card_widget.dart';
import 'package:clothing_app/screens/homepage/homepage_bloc.dart';
import 'package:clothing_app/screens/homepage/homepage_models.dart';
import 'package:clothing_app/screens/homepage/widgets/hero_banner/hero_banner.dart';
import 'package:clothing_app/animations/animation_handler.dart';
import 'package:clothing_app/utils/constant_variables.dart';
import 'package:flutter/material.dart';
import '../../reusable_widgets/shimmer_loaders.dart';


class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen>
    with SingleTickerProviderStateMixin {
  late HomepageBloc _bloc;
  late AnimationHandler _animationHandler;

  @override
  void initState() {
    super.initState(); // Always call super first
    _bloc = HomepageBloc(context, this);
    _animationHandler = AnimationHandler(vsync: this);
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
      backgroundColor: Colors.white,
      body: AnimationLimiter(
        child: RefreshIndicator(
          onRefresh: () => _bloc.refresh(),
          child: CustomScrollView(
            controller: _bloc.scrollController,
            cacheExtent: deviceHeight * 2,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
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
    child: HeroBanner(handler: _animationHandler)),

            ),
            floating: true,
            pinned: true,
          ),

          StreamBuilder<List<Product>>(
            stream: _bloc.productsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return SliverFillRemaining(
                  child: ShimmerLoaders.grid(),
                );
              }

              final products = snapshot.data ?? [];

              // Trigger Banner Animation once data is ready
              if (products.isNotEmpty && !_bloc.animationStarted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_bloc.animationStarted) {
                    _animationHandler.animationPlay();
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
                          position: _animationHandler.titleSlide,
                          child: FadeTransition(
                            opacity: _animationHandler.fade,
                            child: AnimationConfiguration.staggeredGrid(
                              position: index,
                              duration: const Duration(milliseconds: 600),
                              columnCount: 2,
                              child: ScaleAnimation(
                                scale: 0.9,
                                child: FadeInAnimation(
                                  child: ProductCardWidget(
                                    product: product,
                                    bloc: _bloc,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        columnCount: 2,
                        child: ScaleAnimation(
                          scale: 0.9,
                          child: FadeInAnimation(
                            child: ProductCardWidget(
                              product: product,
                              bloc: _bloc,
                            ),
                          ),
                        ),
                      );
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

          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        ],
      ),
    ),
    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bloc.scrollToTop,
        backgroundColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        hoverElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(deviceWidth / 10)),
        child: Container(
            width: deviceWidth / 2,
            height: deviceWidth / 2,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(deviceWidth / 10),),
            child: Icon(Icons.arrow_upward, size: deviceWidth / 10)),
      )
    );
  }
}

