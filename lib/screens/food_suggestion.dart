import 'package:flutter/material.dart';

class FoodSuggestionPage extends StatefulWidget {
  @override
  _FoodSuggestionPageState createState() => _FoodSuggestionPageState();
}

class _FoodSuggestionPageState extends State<FoodSuggestionPage> {
  // Dummy data for meal suggestions - later replace with API data.
  final List<Map<String, String>> breakfastSuggestions = [
    {
      'name': 'Oatmeal with Fruits',
      'description': 'Healthy oats with banana and berries.',
      // ensure these assets exist or change to NetworkImage
    },
    {
      'name': 'Egg Sandwich',
      'description': 'Protein packed with eggs and veggies.',
      'image': 'assets/breakfast2.jpg',
    },
    {
      'name': 'Yogurt Parfait',
      'description': 'Layered yogurt, granola and fruits.',
      'image': 'assets/breakfast3.jpg',
    },
  ];

  final List<Map<String, String>> lunchSuggestions = [
    {
      'name': 'Grilled Chicken Salad',
      'description': 'Fresh greens with grilled chicken.',
      'image': 'assets/lunch1.jpg',
    },
    {
      'name': 'Veggie Wrap',
      'description': 'Whole wheat wrap loaded with veggies.',
      'image': 'assets/lunch2.jpg',
    },
    {
      'name': 'Quinoa Bowl',
      'description': 'Nourishing bowl with quinoa and beans.',
      'image': 'assets/lunch3.jpg',
    },
    {
      'name': 'Pasta Primavera',
      'description': 'Light pasta with seasonal vegetables.',
      'image': 'assets/lunch4.jpg',
    },
  ];

  // Selected option for each meal
  int? selectedBreakfastIndex;
  int? selectedLunchIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Suggestions'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Breakfast Suggestions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            buildMealSection(breakfastSuggestions, 'breakfast'),
            const SizedBox(height: 24),
            const Text(
              'Lunch Suggestions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            buildMealSection(lunchSuggestions, 'lunch'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  // For now, simply show selected choices.
                  String breakfast = selectedBreakfastIndex != null
                      ? breakfastSuggestions[selectedBreakfastIndex!]['name']!
                      : 'Not selected';
                  String lunch = selectedLunchIndex != null
                      ? lunchSuggestions[selectedLunchIndex!]['name']!
                      : 'Not selected';

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Selected Meals'),
                      content:
                      Text('Breakfast: $breakfast\nLunch: $lunch'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        )
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Confirm Selections',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a list of suggestions for a meal type.
  /// The parameter `mealType` distinguishes between breakfast and lunch.
  Widget buildMealSection(
      List<Map<String, String>> suggestions, String mealType) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        bool isSelected = false;
        if (mealType == 'breakfast') {
          isSelected = index == selectedBreakfastIndex;
        } else if (mealType == 'lunch') {
          isSelected = index == selectedLunchIndex;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            onTap: () {
              setState(() {
                if (mealType == 'breakfast') {
                  selectedBreakfastIndex = index;
                } else if (mealType == 'lunch') {
                  selectedLunchIndex = index;
                }
              });
            },
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                suggestion['image']!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(suggestion['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(suggestion['description']!),
            trailing: Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.teal : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
