// import 'package:flutter/material.dart';
//
// class LoginPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Image.asset(
//             'assets/cropped.jpg',
//             fit: BoxFit.cover,
//           ),
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   SizedBox(
//                     width: 300,
//                     child: TextField(
//                       decoration: InputDecoration(
//                         labelText: 'Username',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   SizedBox(
//                     width: 300,
//                     child: TextField(
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   SizedBox(
//                     width: 300,
//                     child: TextField(
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         border: OutlineInputBorder(),
//                       ),
//                       obscureText: true,
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.pushNamed(context, '/dashboard');
//                     },
//                     child: Text('Login'),
//                   ),
//                   SizedBox(height: 20),
//                   TextButton(
//                     onPressed: () => Navigator.pushNamed(context, '/signin'),
//                     child: Text(
//                       "Don't have an account? Sign In",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Flag to show loading indicator while logging in
  bool _isLoading = false;

  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      // Display error message if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in both email and password")),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() {
        _isLoading = false; // Hide loading indicator
      });

      print("User logged in: ${userCredential.user!.uid}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Successful!")),
      );

      Navigator.pushReplacementNamed(context, '/healthtracking'); // Redirect to Dashboard
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator if error occurs
      });

      String errorMessage = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Wrong password provided.";
      }

      print("Login error: $errorMessage");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator for any other errors
      });

      print("Unexpected error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/cropped.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator() // Show loading spinner
                      : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signin'),
                    child: Text(
                      "Don't have an account? Sign Up",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

