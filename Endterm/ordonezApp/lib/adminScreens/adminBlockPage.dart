import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';

class AdminBlockPage extends StatefulWidget {
  const AdminBlockPage({super.key});

  @override
  State<AdminBlockPage> createState() => _AdminBlockPageState();
}

class _AdminBlockPageState extends State<AdminBlockPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Dates'),
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
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          List<dynamic> blockedDates =
              snapshot.data!.data()?['appointments'] ?? [];

          return ListView.builder(
            itemCount: blockedDates.length,
            itemBuilder: (context, index) {
              var blockedDate = blockedDates[index];

              // Filter only blocked dates
              if (blockedDate['pet'] != 'BLOCKED') {
                return Container(); // Return an empty container for non-blocked dates
              }

              String id = blockedDate['id'];
              Timestamp startTime = blockedDate['startTime'];
              Timestamp endTime = blockedDate['endTime'];

              DateTime startTimeDateTime = startTime.toDate();
              DateTime endTimeDateTime = endTime.toDate();

              String formattedDateStart =
                  DateFormat('MMMM d, y ').format(startTimeDateTime);

              String formattedDateEnd =
                  DateFormat('MMMM d, y ').format(endTimeDateTime);

              return Padding(
                padding: const EdgeInsets.only(right: 8, left: 8, top: 2),
                child: InkWell(
                  onLongPress: () {
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.confirm,
                      title: 'Remove Blocked Dates?',
                      onConfirmBtnTap: () async {
                        try {
                          await FirebaseFirestore.instance
                              .runTransaction((transaction) async {
                            DocumentReference<Map<String, dynamic>> unitRef =
                                FirebaseFirestore.instance
                                    .collection('appointments')
                                    .doc('schedules');

                            // Fetch the latest data within the transaction
                            DocumentSnapshot<Map<String, dynamic>>
                                schedulesQuery = await transaction.get(unitRef);

                            List<dynamic> appointmentsData =
                                schedulesQuery.data()?['appointments'] ?? [];

                            // Remove the blocked date with the specified ID
                            appointmentsData.removeWhere((appointment) =>
                                appointment['id'] == id &&
                                appointment['pet'] == 'BLOCKED');

                            // Update the document within the transaction
                            transaction.update(
                                unitRef, {'appointments': appointmentsData});
                          });
                          Navigator.pop(context);
                          QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                              title: 'Blocked Dates Removed');
                        } catch (e) {
                          print("Failed to delete blocked date: $e");
                        }
                      },
                    );
                  },
                  child: Card(
                    elevation: 20,
                    child: ListTile(
                      title: Column(
                        children: [
                          Row(
                            children: [
                              const Text('Start: '),
                              Text(
                                formattedDateStart,
                                style: const TextStyle(color: Colors.green),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              const Text('End: '),
                              Text(
                                formattedDateEnd,
                                style: const TextStyle(color: Colors.red),
                              )
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
        },
      ),
    );
  }
}
