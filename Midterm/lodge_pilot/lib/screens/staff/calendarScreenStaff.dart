import 'package:airbnb_scheduler/screens/staff/appointmentsScreenStaff.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../models/calendarDataSource.dart';

class calendarScreenStaff extends StatefulWidget {
  const calendarScreenStaff({super.key, required this.unitName});

  final unitName;

  @override
  State<calendarScreenStaff> createState() => _calendarScreenStaffState();
}

class _calendarScreenStaffState extends State<calendarScreenStaff> {
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
                  return appointmentsScreenStaff(unitName: widget.unitName);
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
}
