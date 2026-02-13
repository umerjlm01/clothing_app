import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.index, required this.onTap, this.chatUnreadCount = 0, this.chatUnreadCountStream});
  final int index;
  final Function(int) onTap;
  final int chatUnreadCount;
  final Stream<int>? chatUnreadCountStream;


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
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () => onTap(2),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.message),
                if (chatUnreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        chatUnreadCount.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          label: 'Chat',
        ),
        BottomNavigationBarItem(icon: GestureDetector(onTap: ()=> onTap(3) ,child: Icon(Icons.person)), label: 'Profile'),
        ]

    );
  }
}
