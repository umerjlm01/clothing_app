import 'package:flutter/material.dart';

import '../utils/constant_variables.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    required this.validator,
    this.isObscure = false,
    required this.onTapVisible,


  });

  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final bool? isObscure;
  final VoidCallback? onTapVisible;


  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? (isObscure ?? false) : false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: isPassword
            ? GestureDetector(
          onTap: onTapVisible,
          child: Icon(
            isObscure! ? Icons.visibility_off : Icons.visibility
          ),
        ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(deviceHeight * 0.02),
          borderSide: const BorderSide(color: Colors.grey),
        ),

      ),
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.text,
    );
  }
}
