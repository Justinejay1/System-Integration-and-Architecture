import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'appointmentDetailsEditScreenStaff.dart';

class appointmentDetailsScreenStaff extends StatefulWidget {
  const appointmentDetailsScreenStaff(
      {super.key, required this.unitName, required this.id});

  final unitName;
  final id;

  @override
  State<appointmentDetailsScreenStaff> createState() =>
      _appointmentDetailsScreenStaffState();
}

class _appointmentDetailsScreenStaffState
    extends State<appointmentDetailsScreenStaff> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.unitName)),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('units')
              .doc(widget.unitName)
              .snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              Map<String, dynamic>? unitData = snapshot.data!.data();
              if (unitData != null && unitData.containsKey('appointments')) {
                List<dynamic>? appointments = unitData['appointments'];
                if (appointments != null) {
                  List<dynamic> filteredAppointments = appointments
                      .where((appointment) =>
                          appointment is Map<String, dynamic> &&
                          appointment.containsKey('id') &&
                          appointment['id'] == widget.id)
                      .toList();

                  if (filteredAppointments.isNotEmpty) {
                    return ListView.builder(
                      itemCount: filteredAppointments.length,
                      itemBuilder: (BuildContext context, int index) {
                        dynamic appointmentData = filteredAppointments[index];
                        String title = appointmentData['subject'];
                        String id = appointmentData['id'];
                        String phone = appointmentData['phone'];
                        String req = appointmentData['requests'];

                        Timestamp? startTime =
                            appointmentData['startTime'] as Timestamp?;
                        Timestamp? endTime =
                            appointmentData['endTime'] as Timestamp?;
                        DateTime startTimeValue =
                            startTime?.toDate() ?? DateTime.now();
                        DateTime endTimeValue =
                            endTime?.toDate() ?? DateTime.now();

                        String? num = appointmentData['guests'];
                        String dateTextCheckIn =
                            DateFormat('MMMM dd, yyyy').format(startTimeValue);
                        String dateTextCheckOut =
                            DateFormat('MMMM dd, yyyy').format(endTimeValue);

                        Timestamp timestamp = appointmentData['timestamp'];

                        DateTime timestampval = timestamp.toDate();

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'ID: $id',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Name: $title',
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Check-in: $dateTextCheckIn',
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Check-out: $dateTextCheckOut',
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Number of guests: $num',
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 4.0),
                                  GestureDetector(
                                    onTap: () {
                                      _launchPhone(
                                          phone); // Function to launch the phone dialer (as in your original code)
                                    },
                                    onLongPress: () {
                                      _copyToClipboard(
                                          phone); // Function to copy the phone number to clipboard
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Phone number copied to clipboard')));
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Phone: ',
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          color: Colors
                                              .black, // Set the desired color for "Phone"
                                        ),
                                        children: [
                                          TextSpan(
                                            text: phone,
                                            style: const TextStyle(
                                              fontSize: 16.0,
                                              decoration:
                                                  TextDecoration.underline,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Request: $req',
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 50.0),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(builder: (context) {
                                          return appointmentDetailsEditScreenStaff(
                                            unitName: widget.unitName,
                                            id: widget.id,
                                            subject: title,
                                            phone: phone,
                                            num: num,
                                            req: req,
                                            checkin: startTimeValue,
                                            checkout: endTimeValue,
                                            timestamp: timestampval,
                                          );
                                        }),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xff820000),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18))),
                                    child: const Text('Edit'),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                        child: Text('No matching appointments found'));
                  }
                }
              }
            }

            return const Center(child: Text('No appointments found'));
          },
        ));
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}

void _launchPhone(String phoneNumber) async {
  if (phoneNumber.isNotEmpty) {
    final Uri url = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
