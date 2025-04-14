import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/onboarding_page.dart';
import 'screens/login_page.dart';
import 'screens/sign_in_page.dart';
import 'screens/form_page.dart';
import 'screens/dashboard.dart';
import 'screens/Healthtracking.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MealMetricsApp());
}

class MealMetricsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MealMetrics',
      home: AuthWrapper(), // This will decide the first page dynamically
      routes: {
        '/login': (context) => LoginPage(),
        '/signin': (context) => SignInPage(),
        '/form': (context) => FormPage(),
        '/healthtracking': (context) => HealthTrackingPage(),
      },
    );
  }
}

/// **AuthWrapper - Checks if User is Logged In and if Form is Completed**
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, formSnapshot) {
              if (formSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (formSnapshot.hasData && formSnapshot.data!.exists) {
                final userData = formSnapshot.data!.data() as Map<String, dynamic>;
                bool isFormCompleted = userData['formCompleted'] ?? false;

                if (isFormCompleted) {
                  return HealthTrackingPage(); // Redirect to Dashboard if form is completed
                } else {
                  return FormPage(); // Redirect to Form page if form is not completed
                }
              } else {
                return FormPage(); // If no data exists, assume form is not completed
              }
            },
          );
        } else {
          return OnboardingPage(); // If user is not signed in, go to onboarding
        }
      },
    );
  }
}
