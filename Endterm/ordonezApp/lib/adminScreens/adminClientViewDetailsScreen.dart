import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ordonez_vet/adminScreens/adminClientPetsViewDetailsScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class AdmminClientViewDetailsScreen extends StatefulWidget {
  const AdmminClientViewDetailsScreen({super.key, required this.uid});
  final uid;

  @override
  State<AdmminClientViewDetailsScreen> createState() =>
      _AdmminClientViewDetailsScreenState();
}

class _AdmminClientViewDetailsScreenState
    extends State<AdmminClientViewDetailsScreen> {
  String uid = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      uid = widget.uid;
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
        title: const Text('Client Details'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
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
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Pets',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20.0),
                                  StreamBuilder<
                                      QuerySnapshot<Map<String, dynamic>>>(
                                    stream: FirebaseFirestore.instance
                                        .collection('pets')
                                        .where('user_uid',
                                            isEqualTo: widget.uid)
                                        .snapshots(),
                                    builder: (context, petSnapshot) {
                                      if (petSnapshot.hasData &&
                                          petSnapshot.data != null &&
                                          petSnapshot.data!.docs.isNotEmpty) {
                                        return Column(
                                          children: petSnapshot.data!.docs
                                              .map((petDoc) {
                                            Map<String, dynamic> petData =
                                                petDoc.data();
                                            String petName =
                                                petData['name'] ?? '';
                                            String petSpecies =
                                                petData['species'] ?? '';
                                            // Add more fields as needed

                                            return InkWell(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  CupertinoPageRoute(
                                                    builder: (BuildContext
                                                            context) =>
                                                        AdminClientPetsViewDetailsScreen(
                                                      uid: uid,
                                                      petName: petName,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Card(
                                                elevation: 20,
                                                child: ListTile(
                                                  title: Text(petName),
                                                  subtitle: Text(petSpecies),
                                                  trailing: const Icon(
                                                    Icons.arrow_circle_right,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      } else {
                                        return const Text('No pets available');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
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
