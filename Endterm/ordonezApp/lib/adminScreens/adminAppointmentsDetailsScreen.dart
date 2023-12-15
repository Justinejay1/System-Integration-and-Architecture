import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import "package:http/http.dart" as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:ordonez_vet/adminScreens/adminClientPetsViewDetailsScreen.dart';
import 'package:ordonez_vet/adminScreens/adminClientViewDetailsScreen.dart';
import 'package:ordonez_vet/adminScreens/adminClientsScreen.dart';

class AdminAppointmentsDetailsScreen extends StatefulWidget {
  const AdminAppointmentsDetailsScreen({super.key, required this.id});

  final id;
  @override
  State<AdminAppointmentsDetailsScreen> createState() =>
      _AdminAppointmentsDetailsScreenState();
}

class _AdminAppointmentsDetailsScreenState
    extends State<AdminAppointmentsDetailsScreen> {
  String? user_uid = '';

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
  Future<List<String>> getClientDeviceTokens(String uid) async {
    try {
      // Get the device tokens for the specified user ID
      DocumentSnapshot<Map<String, dynamic>> userTokensSnapshot =
          await FirebaseFirestore.instance
              .collection("UserTokens")
              .doc(uid)
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Appointment Details'),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .doc(
                'schedules') // Assuming 'schedules' is the document you are interested in
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text('No data available.'),
            );
          }

          // Access the 'appointments' array within the 'schedules' document
          List<dynamic> appointments = snapshot.data!.get('appointments');

          if (appointments.isEmpty) {
            return const Center(
              child: Text('No appointments available.'),
            );
          }

          // Filter appointments based on the widgetId
          Map<String, dynamic>? appointmentData = appointments.firstWhere(
            (appointment) => appointment['id'] == widget.id,
            orElse: () => null,
          );

          if (appointmentData == null) {
            return Center(
              child: Text('Appointment not found for id: ${widget.id}'),
            );
          }
          String name = appointmentData['name'];
          String pet = appointmentData['pet'];
          String uid = appointmentData['user_uid'];

          Timestamp startTime = appointmentData['startTime'];

          DateTime startTimeDateTime = startTime.toDate();

          String formattedDateStart =
              DateFormat('MMMM d, y ').format(startTimeDateTime);

          bool accept = appointmentData['accept'];
          bool deny = appointmentData['deny'];
          bool done = appointmentData['done'];

          Widget iconStatus() {
            if (accept == true) {
              if (done == true) {
                return const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 70,
                );
              }
              return const Icon(
                Icons.check,
                color: Colors.orange,
                size: 70,
              );
            } else if (deny) {
              return const Icon(
                Icons.close,
                color: Colors.red,
                size: 70,
              );
            } else {
              return const Icon(
                Icons.watch_later,
                color: Colors.black,
                size: 70,
              );
            }
          }

          Widget textStatus() {
            if (accept == true) {
              if (done == true) {
                return const Text(
                  'DONE',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                      color: Colors.green),
                  textAlign: TextAlign.center,
                );
              }
              return const Text(
                'APPROVED',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                    color: Colors.orange),
                textAlign: TextAlign.center,
              );
            } else if (deny) {
              return const Text(
                'DENIED',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                    color: Colors.red),
                textAlign: TextAlign.center,
              );
            } else {
              return const Text(
                'PENDING',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                    color: Colors.black),
                textAlign: TextAlign.center,
              );
            }
          }

          // Build your UI using the filtered appointmentData
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 50.0,
                      backgroundColor: const Color(0xff0C356A),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 45.0,
                        child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: iconStatus()),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    textStatus(),
                    const SizedBox(height: 16.0),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      pet,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      formattedDateStart,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  DocumentReference documentReference =
                                      FirebaseFirestore.instance
                                          .collection('appointments')
                                          .doc('schedules');

                                  // Fetch the document
                                  DocumentSnapshot documentSnapshot =
                                      await documentReference.get();

                                  if (documentSnapshot.exists) {
                                    // Get the current array
                                    List<dynamic> appointments =
                                        documentSnapshot['appointments'];

                                    // Find the index where 'id' is equal to widgetId
                                    int index = appointments.indexWhere(
                                        (appointment) =>
                                            appointment['id'] == widget.id);

                                    if (index != -1) {
                                      // Update the 'action' for the found element
                                      appointments[index]['accept'] = false;
                                      appointments[index]['done'] = false;
                                      appointments[index]['deny'] = true;

                                      // Update the entire array in Firestore
                                      await documentReference.update({
                                        'appointments': appointments,
                                      });

                                      String body =
                                          "Name: $name | Pet: $pet | Appointment Date: $formattedDateStart";

                                      String title = "APPOINTMENT DENIED";

                                      sendPushNotification(body, title, uid);

                                      print('Firestore update successful');
                                    } else {
                                      print('Element not found in the array');
                                    }
                                  } else {
                                    print('Document does not exist');
                                  }
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Deny'),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.red), // Set your desired color
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  DocumentReference documentReference =
                                      FirebaseFirestore.instance
                                          .collection('appointments')
                                          .doc('schedules');

                                  // Fetch the document
                                  DocumentSnapshot documentSnapshot =
                                      await documentReference.get();

                                  if (documentSnapshot.exists) {
                                    // Get the current array
                                    List<dynamic> appointments =
                                        documentSnapshot['appointments'];

                                    // Find the index where 'id' is equal to widgetId
                                    int index = appointments.indexWhere(
                                        (appointment) =>
                                            appointment['id'] == widget.id);

                                    if (index != -1) {
                                      // Update the 'action' for the found element
                                      appointments[index]['accept'] = false;
                                      appointments[index]['done'] = false;
                                      appointments[index]['deny'] = false;

                                      // Update the entire array in Firestore
                                      await documentReference.update({
                                        'appointments': appointments,
                                      });

                                      print('Firestore update successful');

                                      String body =
                                          "Name: $name | Pet: $pet | Appointment Date: $formattedDateStart";

                                      String title = "APPOINTMENT PENDING";

                                      sendPushNotification(body, title, uid);
                                    } else {
                                      print('Element not found in the array');
                                    }
                                  } else {
                                    print('Document does not exist');
                                  }
                                },
                                icon: const Icon(Icons.watch_later),
                                label: const Text('Pending'),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(Colors
                                          .grey), // Set your desired color
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  DocumentReference documentReference =
                                      FirebaseFirestore.instance
                                          .collection('appointments')
                                          .doc('schedules');

                                  // Fetch the document
                                  DocumentSnapshot documentSnapshot =
                                      await documentReference.get();

                                  if (documentSnapshot.exists) {
                                    // Get the current array
                                    List<dynamic> appointments =
                                        documentSnapshot['appointments'];

                                    // Find the index where 'id' is equal to widgetId
                                    int index = appointments.indexWhere(
                                        (appointment) =>
                                            appointment['id'] == widget.id);

                                    if (index != -1) {
                                      // Update the 'action' for the found element
                                      appointments[index]['accept'] = true;
                                      appointments[index]['done'] = false;
                                      appointments[index]['deny'] = false;

                                      // Update the entire array in Firestore
                                      await documentReference.update({
                                        'appointments': appointments,
                                      });

                                      print('Firestore update successful');

                                      String body =
                                          "Name: $name | Pet: $pet | Appointment Date: $formattedDateStart";

                                      String title = "APPOINTMENT APPROVED";

                                      sendPushNotification(body, title, uid);
                                    } else {
                                      print('Element not found in the array');
                                    }
                                  } else {
                                    print('Document does not exist');
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(Colors
                                          .orange), // Set your desired color
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  DocumentReference documentReference =
                                      FirebaseFirestore.instance
                                          .collection('appointments')
                                          .doc('schedules');

                                  // Fetch the document
                                  DocumentSnapshot documentSnapshot =
                                      await documentReference.get();

                                  if (documentSnapshot.exists) {
                                    // Get the current array
                                    List<dynamic> appointments =
                                        documentSnapshot['appointments'];

                                    // Find the index where 'id' is equal to widgetId
                                    int index = appointments.indexWhere(
                                        (appointment) =>
                                            appointment['id'] == widget.id);

                                    if (index != -1) {
                                      // Update the 'action' for the found element
                                      appointments[index]['accept'] = true;
                                      appointments[index]['done'] = true;
                                      appointments[index]['deny'] = false;

                                      // Update the entire array in Firestore
                                      await documentReference.update({
                                        'appointments': appointments,
                                      });

                                      print('Firestore update successful');

                                      String body =
                                          "Name: $name | Pet: $pet | Appointment Date: $formattedDateStart";

                                      String title = "APPOINTMENT DONE";

                                      sendPushNotification(body, title, uid);
                                    } else {
                                      print('Element not found in the array');
                                    }
                                  } else {
                                    print('Document does not exist');
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Done'),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(Colors
                                          .green), // Set your desired color
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (BuildContext context) =>
                                          AdmminClientViewDetailsScreen(
                                              uid: uid),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.people_sharp),
                                label: const Text('View Client Details'),
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(Colors
                                          .blue), // Set your desired color
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
