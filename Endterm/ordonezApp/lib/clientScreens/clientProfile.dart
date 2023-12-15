import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ordonez_vet/clientScreens/clientProfileEditScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;

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
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            Map<String, dynamic> userData =
                snapshot.data!.data() as Map<String, dynamic>;

            String fullName = userData['user_fullName'] ?? '';
            String fullAddress = userData['user_address'] ?? '';
            String sex = userData['user_sex'] ?? '';
            String phone = userData['user_phone'] ?? '';

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
                        CircleAvatar(
                          radius: 65.0,
                          backgroundColor: const Color(0xff0C356A),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 60.0,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image(
                                image: sex == 'Male'
                                    ? const AssetImage('assets/male_icon.png')
                                    : const AssetImage(
                                        'assets/female_icon.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          fullAddress,
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          sex,
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        GestureDetector(
                          onTap: () {
                            _launchPhone(phone);
                          },
                          onLongPress: () {
                            _copyToClipboard(phone);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Phone number copied to clipboard'),
                              ),
                            );
                          },
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 18.0,
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (BuildContext context) =>
                                    ClientProfileEditScreen(
                                  fullName: fullName,
                                  fullAddress: fullAddress,
                                  phone: phone,
                                  sex: sex,
                                ),
                              ),
                            );
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
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return const Text('No data available');
          }
        },
      ),
    );
  }
}

void _launchPhone(String phoneNumber) async {
  if (phoneNumber.isNotEmpty) {
    final Uri url = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

void _copyToClipboard(String text) {
  Clipboard.setData(ClipboardData(text: text));
}
