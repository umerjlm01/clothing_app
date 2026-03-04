import 'package:clothing_app/screens/cartpage/cart_bloc.dart';
import 'package:flutter/material.dart';
import 'package:clothing_app/screens/bottom_nav_bar/bottom_nav_bloc.dart';
import '../../reusable_widgets/bottom_nav_bar.dart';
import '../chat_list_page/chat_list_bloc.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late BottomNavBloc _bloc;


  @override
  void initState() {
    super.initState();
    _bloc = BottomNavBloc(context, this);
    _bloc.initializeFCM();
    initPush();

  }
  void initPush()async{
    await _bloc.initZego();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _bloc.currentIndexStream,
      initialData: 0,
      builder: (context, indexSnapshot) {
        final index = indexSnapshot.data ?? 0;

        return StreamBuilder<int>(
          stream: ChatListBloc.instance?.totalUnreadStream,
          initialData: 0,
          builder: (context, unreadSnapshot) {
            final totalUnread = unreadSnapshot.data ?? 0;

            return StreamBuilder<int>(
              stream: CartBloc.instance?.totalQuantityStream,
              initialData: 0,
              builder: (context, cartSnapshot) {
                final totalQuantity = cartSnapshot.data ?? 0;

                return Scaffold(
                  body: IndexedStack(
                    index: index,
                    children: _bloc.screens,
                  ),
                  bottomNavigationBar: BottomNavBar(
                    index: index,
                    onTap: (i) => _bloc.updateIndex(i),
                    chatUnreadCount: totalUnread,
                    cartCount: totalQuantity, // Pass totalQuantity to your BottomNavBar
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

