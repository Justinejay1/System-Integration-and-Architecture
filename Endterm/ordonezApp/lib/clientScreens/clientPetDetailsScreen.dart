import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ordonez_vet/clientScreens/clientPetDetailsEditScreen.dart';

class ClientPetDetailsScreen extends StatefulWidget {
  const ClientPetDetailsScreen(
      {super.key,
      required this.petName,
      required this.petSpecies,
      required this.petBreed,
      required this.petSex,
      required this.petBirthday,
      required this.petColor});

  final petName;
  final petSpecies;
  final petBreed;
  final petSex;
  final petBirthday;
  final petColor;

  @override
  State<ClientPetDetailsScreen> createState() => _ClientPetDetailsScreenState();
}

class _ClientPetDetailsScreenState extends State<ClientPetDetailsScreen> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Details'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('pets')
            .where('user_uid', isEqualTo: userId)
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
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(CupertinoPageRoute(
                                  builder: (BuildContext context) =>
                                      ClientPetDetailsEditScreen(
                                          petName: petName,
                                          petSpecies: petSpecies,
                                          petBreed: petBreed,
                                          petSex: petSex,
                                          petBirthday: petBirthday,
                                          petColor: petColor)));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0174BE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Edit Profile'),
                          ),
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
