import 'package:airbnb_scheduler/screens/registerScreen.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class loginScreen extends StatefulWidget {
  const loginScreen({super.key});

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  final _formkey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNode2 = FocusNode();

  var obscurePassword = true;

  void login() async {
    if (_formkey.currentState!.validate()) {
      QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: 'Checking user credentials...');

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailController.text, password: passwordController.text)
          .then((value) {
        Navigator.pop(context);
        QuickAlert.show(context: context, type: QuickAlertType.success);
      }).catchError((err) {
        print(err.code);
        if (err.code == 'user-not-found') {
          Navigator.pop(context);
          QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'User does not exist!');
        }
        if (err.code == 'wrong-password') {
          Navigator.pop(context);
          QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Incorrect Password!');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 100,
          ),
          const CircleAvatar(
              backgroundColor: Color(0xff4E6C50),
              maxRadius: 50,
              child: Icon(
                Icons.date_range,
                size: 50,
                color: Colors.white,
              )),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'LODGE',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            height: 25,
          ),
          Form(
            key: _formkey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //email
                  TextFormField(
                    focusNode: _focusNode,
                    onFieldSubmitted: (value) {
                      _focusNode.unfocus();
                      login();
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
                      login();
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff820000),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18))),
                    onPressed: login,
                    child: const Text('Login'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff820000),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18))),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) {
                          return const registerScreen();
                        }),
                      );
                    },
                    child: const Text('Register new account'),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Copyright ©️ 2023 TechWave. All rights reserved',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
