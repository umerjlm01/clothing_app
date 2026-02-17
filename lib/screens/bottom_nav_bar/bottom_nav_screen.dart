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


  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _bloc.currentIndexStream,
      initialData: 0,
      builder: (context, snapshot) {
        final index = snapshot.data ?? 0;

        return StreamBuilder<int>(
          stream: ChatListBloc.instance?.totalUnreadStream,
          initialData: 0,
          builder: (context, unreadSnapshot) {
            final totalUnread = unreadSnapshot.data ?? 0;

            return Scaffold(
              body: IndexedStack(
                index: index,
                children: _bloc.screens,
              ),
              bottomNavigationBar: BottomNavBar(
                index: index,
                onTap: (i) => _bloc.updateIndex(i),
                chatUnreadCount: totalUnread,
              ),
            );
          },
        );
      },
    );
  }
}

