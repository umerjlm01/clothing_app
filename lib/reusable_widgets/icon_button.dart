import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.onPressed, required this.icon,});
  final Function() onPressed;
  final Widget icon;
  final String text = '';


  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: icon,
    );}
}
