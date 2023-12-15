import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class ClientPetDetailsEditScreen extends StatefulWidget {
  const ClientPetDetailsEditScreen(
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
  State<ClientPetDetailsEditScreen> createState() =>
      _ClientPetDetailsEditScreenState();
}

class _ClientPetDetailsEditScreenState
    extends State<ClientPetDetailsEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController petNameController = TextEditingController();
  TextEditingController petSpeciesController = TextEditingController();
  TextEditingController petBreedController = TextEditingController();
  TextEditingController petBirthdayController = TextEditingController();
  TextEditingController petColorController = TextEditingController();

  String? userId = FirebaseAuth.instance.currentUser?.uid;
  String? petSex;

  DateTime? selectedDate;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      petNameController.text = widget.petName;
      petSpeciesController.text = widget.petSpecies;
      petBreedController.text = widget.petBreed;
      petSex = widget.petSex;
      petColorController.text = widget.petColor;
      petBirthdayController.text = widget.petBirthday;
    });
  }

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
        petBirthdayController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pet Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20.0),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    TextFormField(
                      controller: petSpeciesController,
                      decoration: const InputDecoration(
                        labelText: 'Pet Species',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pet species';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    //pet breed
                    TextFormField(
                      controller: petBreedController,
                      decoration: const InputDecoration(
                        labelText: 'Pet Breed',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pet breed';
                        }
                        return null;
                      },
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
                    TextFormField(
                      controller: petBirthdayController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Pet Birthday',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      onTap: () {
                        _selectDate(context);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pet birthday';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    //pet color
                    TextFormField(
                      controller: petColorController,
                      decoration: const InputDecoration(
                        labelText: 'Pet Color',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pet color';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0174BE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.confirm,
                            title: 'Update Profile?',
                            onConfirmBtnTap: () async {
                              // Form is valid, proceed with saving
                              Map<String, dynamic> updatedData = {
                                'name': petNameController.text,
                                'species': petSpeciesController.text,
                                'breed': petBreedController.text,
                                'sex': petSex,
                                'birthday': petBirthdayController.text,
                                'color': petColorController.text,
                              };

                              // Use where clauses to identify the specific pet document to update
                              await FirebaseFirestore.instance
                                  .collection('pets')
                                  .where('user_uid', isEqualTo: userId)
                                  .where('name', isEqualTo: widget.petName)
                                  .get()
                                  .then((QuerySnapshot<Map<String, dynamic>>
                                      querySnapshot) {
                                if (querySnapshot.docs.isNotEmpty) {
                                  // Assuming pet names are unique for a user, take the first document
                                  String petId = querySnapshot.docs.first.id;
                                  FirebaseFirestore.instance
                                      .collection('pets')
                                      .doc(petId)
                                      .update(updatedData)
                                      .then((_) {
                                    Navigator.pop(context);

                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.success,
                                      text: 'Profile Updated!',
                                    );
                                  }).catchError((error) {
                                    print('Error updating pet profile: $error');
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
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
