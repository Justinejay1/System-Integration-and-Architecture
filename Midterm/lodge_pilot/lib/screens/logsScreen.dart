import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class logsScreen extends StatefulWidget {
  const logsScreen({super.key});

  @override
  State<logsScreen> createState() => _logsScreenState();
}

class _logsScreenState extends State<logsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOGS'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('logs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<QueryDocumentSnapshot> unitDocs = snapshot.data!.docs;

            // Extract all appointments from all units
            List<Map<String, dynamic>> allAppointments = [];

            for (QueryDocumentSnapshot unitDoc in unitDocs) {
              Map<String, dynamic>? documentData =
                  unitDoc.data() as Map<String, dynamic>?;

              if (documentData != null) {
                List<dynamic>? appointmentsArray =
                    documentData['appointments'] as List<dynamic>?;

                if (appointmentsArray != null) {
                  allAppointments
                      .addAll(appointmentsArray.cast<Map<String, dynamic>>());
                }
              }
            }

            // Sort all appointments
            allAppointments.sort((a, b) {
              Timestamp? startTimeA = a['timestamp'] as Timestamp?;
              Timestamp? startTimeB = b['timestamp'] as Timestamp?;
              DateTime? startDateA = startTimeA?.toDate();
              DateTime? startDateB = startTimeB?.toDate();
              return startDateB!.compareTo(startDateA!);
            });

            return ListView.builder(
              itemCount: allAppointments.length,
              itemBuilder: (context, index) {
                Map<String, dynamic>? appointmentMap = allAppointments[index];

                String? subject = appointmentMap['subject'] as String?;
                Timestamp? startTime =
                    appointmentMap['startTime'] as Timestamp?;
                Timestamp? endTime = appointmentMap['endTime'] as Timestamp?;
                String? unitName = appointmentMap['unit'] as String?;

                DateTime? startDate = startTime?.toDate();
                DateTime? endDate = endTime?.toDate();

                String dateTextCheckIn =
                    DateFormat('MMMM dd, yyyy').format(startDate!);
                String dateTextCheckOut =
                    DateFormat('MMMM dd, yyyy').format(endDate!);

                String? id = appointmentMap['id'] as String?;
                String action = appointmentMap['action'].toString();

                Timestamp? timestamp =
                    appointmentMap['timestamp'] as Timestamp?;
                DateTime? time = timestamp?.toDate();

                String timeDate =
                    DateFormat('MMMM dd, yyyy hh:mm a').format(time!);

                // Update the isCompleted check
                bool isCompleted = endDate.isBefore(DateTime.now());

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
                              unitName: unitName,
                              id: id,
                            );
                          }),
                        );
                        print(id);
                      },
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              subject ?? '',
                              style: const TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                            ),
                            // Checkmark icon for completed appointments
                            if (isCompleted)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                          ],
                        ),
                        subtitle: Column(
                          children: [
                            const SizedBox(
                              height: 8,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Action:'),
                                Text(action),
                              ],
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Unit:'),
                                Text(
                                  unitName ?? '',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Check-in at:'),
                                Text(
                                  dateTextCheckIn,
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Check-out at:'),
                                Text(
                                  dateTextCheckOut,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TimeStamp:'),
                                Text(
                                  timeDate,
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 2,
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

          return const Center(child: Text('No Bookings available'));
        },
      ),
    );
  }
}
