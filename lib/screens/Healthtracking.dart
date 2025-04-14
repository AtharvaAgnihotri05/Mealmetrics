import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'add_food.dart';
import 'food_suggestion.dart';

class HealthTrackingPage extends StatefulWidget {
  @override
  _HealthTrackingPageState createState() => _HealthTrackingPageState();
}

class _HealthTrackingPageState extends State<HealthTrackingPage> {
  DateTime selectedDate = DateTime.now();
  Map<String, double> allowedNutrients = {
    'Calories': 2000,
    'Protein': 50,
    'Carbs': 300,
    'Fat': 70,
  };
  Map<String, List<FlSpot>> hourlyData = {};
  int _bottomNavIndex = 1;
  String? userName;
  bool isLoading = true;

  // User metrics
  double? userWeight;
  double? userHeight;
  String? userGoal;

  @override
  void initState() {
    super.initState();
    _initializeHourlyData();
    _fetchUserData();
    _fetchGraphData();
  }

  void _initializeHourlyData() {
    allowedNutrients.forEach((nutrient, limit) {
      hourlyData[nutrient] = List.generate(24, (index) => FlSpot(index.toDouble(), 0));
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            userName = data['name'] ?? 'User';
            userWeight = (data['weight'] as num?)?.toDouble();
            userHeight = (data['height'] as num?)?.toDouble();
            userGoal = data['goal'] ?? 'Not set';
            isLoading = false;
          });
        } else {
          setState(() {
            userName = "User";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        userName = "User";
        isLoading = false;
      });
    }
  }

  Future<void> _fetchGraphData() async {
    Map<String, List<FlSpot>> newHourlyData = {};
    allowedNutrients.forEach((nutrient, _) {
      newHourlyData[nutrient] = List.generate(24, (index) => FlSpot(index.toDouble(), 0));
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DateTime start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      DateTime end = start.add(const Duration(days: 1));

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('foodEntries')
          .where("userId", isEqualTo: user.uid)
          .where("timestamp", isGreaterThanOrEqualTo: start)
          .where("timestamp", isLessThan: end)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final double docCalories = (data["calories"] ?? 0).toDouble();
        final double quantity = (data["quantity"] ?? 1).toDouble();
        final nutrition = data["nutrition"] as Map<String, dynamic>? ?? {};
        final double docProtein = (nutrition["protein_grams"] ?? 0).toDouble();
        final double docCarbs = (nutrition["carbohydrates_grams"] ?? 0).toDouble();
        final double docFat = (nutrition["fat_grams"] ?? 0).toDouble();

        final Timestamp timestamp = data["timestamp"] as Timestamp;
        final DateTime time = timestamp.toDate();
        final int hour = time.hour;

        newHourlyData["Calories"]![hour] =
            FlSpot(hour.toDouble(), newHourlyData["Calories"]![hour].y + docCalories * quantity);
        newHourlyData["Protein"]![hour] =
            FlSpot(hour.toDouble(), newHourlyData["Protein"]![hour].y + docProtein * quantity);
        newHourlyData["Carbs"]![hour] =
            FlSpot(hour.toDouble(), newHourlyData["Carbs"]![hour].y + docCarbs * quantity);
        newHourlyData["Fat"]![hour] =
            FlSpot(hour.toDouble(), newHourlyData["Fat"]![hour].y + docFat * quantity);
      }
    } catch (e) {
      print("Error fetching graph data: $e");
    }

    setState(() {
      hourlyData = newHourlyData;
    });
  }

  // Function to show the dialog to update user metrics
  void _showUpdateMetricsDialog() {
    final weightController = TextEditingController(text: userWeight?.toString());
    final heightController = TextEditingController(text: userHeight?.toString());
    final goalController = TextEditingController(text: userGoal);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Your Metrics"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Weight (kg)"),
              ),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Height (cm)"),
              ),
              TextField(
                controller: goalController,
                decoration: const InputDecoration(labelText: "Health Goal"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final updatedWeight = double.tryParse(weightController.text);
                final updatedHeight = double.tryParse(heightController.text);
                final updatedGoal = goalController.text;

                if (updatedWeight != null && updatedHeight != null) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'weight': updatedWeight,
                      'height': updatedHeight,
                      'goal': updatedGoal,
                    });

                    setState(() {
                      userWeight = updatedWeight;
                      userHeight = updatedHeight;
                      userGoal = updatedGoal;
                    });
                  }
                }

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.subtract(const Duration(days: 1));
              });
              _fetchGraphData();
            },
          ),
          Text(
            "${selectedDate.toLocal().toString().split(' ')[0]}",
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.add(const Duration(days: 1));
              });
              _fetchGraphData();
            },
          ),
        ],
      ),
    );
  }

  Widget buildBmiBox() {
    double bmi = 0;
    String category = "Unavailable";

    if (userWeight != null && userHeight != null && userHeight! > 0) {
      double heightMeters = userHeight! / 100;
      bmi = userWeight! / (heightMeters * heightMeters);

      if (bmi < 18.5) {
        category = "Underweight";
      } else if (bmi < 25) {
        category = "Normal";
      } else if (bmi < 30) {
        category = "Overweight";
      } else {
        category = "Obese";
      }
    }

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("BMI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(bmi.toStringAsFixed(1),
                style: const TextStyle(fontSize: 24, color: Colors.teal)),
            const SizedBox(height: 4),
            Text(category, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            if (userGoal != null)
              Text("Goal: $userGoal", style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget buildLineChart(String nutrient, Color lineColor) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 4,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (allowedNutrients[nutrient]! / 4).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: allowedNutrients[nutrient]! * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: hourlyData[nutrient] ?? [],
            isCurved: true,
            barWidth: 2,
            color: lineColor,
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.3),
            ),
            dotData: FlDotData(show: false),
          )
        ],
      ),
    );
  }

  Widget buildNutrientSlider() {
    return Column(
      children: allowedNutrients.keys.map((nutrient) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nutrient, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 200, child: buildLineChart(nutrient, Colors.teal)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrawerHeader() {
    String displayName = userName ?? 'User';
    String initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';

    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.teal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: const TextStyle(
                  fontSize: 24, color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AddFoodPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Text(userName != null ? 'Hi! $userName' : 'Health Tracking'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(),
            ListTile(
              leading: const Icon(Icons.fastfood),
              title: const Text('Meal Suggestions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FoodSuggestionPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: _showUpdateMetricsDialog,  // Show popup dialog for updating metrics
            ),
            ListTile(
              leading: const Icon(Icons.logout_sharp),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildDateSelector(),
            buildBmiBox(),
            buildNutrientSlider(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.space_dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood_sharp), label: 'Add Food'),
        ],
      ),
    );
  }
}
