import 'package:flutter/material.dart';

class LogoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Optional: Set background color
      body: Center(
        child: Image.asset(
          'assets/logo.png', // Path to your logo image
          width: 150,        // Adjust the size as needed
          height: 150,
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: LogoPage()));
