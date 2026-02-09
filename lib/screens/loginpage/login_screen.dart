import 'package:flutter/material.dart';
import 'package:clothing_app/reusable_widgets/text_form_field.dart';
import 'package:clothing_app/screens/loginpage/login_bloc.dart';
import 'package:clothing_app/screens/loginpage/login_models.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:clothing_app/utils/constant_variables.dart';
import '../../reusable_widgets/app_bar.dart';
import '../../reusable_widgets/reusable_button.dart';
import '../bottom_nav_bar/bottom_nav_screen.dart';
import '../registrationpage/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late LoginBloc _bloc;

  @override
  void initState() {
    if (mounted) {
      _bloc = LoginBloc(context, this);
      super.initState();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _bloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(deviceHeight / 15),
          child: CustomAppBar(
            icon: const Icon(Icons.login),
            title: Text(ConstantStrings.login, style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            elevation: 0,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: deviceWidth / 15),
              child: StreamBuilder<Login>(
                stream: _bloc.loginStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }

                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(deviceHeight * 0.02),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(deviceHeight / 50),
                      child: Form(
                        key: _bloc.formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: deviceHeight / 15,
                            ),
                            SizedBox(height: deviceHeight / 50,),
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: deviceHeight / 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: deviceHeight / 50),
                            AppTextFormField(
                              label: ConstantStrings.email,
                              controller: _bloc.emailController,
                              validator: _bloc.validateEmail,
                            ),
                            SizedBox(height: deviceHeight / 50),
                            AppTextFormField(
                              label: ConstantStrings.password,
                              controller: _bloc.passwordController,
                              isPassword: true,
                              validator: _bloc.validatePassword,

                            ),
                            SizedBox(height: deviceHeight / 40),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                onPressed: () async {
                                  final success = _bloc.login();
                                  final navigator = Navigator.of(context);
                                  if (await success) {
                                    navigator.pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const BottomNavScreen()),
                                          (route) => false,
                                    );
                                  } else {
                                    return;
                                  }
                                },
                                name: ConstantStrings.login,
                              )

                            ),
                            SizedBox(height: deviceHeight / 40),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RegistrationScreen()), (route) => false);
                              },
                              child: Text(
                                "Don't have an account?"
                            ))
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
