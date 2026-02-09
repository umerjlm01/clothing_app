import 'package:clothing_app/reusable_widgets/snack_bar_helper.dart';
import 'package:clothing_app/reusable_widgets/text_form_field.dart';
import 'package:clothing_app/screens/profilepage/messages_models.dart';
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

            /// Chat Users
            SizedBox(
              height: deviceHeight / 10,
              child: FutureBuilder<List<Profile>>(
                future: _bloc.fetchUsers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];

                      return GestureDetector(
                        onTap: () {_bloc.createConversation(user.id);
                          SnackBarHelper.showSnackBar(context, "Chat with ${user.name}", isError: false);

                          },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: deviceWidth / 70, vertical: deviceHeight / 90),
                          padding: EdgeInsets.symmetric(horizontal: deviceWidth / 20, vertical: deviceHeight / 90),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(deviceHeight * 0.02),
                          ),
                          child: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: deviceHeight / 70,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            /// CHat box
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _bloc.messageStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chat = snapshot.data!;
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: chat.length,
                    itemBuilder: (context, index) {
                      final message = chat[chat.length - 1 - index];
                      final isMe =
                          message.senderId ==
                              _bloc.supabase.auth.currentUser?.id;

                      return Align(
                        alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextFormField(
                      label: 'Message',
                      controller: _bloc.messageController,
                      validator: (v) => null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _bloc.sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
