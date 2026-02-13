import 'package:clothing_app/screens/profilepage/profile_models.dart';
import 'package:clothing_app/screens/splashpage/splash_screen.dart';
import 'package:flutter/material.dart';

import 'package:clothing_app/reusable_widgets/reusable_button.dart';
import 'package:clothing_app/screens/profilepage/profile_bloc.dart';

import '../../utils/constant_variables.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ProfileBloc(context, this);
  }

  @override
  void dispose() {
    _bloc.dispose();
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
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("No profile found!"),
                  );
                }

                final profile = snapshot.data!;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(deviceWidth / 30),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(deviceWidth / 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(deviceHeight * 0.02),
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
                              MaterialPageRoute(builder: (_) => const SplashScreen()),
                                  (route) => false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
          ],
        ),
      ),
    );
  }

}
