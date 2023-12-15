import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdminClientPetsViewDetailsScreen extends StatefulWidget {
  const AdminClientPetsViewDetailsScreen(
      {super.key, required this.petName, required this.uid});

  final uid;
  final petName;

  @override
  State<AdminClientPetsViewDetailsScreen> createState() =>
      _AdminClientPetsViewDetailsScreenState();
}

class _AdminClientPetsViewDetailsScreenState
    extends State<AdminClientPetsViewDetailsScreen> {
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
        title: const Text('Client Pet'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('pets')
            .where('user_uid', isEqualTo: widget.uid)
            .where('name', isEqualTo: widget.petName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const CircularProgressIndicator();
          }

          var petDocs = snapshot.data!.docs;

          return Column(
            children: petDocs.map((petDoc) {
              var petData = petDoc.data();

              // Access individual fields
              final petName = petData['name'] ?? '';
              final petSpecies = petData['species'] ?? '';
              final petBreed = petData['breed'] ?? '';
              final petSex = petData['sex'] ?? '';
              final petBirthday = petData['birthday'] ?? '';
              final petColor = petData['color'] ?? '';

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Card(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CircleAvatar(
                            radius: 65.0,
                            backgroundColor: Color(0xff0C356A),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 60.0,
                              child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Icon(
                                    Icons.pets,
                                    color: Colors.black,
                                    size: 70,
                                  )),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            petName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            petSpecies,
                            style: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            petBreed,
                            style: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            petSex,
                            style: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            petBirthday,
                            style: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            petColor,
                            style: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
