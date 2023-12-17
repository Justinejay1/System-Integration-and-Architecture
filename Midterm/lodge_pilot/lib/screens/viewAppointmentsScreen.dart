import 'package:airbnb_scheduler/screens/appointmentDetailsScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;
import "package:http/http.dart" as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';

class appointmentsScreen extends StatefulWidget {
  const appointmentsScreen({super.key, required this.unitName});

  final unitName;

  @override
  State<appointmentsScreen> createState() => _appointmentsScreenState();
}

class _appointmentsScreenState extends State<appointmentsScreen> {
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('units')
            .doc(widget.unitName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Map<String, dynamic>? documentData =
                snapshot.data?.data() as Map<String, dynamic>?;

            if (documentData != null) {
              List<dynamic>? appointmentsArray =
                  documentData['appointments'] as List<dynamic>?;

              if (appointmentsArray != null) {
                final now = DateTime.now();
                List<Map<String, dynamic>> todayAppointments = [];
                List<Map<String, dynamic>> doneAppointments = [];

                for (Map<String, dynamic> appointmentMap in appointmentsArray) {
                  Timestamp? startTime =
                      appointmentMap['startTime'] as Timestamp?;

                  DateTime? startDate = startTime?.toDate();

                  if (startDate != null) {
                    if (startDate.isAfter(now) || isSameDay(startDate, now)) {
                      todayAppointments.add(appointmentMap);
                    } else {
                      doneAppointments.add(appointmentMap);
                    }
                  }
                }

                todayAppointments.sort((a, b) {
                  Timestamp? startTimeA = a['startTime'] as Timestamp?;
                  Timestamp? startTimeB = b['startTime'] as Timestamp?;
                  DateTime? startDateA = startTimeA?.toDate();
                  DateTime? startDateB = startTimeB?.toDate();
                  return startDateA!.compareTo(startDateB!);
                });

                doneAppointments.sort((a, b) {
                  Timestamp? startTimeA = a['startTime'] as Timestamp?;
                  Timestamp? startTimeB = b['startTime'] as Timestamp?;
                  DateTime? startDateA = startTimeA?.toDate();
                  DateTime? startDateB = startTimeB?.toDate();
                  return startDateB!.compareTo(startDateA!);
                });

                // Concatenate today's appointments with future appointments
                List<Map<String, dynamic>> allAppointments = [
                  ...todayAppointments,
                  ...doneAppointments
                ];

                return ListView.builder(
                  itemCount: allAppointments.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic>? appointmentMap =
                        allAppointments[index];

                    String? subject = appointmentMap['subject'] as String?;
                    Timestamp? startTime =
                        appointmentMap['startTime'] as Timestamp?;
                    Timestamp? endTime =
                        appointmentMap['endTime'] as Timestamp?;

                    DateTime? startDate = startTime?.toDate();
                    DateTime? endDate = endTime?.toDate();

                    String dateTextCheckIn =
                        DateFormat('MMMM dd, yyyy').format(startDate!);
                    String dateTextCheckOut =
                        DateFormat('MMMM dd, yyyy').format(endDate!);

                    String? id = appointmentMap['id'] as String?;
                    String num = appointmentMap['guests'].toString();

                    bool isCompleted = endDate.isBefore(now);

                    return Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Card(
                        elevation: 20,
                        shadowColor: const Color(0xff4E6C50),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(builder: (context) {
                                return appointmentDetailsScreen(
                                    unitName: widget.unitName, id: id);
                              }),
                            );
                            print(id);
                          },
                          onLongPress: () {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.warning,
                              title: 'Delete Booking?',
                              showCancelBtn: true,
                              confirmBtnText: 'Delete',
                              onCancelBtnTap: () {
                                Navigator.pop(context);
                              },
                              onConfirmBtnTap: () async {
                                String body =
                                    "Guest: $subject | Check-in: $dateTextCheckIn | Check-out: $dateTextCheckOut";

                                String title =
                                    "CANCELLED BOOKING in ${widget.unitName}";

                                sendPushNotification(body, title);

                                DocumentReference unitRefLOGS =
                                    FirebaseFirestore.instance
                                        .collection('logs')
                                        .doc(widget.unitName);

                                await unitRefLOGS.update({
                                  'appointments': FieldValue.arrayUnion([
                                    {
                                      'unit': widget.unitName,
                                      'action': "Cancelled",
                                      'endTime': endDate,
                                      'startTime': startDate,
                                      'subject': subject,
                                      'id': id,
                                      'timestamp': DateTime.now()
                                    }
                                  ])
                                });

                                print("Deleting appointment with ID: $id");
                                allAppointments.removeAt(index);
                                FirebaseFirestore.instance
                                    .collection('units')
                                    .doc(widget.unitName)
                                    .update({
                                  'appointments': allAppointments
                                }).then((value) {
                                  print('Appointment deleted successfully');
                                  Navigator.pop(context);
                                  QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.success,
                                      title: 'Booking Deleted');
                                }).catchError((error) {
                                  print('Failed to delete appointment: $error');
                                });
                              },
                            );
                          },
                          child: ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  subject ?? '',
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (isCompleted)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ), // Checkmark icon for completed appointments
                              ],
                            ),
                            subtitle: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Check-in at:'),
                                    Text(
                                      dateTextCheckIn,
                                      style:
                                          const TextStyle(color: Colors.green),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Check-out at:'),
                                    Text(
                                      dateTextCheckOut,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Number of guests:'),
                                    Text(num),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            }
          }

          return const Center(child: Text('No Bookings available'));
        },
      ),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
