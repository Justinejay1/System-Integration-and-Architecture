import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ordonez_vet/adminScreens/adminBlockPage.dart';
import 'package:ordonez_vet/models/calendarDataSource.dart';
import 'package:quickalert/quickalert.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
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
                  startTime.hour,
                  startTime.minute,
                ),
                endTime: DateTime(
                  endTime.year,
                  endTime.month,
                  endTime.day,
                  endTime.hour,
                  endTime.minute,
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
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (BuildContext context) => const AdminBlockPage(),
                  ),
                );
              },
              icon: const Icon(Icons.block))
        ],
        title: const Text('Calendar Schedule'),
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
            await FirebaseFirestore.instance
                .runTransaction((transaction) async {
              DocumentReference<Map<String, dynamic>> unitRef =
                  FirebaseFirestore.instance
                      .collection('appointments')
                      .doc('schedules');

              // Fetch the latest data within the transaction
              DocumentSnapshot<Map<String, dynamic>> schedulesQuery =
                  await transaction.get(unitRef);

              List<dynamic> appointmentsData =
                  schedulesQuery.data()?['appointments'] ?? [];

              // Check for conflicts with approved: false
              bool hasConflict = appointmentsData.any((appointmentData) {
                var startTime = appointmentData['startTime'];
                var endTime = appointmentData['endTime'];
                var accept = appointmentData['accept'];

                if (startTime != null &&
                    endTime != null &&
                    startTime is Timestamp &&
                    endTime is Timestamp &&
                    accept != null &&
                    accept is bool &&
                    accept) {
                  // Change this condition to check if approved is true
                  return startTime.toDate().isBefore(checkOutDate!) &&
                      endTime.toDate().isAfter(checkInDate!);
                }

                return false;
              });
              // Check for conflicts with existing blocked dates
              bool hasExistingBlockedDateConflict =
                  appointmentsData.any((appointmentData) {
                var startTime = appointmentData['startTime'];
                var endTime = appointmentData['endTime'];
                var pet = appointmentData['pet'];

                if (startTime != null &&
                    endTime != null &&
                    startTime is Timestamp &&
                    endTime is Timestamp &&
                    pet != null &&
                    pet is String &&
                    pet == 'BLOCKED') {
                  return startTime.toDate().isBefore(checkOutDate!) &&
                      endTime.toDate().isAfter(checkInDate!);
                }

                return false;
              });

              if (!hasConflict && !hasExistingBlockedDateConflict) {
                String generateRandomID() {
                  Random random = Random();
                  int randomNumber = random.nextInt(900000) + 100000;
                  return randomNumber.toString();
                }

                String? userId = FirebaseAuth.instance.currentUser?.uid;

                // Update the document within the transaction
                transaction.update(unitRef, {
                  'appointments': FieldValue.arrayUnion([
                    {
                      'endTime': checkOutDate,
                      'startTime': checkInDate,
                      'pet': 'BLOCKED',
                      'id': generateRandomID(),
                      'accept': true,
                      'deny': false,
                      'done': false,
                      'user_uid': userId,
                      'user_type': 'Admin',
                      'timestamp': DateTime.now(),
                    }
                  ])
                });

                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Dates Blocked',
                );
              } else {
                // Conflicts found, show an error message
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.error,
                  title: 'Appointment Conflict',
                  text:
                      'The selected dates conflict with existing unapproved appointments or blocked dates.',
                );
              }
            });
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
                'Block Dates',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  // Add additional properties to customize the style further if needed
                ),
              ),
              const SizedBox(height: 12),
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
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  onPressed: () async {
                    DateTimeRange datetime = DateTimeRange(
                        start: DateTime.now(),
                        end: DateTime.now().add(const Duration(days: 1)));
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
                  child: const Text('Add Appointment Date Range')),
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
