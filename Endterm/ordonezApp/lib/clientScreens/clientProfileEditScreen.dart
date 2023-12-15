import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class ClientProfileEditScreen extends StatefulWidget {
  const ClientProfileEditScreen(
      {super.key,
      required this.fullName,
      required this.fullAddress,
      required this.phone,
      required this.sex});

  final fullName;
  final fullAddress;
  final sex;
  final phone;

  @override
  State<ClientProfileEditScreen> createState() =>
      _ClientProfileEditScreenState();
}

class _ClientProfileEditScreenState extends State<ClientProfileEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final fullAddressController = TextEditingController();
  String? userSex;
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      fullNameController.text = widget.fullName;
      fullAddressController.text = widget.fullAddress;
      phoneController.text = widget.phone;
      userSex = widget.sex;
    });
  }

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
        title: const Text('Edit Profile'),
        centerTitle: true,
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
                    const SizedBox(height: 12.0),
                    //full name
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '*Required. Please enter your full name.';
                        }
                        return null;
                      },
                      controller: fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    //sex
                    DropdownButtonFormField<String>(
                      value: userSex,
                      decoration: const InputDecoration(
                        labelText: 'Sex',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please sex.';
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
                          userSex = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12.0),
                    //full address
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '*Required. Please enter your address.';
                        }
                        return null;
                      },
                      maxLines: 2,
                      controller: fullAddressController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Address',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    //phone
                    TextFormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '*Required. Please enter your phone number.';
                        }
                        return null;
                      },
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0174BE),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.confirm,
                            title: 'Update Profile?',
                            onConfirmBtnTap: () async {
                              // Form is valid, proceed with saving
                              Map<String, dynamic> updatedData = {
                                'user_uid': userId,
                                'user_fullName': fullNameController.text,
                                'user_sex': userSex,
                                'user_address': fullAddressController.text,
                                'user_phone': phoneController.text,
                              };

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .update(updatedData);

                              Navigator.pop(context);
                              QuickAlert.show(
                                context: context,
                                type: QuickAlertType.success,
                                text: 'Profile Updated!',
                              );
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
