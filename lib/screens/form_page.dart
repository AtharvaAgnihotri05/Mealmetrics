import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormPage extends StatefulWidget {
  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _healthGoal = 'Weight Loss';
  String _activityLevel = 'Sedentary';
  String _gender = 'Male';
  String _foodPreference = 'Vegetarian'; // New Field

  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _saveData() async {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'weight': double.tryParse(_weightController.text) ?? 0.0,
        'height': double.tryParse(_heightController.text) ?? 0.0,
        'healthGoal': _healthGoal,
        'foodPreference': _foodPreference, // Save Food Preference
        'activityLevel': _activityLevel,
        'gender': _gender,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved successfully!')),
      );

      Navigator.pushReplacementNamed(context, '/healthtracking');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/cropped.jpg', fit: BoxFit.cover),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Personal Details Form',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    _buildTextField(_nameController, 'Name'),
                    _buildTextField(_ageController, 'Age', isNumber: true),
                    _buildTextField(_weightController, 'Weight (kg)', isNumber: true),
                    _buildTextField(_heightController, 'Height (cm)', isNumber: true),

                    _buildDropdown('Health Goals', _healthGoal, [
                      'Weight Loss',
                      'Muscle Gain',
                      'Maintenance'
                    ], (value) => setState(() => _healthGoal = value!)),

                    // New Food Preference Section
                    _buildDropdown('Food Preference', _foodPreference, [
                      'Vegan',
                      'Vegetarian',
                      'Eggetarian',
                      'Non-Vegetarian',
                      'Pescatarian',
                      'Other'
                    ], (value) => setState(() => _foodPreference = value!)),

                    _buildDropdown('Activity Level', _activityLevel, [
                      'Sedentary',
                      'Lightly Active',
                      'Moderately Active',
                      'Very Active',
                      'Super Active'
                    ], (value) => setState(() => _activityLevel = value!)),

                    _buildDropdown('Gender', _gender, [
                      'Male',
                      'Female',
                      'Other'
                    ], (value) => setState(() => _gender = value!)),

                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveData,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
