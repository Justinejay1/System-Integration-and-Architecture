import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ordonez_vet/adminScreens/adminHomeScreen.dart';
import 'package:ordonez_vet/clientScreens/clientHomeScreen.dart';
import 'package:ordonez_vet/error.dart';
import 'package:ordonez_vet/loginScreen.dart';

class authGate extends StatelessWidget {
  const authGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // User is logged in
          User? user = snapshot.data;

          // Access 'users' collection and check 'user_type' field
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                DocumentSnapshot userSnapshot = snapshot.data!;
                String userType = userSnapshot['user_type'] as String;

                if (userType == 'Admin') {
                  return const AdminHomeScreen();
                } else if (userType == 'Client') {
                  return const ClientHomeScreen();
                } else {
                  return const errorScreen();
                }
              } else if (snapshot.hasError) {
                return const errorScreen();
              } else {
                // Show a loading indicator while data is being fetched
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        } else {
          // User is not logged in
          return const LoginScreen();
        }
      },
    );
  }
}
