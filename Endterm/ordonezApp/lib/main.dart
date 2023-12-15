import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ordonez_vet/authGate.dart';
import 'package:ordonez_vet/firebase_options.dart';

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
        backgroundColor: const Color(0xffFFF0CE),
        duration: 3000,
        splashTransition: SplashTransition.scaleTransition,
        splash: const CircleAvatar(
          backgroundColor: Color(0xff0C356A),
          maxRadius: 800,
          child: Icon(
            Icons.pets_outlined,
            size: 50,
            color: Color(0xffFFC436),
          ),
        ),
        nextScreen: const authGate(),
      ),
      theme: ThemeData(
          appBarTheme: const AppBarTheme(color: Color(0xff0C356A)),
          scaffoldBackgroundColor: const Color(0xffFFF0CE),
          cardColor: const Color(
            0xffFFF0CE,
          )),
    );
  }
}
