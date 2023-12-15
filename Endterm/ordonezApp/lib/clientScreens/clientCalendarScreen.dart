import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:intl/intl.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ordonez_vet/models/calendarDataSource.dart';
import 'package:quickalert/quickalert.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import "package:http/http.dart" as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;

class ClientCalendarScreen extends StatefulWidget {
  const ClientCalendarScreen({super.key});

  @override
  State<ClientCalendarScreen> createState() => _ClientCalendarScreenState();
}

class _ClientCalendarScreenState extends State<ClientCalendarScreen> {
  List<String> petNames = [];
  String? selectedPet;

  final formKey = GlobalKey<FormState>();

  DateTime? checkInDate;
  DateTime? checkOutDate;

  TextEditingController checkInDateController = TextEditingController();
  TextEditingController checkOutDateController = TextEditingController();
  TextEditingController petNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPetNames();
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
  Future<List<String>> getAdminDeviceTokens() async {
    try {
      // Get the user IDs of admins
      QuerySnapshot<Map<String, dynamic>> adminUsersSnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .where('user_type', isEqualTo: 'Admin')
              .get();

      List<String> adminUserIds =
          adminUsersSnapshot.docs.map((doc) => doc.id).toList();

      // Get device tokens for admin users
      List<String> tokens = [];

      for (String userId in adminUserIds) {
        DocumentSnapshot<Map<String, dynamic>> userTokensSnapshot =
            await FirebaseFirestore.instance
                .collection("UserTokens")
                .doc(userId)
                .get();

        // Check if the 'deviceTokens' field exists and is not null
        dynamic data = userTokensSnapshot.data();
        if (data != null && data['deviceTokens'] != null) {
          List<String> userTokens = List<String>.from(data['deviceTokens']);
          tokens.addAll(userTokens);
        }
      }

      return tokens;
    } catch (e) {
      print('Error getting admin device tokens: $e');
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
      List<String> tokens = await getAdminDeviceTokens();

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

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      DateTime selectedDateTime =
          DateTime(picked.year, picked.month, picked.day);

      // Format the DateTime using intl package
      String formattedDate = DateFormat('MMMM d, y ').format(selectedDateTime);
      controller.text = formattedDate;

      // Format the DateTime using intl package
      String formattedDate2 = DateFormat('MMMM d, y ').format(selectedDateTime);
      controller.text = formattedDate2;

      setState(() {
        checkInDate = selectedDateTime;
        checkOutDate = selectedDateTime;
      });
    }
  }

  Future<void> loadPetNames() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      QuerySnapshot petSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('user_uid', isEqualTo: userId)
          .get();

      setState(() {
        // Explicitly cast elements to String
        petNames =
            petSnapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    }
  }

  Stream<List<Appointment>> fetchAppointmentsFromFirebase() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .doc('schedules')
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
          .map<Appointment?>((appointmentData) {
            DateTime startTime =
                (appointmentData['startTime'] as Timestamp).toDate();
            DateTime endTime =
                (appointmentData['endTime'] as Timestamp).toDate();
            String pet = appointmentData['pet'] as String;

            // Add a condition to check if the 'accept' field is true
            bool accept = appointmentData['accept'] ?? false;

            // Return null for appointments that do not meet the condition
            if (accept) {
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
                subject: pet,
                color: const Color(0xff3876BF),
              );
            } else {
              return null;
            }
          })
          .where((appointment) => appointment != null)
          .cast<Appointment>()
          .toList();

      return sfAppointments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                QuickAlert.show(
                    context: context,
                    type: QuickAlertType.info,
                    title: 'Information',
                    text:
                        '\n1. All appointments are subject for approval regardless of time of appointment request.\n\n2. Disregard the time-in and time-out below the pet name of the appointment.\n\n3. Please bring your phone or a picture of the qr code before entering the clinic.\n\n4. All approved appointments are subject to "First-come, first-serve" basis, unless the doctor deemed it so.\n5. Appointments with the name BLOCKED, cannot be booked for reservation.');
              },
              icon: const Icon(Icons.help))
        ],
        title: const Text('Schedule'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: fetchAppointmentsFromFirebase(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Appointment> appointments = snapshot.data!;
            return Stack(children: [
              SfCalendar(
                view: CalendarView.month,
                dataSource: MeetingDataSource(appointments),
                headerStyle:
                    const CalendarHeaderStyle(textAlign: TextAlign.center),
                monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.appointment,
                    agendaViewHeight: 150,
                    showAgenda: true),
              ),
              Positioned(
                bottom: 16.0,
                right: 16.0,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xffFFC436),
                  onPressed: () {
                    showTimestampDialog(context);
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ]);
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

  Future<void> showTimestampDialog(BuildContext context) async {
    AwesomeDialog(
      dismissOnTouchOutside: false,
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      btnCancelOnPress: () {
        petNameController.clear();
        checkInDateController.clear();
        checkOutDateController.clear();
      },
      btnOkOnPress: () async {
        if (formKey.currentState!.validate()) {
          try {
            // Check for conflicting appointments
            DocumentSnapshot<Map<String, dynamic>> schedulesQuery =
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc('schedules')
                    .get();

            String generateRandomID() {
              Random random = Random();
              int randomNumber = random.nextInt(900000) + 100000;
              return randomNumber.toString();
            }

            DocumentReference unitRef = FirebaseFirestore.instance
                .collection('appointments')
                .doc('schedules');

            String id = generateRandomID();

            String? userId = FirebaseAuth.instance.currentUser?.uid;

            DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();

            if (userSnapshot.exists) {
              Map<String, dynamic> userData =
                  userSnapshot.data() as Map<String, dynamic>;

              if (userData.containsKey('user_fullName')) {
                String userFullName = userData['user_fullName'];
                await unitRef.update({
                  'appointments': FieldValue.arrayUnion([
                    {
                      'endTime': checkOutDate,
                      'startTime': checkInDate,
                      'name': userFullName,
                      'deny': false,
                      'pet': selectedPet,
                      'id': id,
                      'user_uid': userId,
                      'done': false,
                      'accept': false,
                      'timestamp': DateTime.now()
                    }
                  ])
                });

                DocumentSnapshot<Map<String, dynamic>> userSnapshot =
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(userId)
                        .get();

                // Check if the document exists and has data
                if (userSnapshot.exists) {
                  // Extract the full name from the user document
                  String fullName =
                      userSnapshot.data()?['user_fullName'] ?? 'Unknown';

                  // Format the check-in date
                  String dateTextCheckIn =
                      DateFormat('MMMM dd, yyyy').format(checkInDate!);

                  // Construct the body string
                  String body =
                      "Name: $fullName | Pet: $selectedPet | Appointment Date: $dateTextCheckIn";

                  // Now you can use the 'body' string as needed
                  print(body);
                  String title = "APPOINTMENT REQUEST";

                  sendPushNotification(body, title);
                } else {
                  print("User document not found for ID: $userId");
                }

                QuickAlert.show(
                    context: context,
                    type: QuickAlertType.success,
                    title: 'Appointment Requested');
              } else {
                print(
                    'Field "client_full_name" does not exist in the document');
              }
            } else {
              print('Document with ID $userId does not exist');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add appointment')),
            );

            print(e);
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
                'Request Appointment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPet,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 24,
                elevation: 16,
                style: const TextStyle(color: Colors.black),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPet = newValue;
                  });
                },
                items: petNames.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Select a Pet',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.black),
                  suffixIcon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a pet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: checkInDateController,
                readOnly: true,
                onTap: () => _selectDate(context, checkInDateController),
                decoration: const InputDecoration(
                  labelText: 'Check-in Date',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.black),
                  suffixIcon: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 12),
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
