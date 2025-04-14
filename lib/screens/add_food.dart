import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart';
import 'Healthtracking.dart';

class AddFoodPage extends StatefulWidget {
  @override
  _AddFoodPageState createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');

  bool _isLoading = false;
  List<dynamic> _trackedFoods = [];
  dynamic _selectedFood;

  int _currentIndex = 2;
  String _selectedMeasurement = 'grams';
  int _quantity = 1;
  double _calculatedCalories = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  final List<String> measurements = ['grams', 'piece', 'ml', 'slice'];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadTrackedFoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Food"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16),
                if (_isLoading) const LinearProgressIndicator(),
                if (_selectedFood != null) _buildFoodDetailsContainer(),
                const SizedBox(height: 16),
                _buildTrackedFoodsContainer(),
              ],
            ),
          ),
          _buildAIChatButton(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: "Search Food",
        hintText: "e.g., Apple, Chicken Breast, etc.",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: const Icon(Icons.search, color: Colors.teal),
          onPressed: () => _searchFood(_searchController.text),
        ),
      ),
      onSubmitted: _searchFood,
    );
  }

  Widget _buildFoodDetailsContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _selectedFood['photo'] != null
                  ? Image.network(
                _selectedFood['photo']['thumb'],
                width: 60,
                height: 60,
              )
                  : const Icon(Icons.fastfood, size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFood['food_item'] ?? 'Unknown Food',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Calories: ${_calculatedCalories.toStringAsFixed(1)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: measurements.map((measure) {
              return ChoiceChip(
                label: Text(measure),
                selected: _selectedMeasurement == measure,
                onSelected: (selected) {
                  setState(() {
                    _selectedMeasurement = measure;
                  });
                  _searchFood(_searchController.text);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    if (_quantity > 1) _quantity--;
                    _quantityController.text = _quantity.toString();
                  });
                  _searchFood(_searchController.text);
                },
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onSubmitted: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        _quantity = parsed;
                      });
                      _searchFood(_searchController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid positive number')),
                      );
                      _quantityController.text = _quantity.toString();
                    }
                  },
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _quantity++;
                    _quantityController.text = _quantity.toString();
                  });
                  _searchFood(_searchController.text);
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saveFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackedFoodsContainer() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracked Foods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _trackedFoods.isEmpty
                  ? const Center(child: Text('No foods tracked yet'))
                  : ListView.builder(
                itemCount: _trackedFoods.length,
                itemBuilder: (context, index) {
                  final food = _trackedFoods[index];
                  return ListTile(
                    leading: const Icon(Icons.fastfood, color: Colors.teal),
                    title: Text(food['foodName'] ?? 'Unknown Food'),
                    subtitle: Text(
                        '${food['calories']?.toStringAsFixed(1) ?? '0'} kcal - ${food['quantity']} ${food['measurement']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFood(food['id']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIChatButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: _showRecommendationPopup,
        backgroundColor: Colors.teal,
        child: Stack(
          children: [
            const Icon(Icons.food_bank, color: Colors.white),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange,
                ),
                child: const Text(
                  ' ',
                  style: TextStyle(fontSize: 8, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.space_dashboard_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Food'),
      ],
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        if (index == 0) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardPage()));
        } else if (index == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HealthTrackingPage()));
        }
      },
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
    );
  }

  Future<void> _searchFood(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _selectedFood = null;
    });
    final url = Uri.parse(
      'https://mealmetrics.onrender.com/api/get_nutrition?food_item=$query&quantity=$_quantity&unit=$_selectedMeasurement',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedFood = data;
          _calculatedCalories = data['calories']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching nutrition: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFood() async {
    if (_currentUser == null || _selectedFood == null) return;
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).collection('foodEntries').add({
        'userId': _currentUser!.uid,
        'foodName': _selectedFood['food_item'] ?? 'Unknown Food',
        'calories': _calculatedCalories,
        'quantity': _quantity,
        'measurement': _selectedMeasurement,
        'timestamp': FieldValue.serverTimestamp(),
        'nutrition': {
          'carbohydrates_grams': _selectedFood['carbohydrates_grams'] ?? 0,
          'fat_grams': _selectedFood['fat_grams'] ?? 0,
          'protein_grams': _selectedFood['protein_grams'] ?? 0,
          'sugar_grams': _selectedFood['sugar_grams'] ?? 0,
          'fiber_grams': _selectedFood['fiber_grams'] ?? 0,
          'sodium_mg': _selectedFood['sodium_mg'] ?? 0,
        },
      });
      _loadTrackedFoods();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving food: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrackedFoods() async {
    if (_currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('foodEntries')
          .orderBy('timestamp', descending: true)
          .get();
      setState(() {
        _trackedFoods = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading foods: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFood(String foodId) async {
    if (_currentUser == null) return;
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).collection('foodEntries').doc(foodId).delete();
      _loadTrackedFoods();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting food: $e')),
      );
    }
  }

  Future<void> _showRecommendationPopup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final url = Uri.parse("https://mealmetrics.onrender.com/api/get_suggestions");
      final body = json.encode({
        "user_goal": "weight loss",
        "current_macros": {"calories": 2000, "protein": 150, "carbs": 200, "fat": 50},
        "last_meals": ["oatmeal", "salad"]
      });
      final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
      Navigator.pop(context);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List<dynamic>? ?? [];
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("AI Suggestions"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    title: Text(suggestion['name'] ?? 'No Name'),
                    subtitle: Text("Calories: ${suggestion['calories'] ?? 'N/A'}"),
                  );
                },
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Failed to fetch suggestions."),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(e.toString()),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
        ),
      );
    }
  }
}
