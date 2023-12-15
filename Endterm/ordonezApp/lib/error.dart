import 'package:flutter/material.dart';

class errorScreen extends StatelessWidget {
  const errorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Error has occurred. Please contact developer'),
      ),
    );
  }
}
