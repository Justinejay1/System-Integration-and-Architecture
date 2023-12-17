import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;
import "package:http/http.dart" as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';

class appointmentDetailsEditScreen extends StatefulWidget {
  const appointmentDetailsEditScreen(
      {super.key,
      required this.unitName,
      required this.id,
      required this.subject,
      required this.num,
      required this.phone,
      required this.req,
      required this.checkin,
      required this.checkout,
      required this.timestamp});

  final unitName;
  final id;
  final subject;
  final num;
  final phone;
  final req;
  final checkin;
  final checkout;
  final timestamp;

  @override
  State<appointmentDetailsEditScreen> createState() =>
      _appointmentDetailsEditScreenState();
}

class _appointmentDetailsEditScreenState
    extends State<appointmentDetailsEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final numKey = GlobalKey<FormFieldState<String>>();
  final nameKey = GlobalKey<FormFieldState<String>>();
  TextEditingController idController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController reqController = TextEditingController();
  TextEditingController numContoller = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      idController.text = widget.id;
      titleController.text = widget.subject;
      phoneController.text = widget.phone;
      reqController.text = widget.req;
      numContoller.text = widget.num;
    });
  }

  // Use service account credentials to obtain oauth credentials.
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
  Future<List<String>> getAllDeviceTokens() async {
    try {
      QuerySnapshot<Map<String, dynamic>> tokensSnapshot =
          await FirebaseFirestore.instance.collection("UserTokens").get();

      List<String> tokens = [];

      for (QueryDocumentSnapshot<Map<String, dynamic>> doc
          in tokensSnapshot.docs) {
        // Check if the 'deviceTokens' field exists and is not null
        dynamic data = doc.data();
        if (data != null && data['deviceTokens'] != null) {
          List<String> userTokens = List<String>.from(data['deviceTokens']);
          tokens.addAll(userTokens);
        }
      }

      return tokens;
    } catch (e) {
      print('Error getting all device tokens: $e');
      return [];
    }
  }

  //push notif
  void sendPushNotification(String body, String title) async {
    try {
      // Obtain FCM credentials
      final result = await obtainCredentials();

      if (result == null) {
        // Handle the case where obtaining credentials failed
        print('Failed to obtain FCM credentials');
        return;
      }

      // Get all device tokens from Firestore
      List<String> tokens = await getAllDeviceTokens();

      // Define your FCM server endpoint and authorization header
      const String fcmEndpoint =
          'https://fcm.googleapis.com/v1/projects/lodgepilot-97d8f/messages:send';
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
                  'data': {
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
        title: Text(widget.unitName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20.0),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //full name
                    TextFormField(
                      controller: idController,
                      readOnly: true,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'ID',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      key: nameKey,
                      controller: titleController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(fontSize: 16.0),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      key: numKey,
                      controller: numContoller,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16.0),
                      decoration: const InputDecoration(
                        labelText: 'Number of Guests',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a number of guests.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 16.0),
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: reqController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 16.0),
                      decoration: const InputDecoration(
                        labelText: 'Request',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff820000),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Form is valid, proceed with saving
                          DocumentSnapshot<Map<String, dynamic>>
                              appointmentsSnapshot = await FirebaseFirestore
                                  .instance
                                  .collection('units')
                                  .doc(widget.unitName)
                                  .get();

                          List<dynamic> appointments =
                              appointmentsSnapshot.data()?['appointments'] ??
                                  [];

                          Map<String, dynamic> updatedData = {
                            'timestamp': widget.timestamp,
                            'startTime': widget.checkin,
                            'endTime': widget.checkout,
                            'subject': titleController.text,
                            'guests': numContoller.text,
                            'phone': phoneController.text,
                            'requests': reqController.text,
                            'id': widget.id
                          };

                          DocumentReference unitRefLOGS = FirebaseFirestore
                              .instance
                              .collection('logs')
                              .doc(widget.unitName);

                          await unitRefLOGS.update({
                            'appointments': FieldValue.arrayUnion([
                              {
                                'unit': widget.unitName,
                                'action': "Edited",
                                'endTime': widget.checkout,
                                'startTime': widget.checkin,
                                'subject': titleController.text,
                                'guests': numContoller.text,
                                'id': widget.id,
                                'timestamp': DateTime.now()
                              }
                            ])
                          });

                          List<Map<String, dynamic>> updatedAppointments =
                              appointments
                                  .map<Map<String, dynamic>>((appointment) {
                            if (appointment is Map<String, dynamic> &&
                                appointment['id'] == widget.id) {
                              return updatedData;
                            } else {
                              return appointment;
                            }
                          }).toList();

                          await FirebaseFirestore.instance
                              .collection('units')
                              .doc(widget.unitName)
                              .update({
                            'appointments': updatedAppointments,
                          });
                          Navigator.pop(context);
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.success,
                            title: 'Booking Info Updated',
                          );

                          String dateTextCheckIn = DateFormat('MMMM dd, yyyy')
                              .format(widget.checkin!);
                          String dateTextCheckOut = DateFormat('MMMM dd, yyyy')
                              .format(widget.checkout!);

                          String body =
                              "Guest: ${titleController.text} | Check-in: $dateTextCheckIn | Check-out: $dateTextCheckOut";

                          String title =
                              "MODIFIED BOOKING in ${widget.unitName}";

                          sendPushNotification(body, title);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('MMMM dd, yyyy');
    return formatter.format(date);
  }
}
