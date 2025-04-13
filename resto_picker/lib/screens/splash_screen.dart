/*
This file implements the application's splash screen that displays
while the app is initializing and automatically navigates to the home screen.
*/

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:resto_picker/screens/home_screen.dart';

/*
Splash screen widget that shows branding and loading indicator.
This screen:
- Displays the app logo and name
- Shows a loading spinner
- Automatically navigates to HomeScreen after 5 seconds

 */
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// handles the timer and navigation to homescreen
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // start timer upto 5 seconds and navigates to homescreen
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // SVG Rectangle logo at center
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 220,
              left: 0,
              right: 0,
              child: Center(
                child: SvgPicture.asset(
                  'lib/assets/rectangle_svg.svg',
                  width: 320,
                  height: 140,
                ),
              ),
            ),
            // App title text is position above the loading spinner
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 200,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 200,
                  child: const Text(
                    'RESTO PICKER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Righteous',
                      fontSize: 45,
                      height: 1.07,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // loading spinner below the app title
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: SpinKitCircle(color: Colors.yellow, size: 50.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
