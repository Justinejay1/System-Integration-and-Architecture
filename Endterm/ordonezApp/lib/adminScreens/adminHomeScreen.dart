import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:ordonez_vet/adminScreens/adminAppointmentsScreen.dart';
import 'package:ordonez_vet/adminScreens/adminCalendarScreen.dart';
import 'package:ordonez_vet/adminScreens/adminClientsScreen.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter/services.dart' show rootBundle;
import "package:http/http.dart" as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:intl/intl.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _qrBarCodeScannerDialogPlugin = QrBarCodeScannerDialog();
  String? code;

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
          return const AdminAppointmentsScreen();
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

  Future<String> obtainCredentials() async {
    final keyFileData =
        await rootBundle.loadString('assets/service-account.json');
    final keyFile =
        ServiceAccountCredentials.fromJson(json.decode(keyFileData));

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await auth.clientViaServiceAccount(keyFile, scopes);
    final accessToken = client.credentials.accessToken.data;

    return accessToken;
  }

// Get all tokens
  Future<List<String>> getClientDeviceTokens(String id) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> appointmentSnapshot =
          await FirebaseFirestore.instance
              .collection("appointments")
              .doc("schedules")
              .get();

      List<dynamic> appointments =
          appointmentSnapshot.data()?['appointments'] ?? [];

      Map<String, dynamic>? targetAppointment = appointments
          .cast<Map<String, dynamic>>()
          .firstWhere((appointment) => appointment['id'] == id);

      String userUid = targetAppointment['user_uid'] ?? '';

      // Get the device tokens for the specified user ID
      DocumentSnapshot<Map<String, dynamic>> userTokensSnapshot =
          await FirebaseFirestore.instance
              .collection("UserTokens")
              .doc(userUid)
              .get();

      // Check if the 'deviceTokens' field exists and is not null
      dynamic data = userTokensSnapshot.data();
      if (data != null && data['deviceTokens'] != null) {
        // Return the device tokens for the specified user
        List<String> userTokens = List<String>.from(data['deviceTokens']);
        return userTokens;
      } else {
        // Return an empty list if no device tokens found
        return [];
      }
    } catch (e) {
      print('Error getting client device tokens: $e');
      return [];
    }
  }

  //push notif
  void sendPushNotification(String body, String title, String uid) async {
    try {
      // Obtain FCM credentials
      final result = await obtainCredentials();

      if (result == null) {
        // Handle the case where obtaining credentials failed
        print('Failed to obtain FCM credentials');
        return;
      }

      // Get all device tokens from Firestore
      List<String> tokens = await getClientDeviceTokens(uid);

      // Define your FCM server endpoint and authorization header
      const String fcmEndpoint =
          'https://fcm.googleapis.com/v1/projects/ordonez/messages:send';
      String authorizationHeader = 'Bearer $result';

      // Send notification to each device token
      for (String token in tokens) {
        try {
          final response = await http.post(
            Uri.parse(fcmEndpoint),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': authorizationHeader,
            },
            body: jsonEncode(
              <String, dynamic>{
                'message': {
                  'token': token,
                  'notification': {
                    'title': title,
                    'body': body,
                  },
                  'data': <String, dynamic>{
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                    'status': 'done',
                    'body': body,
                    'title': title,
                  },
                },
              },
            ),
          );

          // Handle the response as needed
          if (response.statusCode == 200) {
            print('Notification sent successfully to token: $token');
          } else {
            print(
                'Error sending push notification to token: $token. Status code: ${response.statusCode}');
            print('Response body: ${response.body}');
          }
        } catch (e) {
          print('Error sending push notification: $e');
        }
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: const Text('ADMIN'),
        centerTitle: true,
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
                        const AdminClientsScreen()));
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
                    Icons.people,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text('Clients'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                _qrBarCodeScannerDialogPlugin.getScannedQrBarCode(
                  context: context,
                  onCode: (code) async {
                    try {
                      // Replace 'appointments' with your actual collection name
                      // Replace 'schedules' with your actual document name
                      var result = await FirebaseFirestore.instance
                          .collection('appointments')
                          .doc('schedules')
                          .get();

                      // Check if the document exists and if the code is in the 'appointments' array
                      if (result.exists &&
                          result.data()?['appointments'] != null) {
                        List<dynamic> appointments =
                            result.data()?['appointments'];

                        // Find the index of the appointment with the matching 'id'
                        int index = appointments.indexWhere(
                          (appointment) => appointment['id'] == code,
                        );

                        if (index != -1) {
                          // Update the 'done' field to true
                          appointments[index]['done'] = true;

                          String name = appointments[index]['name'];
                          String pet = appointments[index]['pet'];

                          Timestamp startTime =
                              appointments[index]['startTime'];

                          DateTime startTimeDateTime = startTime.toDate();

                          String formattedDateStart = DateFormat('MMMM d, y ')
                              .format(startTimeDateTime);

                          // Update the document with the modified 'appointments' array
                          await FirebaseFirestore.instance
                              .collection('appointments')
                              .doc('schedules')
                              .update({'appointments': appointments});

                          String body =
                              "Name: $name | Pet: $pet | Appointment Date: $formattedDateStart";

                          String title = "APPOINTMENT SUCCESSFUL";

                          sendPushNotification(body, title, code!);

                          QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                              title: 'Appointment Successful');
                        } else {
                          QuickAlert.show(
                              context: context,
                              type: QuickAlertType.warning,
                              title: 'Code does not exist in records');
                        }
                      } else {
                        QuickAlert.show(
                            context: context,
                            type: QuickAlertType.warning,
                            title: 'Code does not exist in records');
                      }
                    } catch (e) {
                      print('Error checking code: $e');
                      // Handle the error as needed
                    }
                  },
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
                    Icons.qr_code_scanner,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text('Scan QR'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) =>
                        const AdminAppointmentsScreen(),
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
                    Icons.checklist_rounded,
                    size: 70,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text('Appointments'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) =>
                        const AdminCalendarScreen(),
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
                  Text('Appointment Schedule'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
