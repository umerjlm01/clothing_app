import 'package:flutter/material.dart';
import 'package:clothing_app/reusable_widgets/app_bar.dart';
import 'package:clothing_app/reusable_widgets/text_form_field.dart';
import 'package:clothing_app/screens/registrationpage/registration_bloc.dart';
import 'package:clothing_app/screens/registrationpage/registration_model.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:clothing_app/utils/constant_variables.dart';

import '../../animations/animation_handler.dart';
import '../loginpage/login_screen.dart';
import '../../reusable_widgets/shimmer_loaders.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with SingleTickerProviderStateMixin {
  late RegistrationBloc _bloc;
  late AnimationHandler _animationHandler;


  @override
  void initState() {
    if (mounted) {
      _bloc = RegistrationBloc(context, this);
      _animationHandler = AnimationHandler(vsync: this);
      _animationHandler.animationPlay();
      super.initState();
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
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(deviceHeight / 15),
          child: CustomAppBar(
            icon: const Icon(Icons.person_add),
            title: Text(ConstantStrings.register, style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            elevation: 0,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: deviceWidth / 15),
              child: StreamBuilder<Registration>(
                stream: _bloc.registrationStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ShimmerLoaders.circular();
                  }

                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }

                  return SlideTransition(
                    position: _animationHandler.easeInBack,
                    child: FadeTransition(
                      opacity: _animationHandler.fade,
                    child: Card(
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
                                Icons.person_add_alt_1,
                                size: deviceHeight / 15,
                              ),
                               SizedBox(height: deviceHeight / 50),
                               Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: deviceHeight / 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: deviceHeight / 50),
                              AppTextFormField(
                                label: ConstantStrings.name,
                                controller: _bloc.nameController,
                                validator: _bloc.validateName,
                                onTapVisible: () {},
                              ),
                              SizedBox(height: deviceHeight / 50),
                              AppTextFormField(
                                label: ConstantStrings.email,
                                controller: _bloc.emailController,
                                validator: _bloc.validateEmail,
                                onTapVisible: () {},
                              ),
                              SizedBox(height: deviceHeight / 50),
                              AppTextFormField(
                                label: ConstantStrings.phone,
                                controller: _bloc.phoneController,
                                validator: _bloc.validatePhone,
                                onTapVisible: () {},
                              ),
                              SizedBox(height: deviceHeight / 50),
                              StreamBuilder<bool>(
                                stream: _bloc.obscureTextStream,
                                builder: (context, snapshot) {
                                  return AppTextFormField(
                                    label: ConstantStrings.password,
                                    controller: _bloc.passwordController,
                                    isPassword: true,
                                    validator: _bloc.validatePassword,
                                    isObscure: snapshot.data ?? true,
                                    onTapVisible: _bloc.toggleVisiblePassword,
                                  );
                                },
                              ),
                              SizedBox(height: deviceHeight / 40),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                   final success = _bloc.register();
                                    final navigator = Navigator.of(context);
                                    if (await success) {

                                  navigator.pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);}
                                    else{
                                      return;

                                    }
                                    },
                                  child: Text(ConstantStrings.register),
                                ),
                              ),
                              SizedBox(height: deviceHeight / 40),
                              GestureDetector(
                                  onTap: () {
                                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                                  },
                                  child: Text(
                                      "Already have an account?"
                                  ))
                            ],
                          ),
                        ),
                      ),
                    ),
                    ) );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
