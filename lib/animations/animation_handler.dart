import 'package:flutter/material.dart';

class AnimationHandler {
  late final TickerProvider vsync;
  late AnimationController _controller;

  late Animation<Offset> titleSlide;
  late Animation<Offset> subtitleSlide;
  late Animation<double> fade;
  late Animation<Offset> easeInBack;


  AnimationController get animationController  => _controller;

  AnimationHandler({required this.vsync}) {
   _controller = AnimationController(
   duration: const Duration(milliseconds: 1200),
       vsync: vsync);

   titleSlide = Tween<Offset>(
     begin: const Offset(-0.8, 0),
     end: Offset.zero,
   ).animate(CurvedAnimation(
       parent: _controller,
       curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)));
   
   subtitleSlide = Tween<Offset>(
     begin: const Offset(0, 0.8),
     end:  Offset.zero,
   ).animate(CurvedAnimation(
       parent: _controller,
       curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack)));
       
   fade = Tween<double>(
     begin: 0,
     end: 1
   ).animate(CurvedAnimation(
       parent: _controller,
       curve: const Interval(0, 0.5, curve: Curves.easeIn)));

   easeInBack = Tween<Offset>(
     begin: const Offset(0, 1),
     end: Offset.zero,
   ).animate(CurvedAnimation(
       parent: _controller,
       curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack)));
  }

  void animationPlay() => _controller.forward();
  void stopAnimation() => _controller.stop();
  void resetAnimation() => _controller.reset();
  void animationDispose() => _controller.dispose();




}