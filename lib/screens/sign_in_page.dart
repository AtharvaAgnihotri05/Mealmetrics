import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_page.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'formCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Always navigate to FormPage after new signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FormPage()),
      );

    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } on FirebaseException catch (e) {
      _showError("Database error: ${e.message}");
    } catch (e) {
      _showError("Unexpected error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message = "Sign-up failed. Please try again.";
    switch (e.code) {
      case 'email-already-in-use':
        message = "Email already registered. Please login.";
        break;
      case 'weak-password':
        message = "Password too weak (min 6 characters).";
        break;
      case 'invalid-email':
        message = "Invalid email format.";
        break;
    }
    _showError(message);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                  _buildTextField(emailController, "Email", false),
                  const SizedBox(height: 10),
                  _buildTextField(passwordController, "Password", true),
                  const SizedBox(height: 10),
                  _buildTextField(confirmPasswordController, "Confirm Password", true),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Sign Up'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text("Already have an account? Login"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool isPassword) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}