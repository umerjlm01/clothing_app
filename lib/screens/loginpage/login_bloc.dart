import 'dart:developer';
import 'package:clothing_app/bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../local_notifications/navigation_helper.dart';
import '../../utils/constant_strings.dart';
import '../../utils/constant_variables.dart';
import '../../utils/secure_storage.dart';
import 'login_models.dart';

class LoginBloc extends Bloc {

  BuildContext context;
  State<StatefulWidget> state;
  LoginBloc(this.context, this.state);

  final BehaviorSubject<Login> _loginStream = BehaviorSubject<Login>.seeded(Login(email: '', password: ''));
  Stream<Login> get loginStream => _loginStream.stream;



  final storage = SecureStorage();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;
  GlobalKey<FormState> get formKey => _formKey;

  Future<bool> login() async {
    if (!_formKey.currentState!.validate()) {
      log('Form not valid');
      return false;
    }
    showLoadingDialog(navigatorKey.currentContext!);

    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        debugPrint("Login Failed");
        return false;
      }

      debugPrint("Login Successful");

      final Login login = Login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if(!_isDisposed && !_loginStream.isClosed){
      _loginStream.add(login);}

      if (response.session != null) {
        await storage.write('accessToken', response.session!.accessToken);
        log('Token saved securely: ${response.session!.accessToken}');
      }

      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
    finally{
      Navigator.pop(navigatorKey.currentContext!);
    }
  }


  String? validateEmail(String? value) {
    if (value == null){
      return ConstantStrings.enterEmail;
    }
    if (!value.contains('@')){
      return ConstantStrings.invalidEmail;
    }
    if (!value.contains('.com')){
      return ConstantStrings.invalidEmail;
    }
return null;
  }

  String? validatePassword(String? value) {
    if(value == null){
      return ConstantStrings.enterPassword;
    }
    if(value.length < 6){
      return ConstantStrings.invalidPassword;
    }
    return null;

    }


  void showLoadingDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Lottie.asset(
          'assets/lottie/loading.json',
          width: deviceWidth / 3,
          fit: BoxFit.contain,
          delegates: LottieDelegates(
            values: [
              ValueDelegate.color(const [
                '**',
              ], value: Theme.of(context).primaryColor),
            ],
          ),
          repeat: true,
        ),
      ),
    );
  }

 bool _isDisposed = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loginStream.close();
    _isDisposed = true;
  }
  }
