import 'package:airbnb_scheduler/screens/logsScreen.dart';
import 'package:airbnb_scheduler/screens/staff/calendarScreenStaff.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quickalert/quickalert.dart';

class mainScreenStaff extends StatefulWidget {
  const mainScreenStaff({super.key});

  @override
  State<mainScreenStaff> createState() => _mainScreenStaffState();
}

class _mainScreenStaffState extends State<mainScreenStaff> {
  String? mtoken = " ";
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Stream<List<String>> getData() {
    return FirebaseFirestore.instance.collection('units').snapshots().map(
        (QuerySnapshot querySnapshot) =>
            querySnapshot.docs.map((doc) => doc.id).toList());
  }

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
          return const logsScreen();
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
        'lodge',
        'lodge',
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
        title: const Text('Lodge'),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    CupertinoPageRoute(builder: (BuildContext context) {
                  return const logsScreen();
                }));
              },
              icon: const Icon(Icons.history))
        ],
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
      body: StreamBuilder<List<dynamic>>(
          stream: getData(),
          builder:
              (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error.toString()}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            List<dynamic> data = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 5, crossAxisSpacing: 5),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .push(CupertinoPageRoute(builder: (context) {
                        return calendarScreenStaff(unitName: data[index]);
                      }));
                    },
                    child: GridTile(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xff862B0D),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text(
                            data[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
    );
  }
}
