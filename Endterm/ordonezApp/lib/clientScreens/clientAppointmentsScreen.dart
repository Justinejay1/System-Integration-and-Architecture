import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:quickalert/quickalert.dart';

class ClientAppointmentsScreen extends StatefulWidget {
  const ClientAppointmentsScreen({super.key});

  @override
  State<ClientAppointmentsScreen> createState() =>
      _ClientAppointmentsScreenState();
}

class _ClientAppointmentsScreenState extends State<ClientAppointmentsScreen> {
  void deleteAppointment(String petName) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      CollectionReference schedulesCollection =
          FirebaseFirestore.instance.collection('appointments');

      // Update the field name according to your Firestore structure
      String fieldName = 'appointments';

      // Use array-contains query to find the document containing the appointment
      schedulesCollection
          .where('user_uid', isEqualTo: userId)
          .where(fieldName, arrayContains: petName)
          .get()
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          // Iterate over the documents (there might be multiple if the array has duplicates)
          for (var doc in querySnapshot.docs) {
            // Get the reference to the document
            DocumentReference docRef = schedulesCollection.doc(doc.id);

            // Update the array field by removing the specific appointment
            docRef.update({
              fieldName: FieldValue.arrayRemove([petName]),
            }).then((_) {
              print('Appointment deleted successfully!');
              QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: 'Appointment Record Deleted!',
              );
            }).catchError((error) {
              print('Error updating appointment array: $error');
              // Handle error as needed
            });
          }
        } else {
          print('Appointment not found!');
          // Handle the case where the pet is not found
        }
      }).catchError((error) {
        print('Error querying appointment: $error');
        // Handle error as needed
      });
    }
  }

  String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .doc('schedules')
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var data = snapshot.data?.data();
          List<dynamic> appointments = data?['appointments'] ?? [];

          // Filter appointments based on user_uid
          List<dynamic> petAppointments = appointments
              .where((appointment) => appointment['user_uid'] == userId)
              .toList();

          final now = DateTime.now();
          List<Map<String, dynamic>> todayAppointments = [];
          List<Map<String, dynamic>> doneAppointments = [];

          for (Map<String, dynamic> appointmentMap in petAppointments) {
            Timestamp? startTime = appointmentMap['startTime'] as Timestamp?;

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
              var appointmentData = allAppointments[index];

              String petName = appointmentData['pet'];
              String id = appointmentData['id'];
              bool done = appointmentData['done'];
              bool accept = appointmentData['accept'];
              bool deny = appointmentData['deny'];
              Timestamp startTime = appointmentData['startTime'];
              Timestamp endTime = appointmentData['endTime'];

              DateTime startTimeDateTime = startTime.toDate();
              DateTime endTimeDateTime = endTime.toDate();

              String formattedDateStart =
                  DateFormat('MMMM d, y hh:mm a').format(startTimeDateTime);

              String formattedDateEnd =
                  DateFormat('MMMM d, y hh:mm a').format(endTimeDateTime);

              // Sort appointments based on the start time
              appointments.sort((a, b) {
                Timestamp startTimeA = a['startTime'] ?? Timestamp(0, 0);
                Timestamp startTimeB = b['startTime'] ?? Timestamp(0, 0);
                return startTimeA.compareTo(startTimeB);
              });

              Widget textStatus() {
                if (accept == true) {
                  if (done == true) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('Status: '),
                            Text(
                              'DONE',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                        Text('Date: $formattedDateStart')
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('Status: '),
                          Text(
                            'APPROVED',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                      Text('Date: $formattedDateStart')
                    ],
                  );
                } else if (deny) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('Status: '),
                          Text(
                            'DENIED',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      Text('Date: $formattedDateStart')
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('Status: '),
                          Text(
                            'PENDING',
                            style: TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                      Text('Date: $formattedDateStart')
                    ],
                  );
                }
              }

              Widget trailingIcon() {
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
                  return IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CupertinoAlertDialog(
                            title: const Text('Appointment QR Code'),
                            content: Column(
                              children: [
                                const SizedBox(
                                  height: 20,
                                ),
                                PrettyQrView.data(
                                  data: id,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.qr_code_2,
                      size: 40,
                      color: Colors.black,
                    ),
                  );
                } else if (deny) {
                  return const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  );
                } else {
                  return const CircleAvatar(
                    radius: 15,
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
                child: Card(
                  elevation: 20,
                  child: InkWell(
                    onLongPress: () {
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.warning,
                        title:
                            'Are you sure you want to cancel the appointment?',
                        onConfirmBtnTap: () {
                          Navigator.pop(context);
                          allAppointments.removeAt(index);
                          FirebaseFirestore.instance
                              .collection('appointments')
                              .doc('schedules')
                              .update({'appointments': allAppointments}).then(
                                  (value) {
                            print('Appointment Cancelled successfully');
                            QuickAlert.show(
                                context: context,
                                type: QuickAlertType.success,
                                title: 'Appointment Cancelled');
                          }).catchError((error) {
                            print('Failed to Cancel  appointment: $error');
                          });
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        trailing: trailingIcon(),
                        title: Text(
                          petName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: textStatus(),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
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
