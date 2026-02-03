import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key, required this.icon, required this.title, required this.centerTitle, required this.elevation});
  final Widget icon;
  final Widget title;
  final bool centerTitle;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      centerTitle: centerTitle,
      elevation: elevation,
      leading: icon,
    );
  }
}
