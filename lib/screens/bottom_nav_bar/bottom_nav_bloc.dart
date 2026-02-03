import 'package:clothing_app/bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import '../cartpage/cart_screen.dart';
import '../homepage/homepage_screen.dart';
import '../profilepage/profile_screen.dart';

class BottomNavBloc extends Bloc {
  BuildContext context;
  State<StatefulWidget> state;
  BottomNavBloc(this.context, this.state);

 final BehaviorSubject<int> _currentIndex = BehaviorSubject.seeded(0);
  Stream<int> get currentIndexStream => _currentIndex.stream;
  int get currentIndex => _currentIndex.value;




late List<Widget> screens = [
  HomepageScreen(),
  CartScreen(),
  ProfileScreen(),
];

  void updateIndex(int index){
    _currentIndex.add(index);
  }

  @override
  void dispose() {
    _currentIndex.close();

    // TODO: implement dispose
  }



}