import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class registerScreen extends StatefulWidget {
  const registerScreen({super.key});

  @override
  State<registerScreen> createState() => _registerScreenState();
}

class _registerScreenState extends State<registerScreen> {
  final pinController = TextEditingController();
  final fullNameController = TextEditingController();
  String? userType;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpassController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();

  var obscurePassword = true;
  final _formkey = GlobalKey<FormState>();
  final collectionPath = 'users';

  void registerClient() async {
    Navigator.pop(context);
    try {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.loading,
        backgroundColor: const Color(0xFFF4EEE0),
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      if (userCredential.user == null) {
        throw FirebaseAuthException(code: 'null-usercredential');
      }
      String uid = userCredential.user!.uid;
      FirebaseFirestore.instance.collection(collectionPath).doc(uid).set({
        'fullName': fullNameController.text,
        'user_type': userType.toString(),
      });
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      QuickAlert.show(
          backgroundColor: const Color(0xFFF4EEE0),
          context: context,
          type: QuickAlertType.success,
          text: 'Signed Up Successfully');
    } on FirebaseAuthException catch (ex) {
      if (ex.code == 'weak-password') {
        Navigator.of(context).pop();
        QuickAlert.show(
            backgroundColor: const Color(0xFFF4EEE0),
            context: context,
            type: QuickAlertType.error,
            title:
                'Your password is weak. Please enter more than 6 characters.');

        return;
      }
      if (ex.code == 'email-already-in-use') {
        Navigator.of(context).pop();
        QuickAlert.show(
            backgroundColor: const Color(0xFFF4EEE0),
            context: context,
            type: QuickAlertType.error,
            title: 'Your email is already registered.');

        return;
      }
      if (ex.code == 'null-usercredential') {
        Navigator.of(context).pop();
        QuickAlert.show(
            backgroundColor: const Color(0xFFF4EEE0),
            context: context,
            type: QuickAlertType.error,
            title: 'An error occured while creating your account. Try again.');
      }

      print(ex.code);
    }
  }

  void validateInput() async {
    if (_formkey.currentState!.validate()) {
      if (userType == 'Admin') {
        // Retrieve value from Firestore
        String firestoreValue = await FirebaseFirestore.instance
            .collection('auth')
            .doc('pass')
            .get()
            .then((snapshot) => snapshot.data()?['pin']);

        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Please Input Verification Pin'),
              content: TextField(
                obscureText: true,
                controller: pinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pin',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: const Text('Submit'),
                  onPressed: () {
                    if (pinController.text == firestoreValue) {
                      // Correct pin
                      pinController.clear();
                      QuickAlert.show(
                        backgroundColor: const Color(0xFFF4EEE0),
                        context: context,
                        type: QuickAlertType.confirm,
                        text: null,
                        confirmBtnText: 'Yes',
                        cancelBtnText: 'Cancel',
                        onConfirmBtnTap: () {
                          Navigator.pop(context);
                          registerClient();
                        },
                      );
                    } else {
                      // Incorrect pin
                      Navigator.pop(context);
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.error,
                        title: 'Incorrect Pin',
                      );
                      pinController.clear();
                    }
                  },
                ),
              ],
            );
          },
        );
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.confirm,
          onConfirmBtnTap: () {
            registerClient();
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register account',
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Form(
              key: _formkey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    height: 12,
                  ),

                  //full name
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Required. Please enter your full name.';
                      }
                      return null;
                    },
                    focusNode: _focusNode4,
                    onFieldSubmitted: (value) {
                      _focusNode4.unfocus();
                      validateInput();
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

                  const SizedBox(
                    height: 12.0,
                  ),

                  //user type
                  DropdownButtonFormField<String>(
                    value: userType,
                    decoration: const InputDecoration(
                      labelText: 'User Type',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a user type.';
                      }
                      return null;
                    },
                    items: <String>[
                      'Admin',
                      'Staff',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        userType = value;
                      });
                    },
                  ),

                  const SizedBox(
                    height: 12.0,
                  ),

                  //email
                  TextFormField(
                    focusNode: _focusNode,
                    onFieldSubmitted: (value) {
                      _focusNode.unfocus();
                      validateInput();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Required. Please enter an email address.';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(
                          color: Colors.black,
                        )),
                  ),
                  const SizedBox(
                    height: 12.0,
                  ),

                  //password
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Required. Please enter your password.';
                      }
                      if (value.length <= 6) {
                        return 'Password must be more than 6 characters';
                      }
                      return null;
                    },
                    focusNode: _focusNode2,
                    onFieldSubmitted: (value) {
                      _focusNode2.unfocus();
                      validateInput();
                    },
                    obscureText: obscurePassword,
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: const TextStyle(color: Colors.black),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12.0,
                  ),

                  //confirm password
                  TextFormField(
                    onFieldSubmitted: (value) {
                      _focusNode3.unfocus();
                      validateInput();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '*Required. Please enter your password.';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords don\'t match';
                      }
                      return null;
                    },
                    focusNode: _focusNode3,
                    obscureText: obscurePassword,
                    controller: confirmpassController,
                    decoration: const InputDecoration(
                      labelText: 'Re-type Password',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 12.0,
                  ),
                  ElevatedButton(
                    onPressed: validateInput,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff820000),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18))),
                    child: const Text('Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
