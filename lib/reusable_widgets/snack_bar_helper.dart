import 'package:clothing_app/reusable_widgets/snack_bar.dart';
import 'package:flutter/material.dart';

class SnackBarHelper{
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    final snackBar = SnackBar(content: CustomSnackBar(
      message: message,
      isError: isError,
    ),
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: 3),);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}



