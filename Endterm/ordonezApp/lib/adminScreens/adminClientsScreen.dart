import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ordonez_vet/adminScreens/adminClientViewDetailsScreen.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
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
        title: const Text('Clients'),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('user_type', isEqualTo: 'Client')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // If there are no documents, display a message
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No Client Users found.'),
            );
          }

          // If there are documents, display a ListView
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var userData =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var uid = snapshot.data!.docs[index].id;

              String name = userData['user_fullName'];
              String address = userData['user_address'];

              // Display user data in your desired format
              return Padding(
                padding: const EdgeInsets.only(right: 8, left: 8, top: 2),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (BuildContext contex) =>
                            AdmminClientViewDetailsScreen(
                          uid: uid,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 20,
                    child: ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(address),
                      trailing: const Icon(
                        Icons.arrow_circle_right,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
