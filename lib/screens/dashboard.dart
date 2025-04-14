import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Healthtracking.dart';
import 'add_food.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isDarkMode = false;
  Map<String, dynamic>? userData;
  int _bottomNavIndex = 1; // "Chat" is the current tab
  User? _currentUser;

  // For AI chat
  final TextEditingController _chatController = TextEditingController();
  List<Map<String, String>> _conversation = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  // Fetch user profile data from Firestore (for goal and other info)
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userData = snapshot.data() as Map<String, dynamic>?;
      });
    }
  }

  // Aggregate whole day's macros from food entries.
  Future<Map<String, dynamic>> _aggregateDailyMacros() async {
    if (_currentUser == null) return {};
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('foodEntries')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .get();

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalSodium = 0;
    double totalSugar = 0;

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      totalCalories += (data['calories'] ?? 0).toDouble();
      var nutrition = data['nutrition'] as Map<String, dynamic>? ?? {};
      totalCarbs += (nutrition['carbohydrates_grams'] ?? 0).toDouble();
      totalProtein += (nutrition['protein_grams'] ?? 0).toDouble();
      totalFat += (nutrition['fat_grams'] ?? 0).toDouble();
      totalSodium += (nutrition['sodium_mg'] ?? 0).toDouble();
      totalSugar += (nutrition['sugar_grams'] ?? 0).toDouble();
    }
    print("Aggregator results: Calories: $totalCalories, Protein: $totalProtein, Carbs: $totalCarbs, Fat: $totalFat, Sodium: $totalSodium, Sugar: $totalSugar");
    return {
      "calories": totalCalories,
      "protein": totalProtein,
      "carbs": totalCarbs,
      "fat": totalFat,
      "sodium_mg": totalSodium,
      "sugar_grams": totalSugar,
    };
  }

  // Logout method.
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Logged out successfully")));
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error logging out: $e")));
    }
  }

  // Bottom navigation bar widget.
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _bottomNavIndex,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fastfood),
          label: 'Food',
        ),
      ],
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() {
          _bottomNavIndex = index;
        });
        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HealthTrackingPage()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AddFoodPage()),
          );
        }
      },
    );
  }

  // Chat box widget for AI conversation.
  Widget _buildChatBox() {
    // Increase height from 40% to 55% of the screen height.
    final boxHeight = MediaQuery.of(context).size.height * 0.60;
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.1,
      right: MediaQuery.of(context).size.width * 0.1,
      bottom: 80, // keep as is above bottom nav
      child: Container(
        height: boxHeight,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            // Chat messages area.
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _conversation.length,
                itemBuilder: (context, index) {
                  final message = _conversation[index];
                  bool isUser = message['sender'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(message['message'] ?? ''),
                    ),
                  );
                },
              ),
            ),
            // Chat input row.
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendChatMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Send chat message: aggregate macros and call API.
  Future<void> _sendChatMessage() async {
    String userMessage = _chatController.text.trim();
    if (userMessage.isEmpty) return;
    setState(() {
      _conversation.add({'sender': 'user', 'message': userMessage});
    });
    _chatController.clear();

    // Get user's goal from Firestore data.
    String goal = userData?['healthGoal'] ?? "weight loss";
    print("User Goal: $goal");

    // Aggregate today's macros.
    Map<String, dynamic> macros = await _aggregateDailyMacros();
    print("Aggregated Macros: $macros");

    final url = Uri.parse("https://mealmetrics.onrender.com/api/get_reply");
    final body = json.encode({
      "query": userMessage,
      "goal": goal,
      "macros": macros,
    });
    print("Request Body: $body");

    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 400) {
        final data = json.decode(response.body);
        String reply = data['reply'] ?? "No reply";
        setState(() {
          _conversation.add({'sender': 'ai', 'message': reply});
        });
      } else {
        setState(() {
          _conversation.add({'sender': 'ai', 'message': 'Error: Unable to fetch reply.'});
        });
      }
    } catch (e) {
      setState(() {
        _conversation.add({'sender': 'ai', 'message': 'Error: ${e.toString()}'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal AI"),
        backgroundColor: Colors.teal,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: const Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.brightness_6),
              title: Text('Change Theme'),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (bool value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Personal Info'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text('Personal Info'),
                    content: userData != null
                        ? Text("Name: ${userData!['name']}\nAge: ${userData!['age']}\nWeight: ${userData!['weight']}\nHeight: ${userData!['height']}\nGoal: ${userData!['healthGoal']}")
                        : Text("No data available"),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Close'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log Out'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/Background_1.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          _buildChatBox(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
