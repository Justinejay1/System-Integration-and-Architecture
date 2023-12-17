import 'package:airbnb_scheduler/screens/staff/appointmentDetailsScreenStaff.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class appointmentsScreenStaff extends StatefulWidget {
  const appointmentsScreenStaff({super.key, required this.unitName});

  final unitName;

  @override
  State<appointmentsScreenStaff> createState() =>
      _appointmentsScreenStaffState();
}

class _appointmentsScreenStaffState extends State<appointmentsScreenStaff> {
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
                List<Map<String, dynamic>> futureAppointments = [];

                for (Map<String, dynamic> appointmentMap in appointmentsArray) {
                  Timestamp? startTime =
                      appointmentMap['startTime'] as Timestamp?;
                  DateTime? startDate = startTime?.toDate();

                  if (startDate != null) {
                    if (startDate.isAfter(now) || isSameDay(startDate, now)) {
                      todayAppointments.add(appointmentMap);
                    } else {
                      futureAppointments.add(appointmentMap);
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

                futureAppointments.sort((a, b) {
                  Timestamp? startTimeA = a['startTime'] as Timestamp?;
                  Timestamp? startTimeB = b['startTime'] as Timestamp?;
                  DateTime? startDateA = startTimeA?.toDate();
                  DateTime? startDateB = startTimeB?.toDate();
                  return startDateB!.compareTo(startDateA!);
                });

                // Concatenate today's appointments with future appointments
                List<Map<String, dynamic>> allAppointments = [
                  ...todayAppointments,
                  ...futureAppointments
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
                    Timestamp? timestamp =
                        appointmentMap['timestamp'] as Timestamp?;

                    DateTime? startDate = startTime?.toDate();
                    DateTime? endDate = endTime?.toDate();
                    DateTime? timestampdate = timestamp?.toDate();

                    String dateTextCheckIn =
                        DateFormat('MMMM dd, yyyy').format(startDate!);
                    String dateTextCheckOut =
                        DateFormat('MMMM dd, yyyy').format(endDate!);
                    String timestampformat = DateFormat('MMMM dd, yyyy hh:mm a')
                        .format(timestampdate!);

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
                                return appointmentDetailsScreenStaff(
                                    unitName: widget.unitName, id: id);
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
