import 'package:cached_network_image/cached_network_image.dart';
import 'package:clothing_app/reusable_widgets/icon_button.dart';
import 'package:clothing_app/screens/homepage/homepage_bloc.dart';
import 'package:clothing_app/screens/homepage/homepage_models.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:clothing_app/utils/constant_variables.dart';
import 'package:flutter/material.dart';
import '../../reusable_widgets/app_bar.dart';


class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  late HomepageBloc _bloc;
  @override
  void initState() {
    if (mounted) {
      _bloc = HomepageBloc(context, this);
      super.initState();
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
        title: Text(ConstantStrings.home, style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        elevation: 0,
      ),),

      body: StreamBuilder<List<Product>>(
        stream: _bloc.productsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!;


          if (products.isEmpty) {
            return Center(child: Text(ConstantStrings.noProducts));
          }

          return Padding(
            padding: EdgeInsets.all(deviceHeight / 75 ),
            child: GridView.builder(
              itemCount: products.length,
              gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: deviceWidth / 50,
                mainAxisSpacing: deviceHeight / 50,
                childAspectRatio: (deviceWidth / deviceHeight) / 0.7,
              ),
              itemBuilder: (context, index) {
                final product = products[index];





                return Card(
                  shadowColor: Colors.black26,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(deviceHeight * 0.02),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(deviceHeight * 0.02),
                        ),
                        child: CachedNetworkImage(
                          height: deviceHeight * 0.19,
                          width: double.infinity,
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => SizedBox(
                            height: deviceHeight * 0.19,
                            child:  Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => SizedBox(
                            height: deviceHeight * 0.19,
                            child: Center(
                              child: Icon(Icons.broken_image, size: deviceHeight / 60),
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
                        padding: EdgeInsets.fromLTRB(deviceWidth / 50, deviceHeight / 70, deviceWidth / 50, deviceHeight / 70),
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
                                  fontSize: deviceHeight / 60,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            AppIconButton(onPressed: () {_bloc.toggleAddToCart(product);
                              }, icon: Icon(Icons.add_shopping_cart))
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }




}
