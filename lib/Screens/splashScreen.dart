import 'package:examinator/Screens/login.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: AnimatedSplashScreen(
            splash: Transform.scale(
              scale: 5,
              child: LottieBuilder.asset(
                'assets/images/splash.json',
              ),
            ),
            nextScreen: LoginPage(),
          ),
        ),
      ),
    );
  }
}
