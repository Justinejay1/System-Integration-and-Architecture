import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ordonez_vet/adminScreens/adminAppointmentsDetailsScreen.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
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
        title: const Text('Appointments'),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance.collection('appointments').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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

          // If there are no documents, display a message
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No Appointments found.'),
            );
          }

          // If there are documents, display a ListView
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var scheduleData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var uid = snapshot.data!.docs[index].id;

              // Assuming 'appointments' is an array of appointments
              List<dynamic>? appointments = scheduleData['appointments'];

              if (appointments == null || appointments.isEmpty) {
                return const SizedBox
                    .shrink(); // Skip if no appointments or empty array
              }

              // Sort appointments based on the start time
              appointments.sort((a, b) {
                Timestamp startTimeA = a['startTime'] ?? Timestamp(0, 0);
                Timestamp startTimeB = b['startTime'] ?? Timestamp(0, 0);
                return startTimeA.compareTo(startTimeB);
              });

              // Display each appointment in the 'appointments' array
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: appointments.map((appointment) {
                  String name = appointment['name'] ?? 'Unknown Name';
                  if (name == 'Unknown Name') {
                    // Skip creating the card if the name is 'Unknown Name'
                    return const SizedBox.shrink();
                  }

                  String id = appointment['id'] ?? 'Unknown Name';
                  String pet = appointment['pet'] ?? 'Unknown Name';
                  Timestamp startTime =
                      appointment['startTime'] ?? Timestamp(0, 0);
                  Timestamp endTime = appointment['endTime'] ?? Timestamp(0, 0);

                  DateTime startTimeDateTime = startTime.toDate();
                  DateTime endTimeDateTime = endTime.toDate();

                  String formattedDateStart =
                      DateFormat('MMMM d, y ').format(startTimeDateTime);

                  bool done = appointment['done'];
                  bool accept = appointment['accept'];
                  bool deny = appointment['deny'];

                  Widget iconStatus() {
                    if (accept == true) {
                      if (done == true) {
                        return const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                        );
                      }
                      return const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                      );
                    } else if (deny) {
                      return const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      );
                    } else {
                      return const CircleAvatar(
                        backgroundColor: Colors.black,
                        child: Icon(
                          Icons.watch_later,
                          color: Colors.white,
                        ),
                      );
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8, left: 8, top: 2),
                    child: InkWell(
                      onTap: () {
                        // Handle appointment tap
                      },
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (BuildContext context) =>
                                  AdminAppointmentsDetailsScreen(
                                id: id,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 20,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              ListTile(
                                leading: iconStatus(),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('Pet: $pet\n'
                                    'Start: $formattedDateStart'),
                                trailing: const Icon(
                                  Icons.arrow_circle_right,
                                  color: Colors.black,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
