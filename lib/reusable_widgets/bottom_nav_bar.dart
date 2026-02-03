import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.index, required this.onTap});
  final int index;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white38,
      currentIndex: index,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      items:  [
        BottomNavigationBarItem(icon: GestureDetector(onTap: ()=> onTap(0) ,child: Icon(Icons.home)), label: 'Home'),
        BottomNavigationBarItem(icon: GestureDetector(onTap: ()=> onTap(1) ,child: Icon(Icons.shopping_cart)), label: 'Cart'),
        BottomNavigationBarItem(icon: GestureDetector(onTap: ()=> onTap(2) ,child: Icon(Icons.person)), label: 'Profile'),
        ]

    );
  }
}
