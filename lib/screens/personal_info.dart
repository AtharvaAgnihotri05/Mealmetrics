import 'package:flutter/material.dart';

class PersonalInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Info"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "Personal Info Content Here",
          style: TextStyle(fontSize: 20, color: Colors.blue),
        ),
      ),
    );
  }
}
