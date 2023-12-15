import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ordonez_vet/clientScreens/clientAppointmentsScreen.dart';
import 'package:ordonez_vet/clientScreens/clientCalendarScreen.dart';
import 'package:ordonez_vet/clientScreens/clientPetsScreen.dart';
import 'package:ordonez_vet/clientScreens/clientProfile.dart';
import 'package:quickalert/quickalert.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  String? mtoken = " ";
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    requestPermission();
    getToken();
    initInfo();
  }

  initInfo() {
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/launcher_icon');
    var IOSInitialize = const DarwinInitializationSettings();

    var initializationSettings =
        InitializationSettings(android: androidInitialize, iOS: IOSInitialize);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        Navigator.push(context,
            CupertinoPageRoute(builder: (BuildContext context) {
          return const ClientAppointmentsScreen();
        }));
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("................onMessage.............");
      print(
          "onMessageL: ${message.notification?.title} / ${message.notification?.body}");

      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        message.notification!.body.toString(),
        htmlFormatBigText: true,
      );

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'ordonez',
        'ordonez',
        importance: Importance.max,
        styleInformation: bigTextStyleInformation,
        priority: Priority.max,
        playSound: true,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: const DarwinNotificationDetails());
      await flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title,
        message.notification?.body,
        platformChannelSpecifics,
        payload: message.data['body'],
      );
    });
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mtoken = token;

        print('My token is $mtoken');
      });

      saveToken(token!);
    });
  }

  void saveToken(String token) async {
    User? user = FirebaseAuth.instance.currentUser;

    // Get the current list of device tokens
    DocumentSnapshot<Map<String, dynamic>> userTokensDoc =
        await FirebaseFirestore.instance
            .collection("UserTokens")
            .doc(user!.uid)
            .get();

    List<String> currentTokens = [];

    // Check if the document exists and 'deviceTokens' is not null
    if (userTokensDoc.exists) {
      // If the document exists, retrieve the current tokens
      dynamic data = userTokensDoc.data();
      if (data != null && data['deviceTokens'] != null) {
        currentTokens = List<String>.from(data['deviceTokens']);
      }
    }

    // Add the new token to the list if it's not already present
    if (!currentTokens.contains(token)) {
      currentTokens.add(token);

      // Save the updated list of device tokens
      await FirebaseFirestore.instance
          .collection("UserTokens")
          .doc(user.uid)
          .set({
        'deviceTokens': currentTokens,
      });
    }
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined permission');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordonez Vet Clinic'),
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.confirm,
                title: 'Sign out?',
                onConfirmBtnTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
              );
            },
            icon: const Icon(Icons.logout)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (BuildContext context) =>
                        const ClientProfileScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0174BE),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16), // Adjust the radius as needed
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text('My Profile'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (BuildContext context) =>
                        const ClientPetsScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0174BE),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16), // Adjust the radius as needed
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text('My Pets'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) =>
                        const ClientAppointmentsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0174BE),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16), // Adjust the radius as needed
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text('My Appointments'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) =>
                        const ClientCalendarScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0174BE),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16), // Adjust the radius as needed
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_to_queue_sharp,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text('Schedule Appointment'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
