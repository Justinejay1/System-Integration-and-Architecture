import 'dart:io';
import 'package:airbnb_scheduler/authGate.dart';
import 'package:airbnb_scheduler/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message ${message.messageId}');
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.getInitialMessage();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const run());
}

class run extends StatelessWidget {
  const run({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreen(
        backgroundColor: const Color(0xffFAECD6),
        duration: 3000,
        splashTransition: SplashTransition.scaleTransition,
        splash: const CircleAvatar(
          backgroundColor: Color(0xff4E6C50),
          maxRadius: 800,
          child: Icon(
            Icons.date_range,
            size: 50,
            color: Colors.white,
          ),
        ),
        nextScreen: const authGate(),
      ),
      theme: ThemeData(
          appBarTheme: const AppBarTheme(color: Color(0xff4E6C50)),
          scaffoldBackgroundColor: const Color(0xffFAECD6),
          cardColor: const Color(
            0xffF2DEBA,
          )),
    );
  }
}
