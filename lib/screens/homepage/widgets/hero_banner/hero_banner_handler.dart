import 'package:flutter/material.dart';

class HeroBannerHandler {
  late final TickerProvider vsync;
  late AnimationController _controller;

  late Animation<Offset> titleSlide;
  late Animation<Offset> subtitleSlide;
  late Animation<double> fade;
  late Animation<Offset> easeInBack;


  AnimationController get animationController  => _controller;

  HeroBannerHandler({required this.vsync}) {
   _controller = AnimationController(
   duration: Duration(milliseconds: 800),
       vsync: vsync);

   titleSlide = Tween<Offset>(
     begin: const Offset(-1, 0),
     end: Offset.zero,
   ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
   
   subtitleSlide = Tween<Offset>(
     begin: const Offset(0, 1),
     end:  Offset.zero,
   ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
   fade = Tween<double>(
     begin: 0,
     end: 1
   ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

   easeInBack = Tween<Offset>(
     begin: const Offset(0, 1),
     end: Offset.zero,
   ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInBack));



  }

  void animationPlay() => _controller.forward();
  void stopAnimation() => _controller.stop();
  void resetAnimation() => _controller.reset();
  void animationDispose() => _controller.dispose();




}