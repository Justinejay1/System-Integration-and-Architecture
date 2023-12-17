import 'dart:convert';
import 'package:airbnb_scheduler/models/calendarDataSource.dart';
import 'package:airbnb_scheduler/screens/viewAppointmentsScreen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:quickalert/quickalert.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import "package:http/http.dart" as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;

class calendarScreen extends StatefulWidget {
  const calendarScreen({super.key, required this.unitName});

  final unitName;

  @override
  State<calendarScreen> createState() => _calendarScreenState();
}

class _calendarScreenState extends State<calendarScreen> {
  Stream<List<Appointment>> fetchAppointmentsFromFirebase(String unitName) {
    return FirebaseFirestore.instance
        .collection('units')
        .doc(unitName)
        .snapshots()
        .map((DocumentSnapshot documentSnapshot) {
      if (!documentSnapshot.exists) {
        return [];
      }

      Map<String, dynamic>? data =
          documentSnapshot.data() as Map<String, dynamic>?;

      if (data == null || !data.containsKey('appointments')) {
        return [];
      }

      List<Appointment> sfAppointments = (data['appointments'] as List<dynamic>)
          .map<Appointment>((appointmentData) {
        DateTime startTime =
            (appointmentData['startTime'] as Timestamp).toDate();
        DateTime endTime = (appointmentData['endTime'] as Timestamp).toDate();
        String subject = appointmentData['subject'] as String;

        return Appointment(
            startTime: DateTime(
              startTime.year,
              startTime.month,
              startTime.day,
            ),
            endTime: DateTime(
              endTime.year,
              endTime.month,
              endTime.day,
            ),
            subject: subject,
            color: const Color(0xff862B0D));
      }).toList();

      return sfAppointments;
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
      print(result);

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
        title: Text(widget.unitName),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) {
                  return appointmentsScreen(unitName: widget.unitName);
                }),
              );
            },
            label: const Text(
              'Bookings',
              style: TextStyle(color: Colors.white),
            ),
            icon: const Icon(Icons.view_column, color: Colors.white),
          ),
        ],
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: fetchAppointmentsFromFirebase(widget.unitName),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Appointment> appointments = snapshot.data!;
            return Stack(
              children: [
                SfCalendar(
                  view: CalendarView.month,
                  dataSource: MeetingDataSource(appointments),
                  headerStyle:
                      const CalendarHeaderStyle(textAlign: TextAlign.center),
                  monthViewSettings: const MonthViewSettings(
                      appointmentDisplayMode:
                          MonthAppointmentDisplayMode.appointment,
                      agendaViewHeight: 100,
                      showAgenda: true),
                ),
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xff4E6C50),
                    onPressed: () {
                      showTimestampDialog(context);
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return const Center(
              child: Text('Error fetching appointments'),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  void showTimestampDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameKey = GlobalKey<FormFieldState<String>>();
    final phoneKey = GlobalKey<FormFieldState<String>>();
    final numKey = GlobalKey<FormFieldState<String>>();

    DateTime? checkInDate;
    DateTime? checkOutDate;
    TextEditingController checkInDateController = TextEditingController();
    TextEditingController checkOutDateController = TextEditingController();
    TextEditingController subjectController = TextEditingController();
    TextEditingController numGuestController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
    TextEditingController reqController = TextEditingController();

    AwesomeDialog(
      dismissOnTouchOutside: false,
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (formKey.currentState!.validate()) {
          try {
            DocumentReference unitRef = FirebaseFirestore.instance
                .collection('units')
                .doc(widget.unitName);

            DocumentReference unitRefLOGS = FirebaseFirestore.instance
                .collection('logs')
                .doc(widget.unitName);

            String generateRandomID() {
              Random random = Random();
              int randomNumber = random.nextInt(900000) + 100000;
              return randomNumber.toString();
            }

            String id = generateRandomID();

            await unitRef.update({
              'appointments': FieldValue.arrayUnion([
                {
                  'endTime': checkOutDate,
                  'startTime': checkInDate,
                  'subject': subjectController.text,
                  'guests': numGuestController.text,
                  'id': id,
                  'phone': phoneController.text,
                  'requests': reqController.text,
                  'timestamp': DateTime.now()
                }
              ])
            });

            await unitRefLOGS.update({
              'appointments': FieldValue.arrayUnion([
                {
                  'unit': widget.unitName,
                  'action': "Added",
                  'endTime': checkOutDate,
                  'startTime': checkInDate,
                  'subject': subjectController.text,
                  'guests': numGuestController.text,
                  'id': id,
                  'timestamp': DateTime.now()
                }
              ])
            });

            String dateTextCheckIn =
                DateFormat('MMMM dd, yyyy').format(checkInDate!);
            String dateTextCheckOut =
                DateFormat('MMMM dd, yyyy').format(checkOutDate!);

            String body =
                "Guest: ${subjectController.text} | Check-in: $dateTextCheckIn | Check-out: $dateTextCheckOut";

            String title = "NEW BOOKING in ${widget.unitName}";

            sendPushNotification(body, title);

            QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: 'Booking Added');
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add booking')),
            );
          }
        } else {
          QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Please fill all input fields');
        }
      },
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              const Text(
                'Add new booking',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  // Add additional properties to customize the style further if needed
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: nameKey,
                controller: subjectController,
                decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(color: Colors.black),
                    suffixIcon: Icon(Icons.person)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: checkInDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                            labelText: 'Check-in Date',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            labelStyle: TextStyle(color: Colors.black),
                            suffixIcon: Icon(Icons.date_range)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: checkOutDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                            labelText: 'Check-out Date',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            labelStyle: TextStyle(color: Colors.black),
                            suffixIcon: Icon(Icons.date_range)),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff820000),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18))),
                          onPressed: () async {
                            DateTimeRange datetime = DateTimeRange(
                                start: DateTime.now(),
                                end: DateTime.now()
                                    .add(const Duration(days: 1)));
                            final newDateRange = await showDateRangePicker(
                                context: context,
                                initialDateRange: datetime,
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2100));

                            if (newDateRange != null) {
                              setState(() {
                                checkInDate = newDateRange.start;
                                checkInDateController.text =
                                    formatDate(newDateRange.start);

                                checkOutDate = newDateRange.end;
                                checkOutDateController.text =
                                    formatDate(newDateRange.end);
                              });
                            }
                          },
                          child: const Text('Add Booking Schedule')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: numKey,
                controller: numGuestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Number of guests',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(color: Colors.black),
                    suffixIcon: Icon(Icons.numbers_outlined)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                key: phoneKey,
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(color: Colors.black),
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 2,
                controller: reqController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(color: Colors.black),
                    labelText: 'Requests',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.note_rounded)),
              ),
            ],
          ),
        ),
      ),
    ).show();
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('MMMM dd, yyyy');
    return formatter.format(date);
  }
}
