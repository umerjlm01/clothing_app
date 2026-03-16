import 'package:clothing_app/screens/homepage/widgets/hero_banner/hero_banner_handler.dart';
import 'package:flutter/material.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key, required this.handler});
  final HeroBannerHandler handler;



  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner>
with SingleTickerProviderStateMixin{
  @override
  void initState() {
    // TODO: implement initState
    super.initState();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.handler.animationPlay();
    });
  }


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        children: [

           Positioned.fill(child: Image.asset('assets/images/hero_banner.jpg', fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            )),

          Padding(padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SlideTransition(position: widget.handler.titleSlide,
              child: Text("Welcome to Clothing App", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
              SlideTransition(position: widget.handler.subtitleSlide,
              child: Text('UpTo 40% OFF', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))]
          ),)
      ]
      ),
    );
  }
}
