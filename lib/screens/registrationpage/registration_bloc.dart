import 'dart:developer';

import 'package:clothing_app/bloc/bloc.dart';
import 'package:clothing_app/screens/registrationpage/registration_model.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class RegistrationBloc extends Bloc{
  final BuildContext context;
  final State<StatefulWidget> state;
  RegistrationBloc(this.context, this.state);

  final GlobalKey<FormState>  _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final BehaviorSubject<Registration> _registrationStream = BehaviorSubject<Registration>.seeded(Registration(email: '', password: '', name: '', phone: ''));
  Stream<Registration> get registrationStream => _registrationStream.stream;
  
  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;
  TextEditingController get nameController => _nameController;
  TextEditingController get phoneController => _phoneController;
  GlobalKey<FormState> get formKey => _formKey;
  final supabase = Supabase.instance.client;
  
  Future<bool> register() async {
    if(!_formKey.currentState!.validate()){
     log('Not validate');
      return false;
    }
    try{
    final AuthResponse register = await supabase.auth.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      data: {"name": _nameController.text,
        "phone": _phoneController.text,
      },



    );
    if (register.user != null) {
      final Registration registration = Registration(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        phone: _phoneController.text,

      );
        if(!_isDisposed && !_registrationStream.isClosed){
      _registrationStream.add(registration);}
        return true;

    } else {
      _registrationStream.addError(register);
    }}
    catch(e){
      log(e.toString());
      return false;
    }
    return false;
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
    if (value == null){
      return ConstantStrings.enterPassword;
    }
    if (value.length < 6){
      return ConstantStrings.invalidPassword;
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null){
      return ConstantStrings.enterName;
    }
    return null;

  }
  String? validatePhone(String? value) {
    if(value == null){
      return ConstantStrings.enterPhone;
    }

    return null;

  }
  bool _isDisposed = false;
  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
   _registrationStream.close();
    // TODO: implement dispose
  }

}