import 'package:clothing_app/screens/profilepage/profile_models.dart';
import 'package:clothing_app/screens/splashpage/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:clothing_app/reusable_widgets/reusable_button.dart';
import 'package:clothing_app/screens/profilepage/profile_bloc.dart';

import '../../utils/constant_variables.dart';
import '../../animations/animation_handler.dart';
import '../../reusable_widgets/shimmer_loaders.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late ProfileBloc _bloc;
  late AnimationHandler _animationHandler;

  @override
  void initState() {
    super.initState();
    _bloc = ProfileBloc(context, this);
    _animationHandler = AnimationHandler(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.of(context)) {
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
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            ///Profile
            FutureBuilder<Profile>(
              future: _bloc.getProfile(),
              initialData: Profile(id: '', name: '', email: '', phone: ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ShimmerLoaders.profile();
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No profile found!"),
                  );
                }

                final profile = snapshot.data!;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(deviceWidth / 30),
                  child: SlideTransition(
                    position: _animationHandler.titleSlide,
                    child: FadeTransition(
                      opacity: _animationHandler.fade,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(deviceWidth / 30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                deviceHeight * 0.02,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: deviceHeight / 15,
                                  backgroundColor: Colors.grey.shade300,
                                  child: Icon(
                                    Icons.person,
                                    size: deviceHeight / 10,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: deviceHeight / 50),
                                Text(
                                  profile.name,
                                  style: TextStyle(
                                    fontSize: deviceHeight / 50,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: deviceHeight / 80),
                                Text(
                                  profile.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: deviceHeight / 50,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (profile.phone != null) ...[
                                  SizedBox(height: deviceHeight / 80),
                                  Text(
                                    profile.phone!,
                                    style: TextStyle(
                                      fontSize: deviceHeight / 50,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: deviceHeight / 40),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              name: 'Logout',
                              onPressed: () {
                                _bloc.logout();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SplashScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                          SizedBox(height: deviceHeight / 25),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Featured Articles",
                              style: TextStyle(
                                fontSize: deviceHeight / 45,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          SizedBox(height: deviceHeight / 60),
                          _buildBlogSection(),
                          SizedBox(height: deviceHeight / 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogSection() {
    final blogs = [
      {
        "title": "Summer Collection 2026: What's Trending",
        "image":
            "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3",
        "date": "Mar 10, 2026",
      },
      {
        "title": "Sustainable Fashion: Brands to Watch",
        "image":
            "https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3",
        "date": "Mar 05, 2026",
      },
    ];

    return SizedBox(
      height: deviceHeight * 0.26,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: blogs.length,
        itemBuilder: (context, index) {
          final blog = blogs[index];
          return Container(
            width: deviceWidth * 0.65,
            margin: EdgeInsets.only(
              right: deviceWidth / 25,
              bottom: deviceHeight / 100,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(deviceHeight * 0.02),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(deviceHeight * 0.02),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: blog['image']!,
                    height: deviceHeight * 0.15,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: deviceHeight * 0.15,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: deviceHeight / 70,
                      vertical: deviceHeight / 90,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          blog['title']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: deviceHeight / 60,
                            height: 1.2,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          blog['date']!,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: deviceHeight / 75,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
