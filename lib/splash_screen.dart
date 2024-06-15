import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'chat_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3), () {});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 150,
              child: Image.asset('assets/images/bot_roses.png'),
            ),
            const SizedBox(height: 20),
            Animate(
              effects: [FadeEffect(duration: 1000.ms), ScaleEffect(delay: 500.ms)],
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.pink, Colors.blue],
                  tileMode: TileMode.mirror,
                ).createShader(bounds),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Just for you, Princess',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,  // Necessary for ShaderMask to work
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
