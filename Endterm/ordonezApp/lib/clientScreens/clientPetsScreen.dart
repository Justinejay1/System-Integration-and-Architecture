import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ordonez_vet/clientScreens/clientPetDetailsScreen.dart';
import 'package:quickalert/quickalert.dart';

class ClientPetsScreen extends StatefulWidget {
  const ClientPetsScreen({super.key});

  @override
  State<ClientPetsScreen> createState() => _ClientPetsScreenState();
}

class _ClientPetsScreenState extends State<ClientPetsScreen> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> pets = [];

  Future<List<Map<String, dynamic>>> getPetsForUser(String userUid) async {
    try {
      CollectionReference petsCollection =
          FirebaseFirestore.instance.collection('pets');

      QuerySnapshot querySnapshot =
          await petsCollection.where('user_uid', isEqualTo: userUid).get();

      List<Map<String, dynamic>> pets = [];

      for (var doc in querySnapshot.docs) {
        pets.add(doc.data() as Map<String, dynamic>);
      }

      return pets;
    } catch (error) {
      print('Error getting pets: $error');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    loadPets();
  }

  Future<void> loadPets() async {
    List<Map<String, dynamic>> userPets = await getPetsForUser(userId!);

    setState(() {
      pets = userPets;
    });
  }

  void addPet(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    TextEditingController petNameController = TextEditingController();
    TextEditingController petSpeciesController = TextEditingController();
    TextEditingController petBreedController = TextEditingController();
    TextEditingController petBirthdayController = TextEditingController();
    TextEditingController petColorController = TextEditingController();

    String? petSex;

    DateTime? selectedDate;

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );

      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
          petBirthdayController.text =
              picked.toLocal().toString().split(' ')[0];
        });
      }
    }

    AwesomeDialog(
      dismissOnTouchOutside: false,
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (formKey.currentState!.validate()) {
          try {
            // Get a reference to the Firestore instance
            FirebaseFirestore firestore = FirebaseFirestore.instance;

            // Add your collection and document reference
            CollectionReference petsCollection = firestore.collection('pets');

            // Add pet data to Firestore
            await petsCollection.add({
              'user_uid': userId,
              'name': petNameController.text,
              'species': petSpeciesController.text,
              'breed': petBreedController.text,
              'sex': petSex,
              'birthday': petBirthdayController.text,
              'color': petColorController.text,
            });

            // Close the dialog
            QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: 'Pet Registered!');
          } catch (error) {
            print('Error adding pet to Firestore: $error');
            // Handle error as needed
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
                'Register New Pet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  // Add additional properties to customize the style further if needed
                ),
              ),
              const SizedBox(height: 12),

              //pet name
              TextFormField(
                controller: petNameController,
                decoration: const InputDecoration(
                  labelText: 'Pet Name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pet name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              //pet species
              TextField(
                controller: petSpeciesController,
                decoration: const InputDecoration(
                  labelText: 'Pet Species',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              //pet sex
              DropdownButtonFormField<String>(
                value: petSex,
                decoration: const InputDecoration(
                  labelText: 'Pet Sex',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pet sex.';
                  }
                  return null;
                },
                items: <String>[
                  'Male',
                  'Female',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    petSex = value;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ).show();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPetStream(String userId) {
    return FirebaseFirestore.instance
        .collection('pets')
        .where('user_uid', isEqualTo: userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              onPressed: () {
                addPet(context);
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: getPetStream(userId!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                    child:
                        CircularProgressIndicator()); // or another loading indicator
              }

              var pets = snapshot.data!.docs;

              // Sort pets alphabetically based on the pet name
              pets.sort((a, b) =>
                  (a['name'] as String).compareTo(b['name'] as String));

              return Column(
                children: pets.map((pet) {
                  String petName = pet['name'];
                  String petSpecies = pet['species'];
                  String petBreed = pet['breed'];
                  String petSex = pet['sex'];
                  String petBirthday = pet['birthday'];
                  String petColor = pet['color'];
                  return Card(
                    elevation: 20,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(CupertinoPageRoute(
                            builder: (BuildContext context) =>
                                ClientPetDetailsScreen(
                                    petName: petName,
                                    petSpecies: petSpecies,
                                    petBreed: petBreed,
                                    petSex: petSex,
                                    petBirthday: petBirthday,
                                    petColor: petColor)));
                      },
                      onLongPress: () {
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.warning,
                          title: 'Are you sure you want to delete record?',
                          onConfirmBtnTap: () {
                            Navigator.pop(context);
                            String petName = pet['name'];
                            CollectionReference petsCollection =
                                FirebaseFirestore.instance.collection('pets');
                            Query query = petsCollection
                                .where('user_uid', isEqualTo: userId)
                                .where('name', isEqualTo: petName);

                            query.get().then((QuerySnapshot querySnapshot) {
                              // Check if the query returned any documents
                              if (querySnapshot.docs.isNotEmpty) {
                                // Delete the first document (assuming pet names are unique for a user)
                                String petId = querySnapshot.docs.first.id;
                                petsCollection.doc(petId).delete().then((_) {
                                  print('Pet deleted successfully!');

                                  QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.success,
                                      title: 'Pet Record Deleted!');
                                  // You can add additional logic or feedback to the user here
                                }).catchError((error) {
                                  print('Error deleting pet: $error');
                                  // Handle error as needed
                                });
                              } else {
                                print('Pet not found!');
                                // Handle the case where the pet is not found
                              }
                            }).catchError((error) {
                              print('Error querying pet: $error');
                              // Handle error as needed
                            });
                          },
                        );
                      },
                      child: ListTile(
                        title: Text(
                          petName,
                        ),
                        subtitle: Text(
                          petSpecies,
                        ),
                        trailing: const Icon(Icons.arrow_circle_right),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}
