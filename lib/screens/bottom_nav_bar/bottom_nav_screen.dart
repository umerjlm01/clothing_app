import 'package:flutter/material.dart';
import 'package:clothing_app/screens/bottom_nav_bar/bottom_nav_bloc.dart';
import '../../reusable_widgets/bottom_nav_bar.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late BottomNavBloc _bloc;

  @override
  void initState() {
    if (mounted) {
      _bloc = BottomNavBloc(context, this);
      super.initState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _bloc.currentIndexStream,
      initialData: 0,
      builder: (context, snapshot) {
        final index = snapshot.data!;

        return Scaffold(
          body: IndexedStack(
            index: index,
            children: _bloc.screens,
          ),
          bottomNavigationBar: BottomNavBar(
            index: index,
            onTap: (index) => _bloc.updateIndex(index),
          ),
        );
      },
    );
  }
}
