import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../models/meal_model.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _selectedMealType = '아침';

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _showAddMealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('식사 추가'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                items: ['아침', '점심', '저녁', '간식']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMealType = value!;
                  });
                },
                decoration: const InputDecoration(labelText: '식사 타입'),
              ),
              TextFormField(
                controller: _foodNameController,
                decoration: const InputDecoration(labelText: '음식 이름'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '음식 이름을 입력하세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: '칼로리 (kcal)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '칼로리를 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '올바른 숫자를 입력하세요';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: _submitMeal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DDC97),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _submitMeal() {
    if (_formKey.currentState!.validate()) {
      final meal = MealModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'user1',
        mealType: _selectedMealType,
        foodName: _foodNameController.text,
        calories: int.parse(_caloriesController.text),
        date: DateTime.now(),
      );

      Provider.of<MealProvider>(context, listen: false).addMeal(meal);
      
      _foodNameController.clear();
      _caloriesController.clear();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MealProvider>(
        builder: (context, mealProvider, child) {
          final meals = mealProvider.meals;
          final mealsByType = <String, List<MealModel>>{};
          
          for (var meal in meals) {
            if (!mealsByType.containsKey(meal.mealType)) {
              mealsByType[meal.mealType] = [];
            }
            mealsByType[meal.mealType]!.add(meal);
          }

          return meals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '(작업진행중)\n기록된 식사가 없습니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Color(0xFF555555)),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildMealTypeSection('아침', mealsByType['아침'] ?? [], mealProvider),
                    _buildMealTypeSection('점심', mealsByType['점심'] ?? [], mealProvider),
                    _buildMealTypeSection('저녁', mealsByType['저녁'] ?? [], mealProvider),
                    _buildMealTypeSection('간식', mealsByType['간식'] ?? [], mealProvider),
                  ],
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealDialog,
        backgroundColor: const Color(0xFF3DDC97),
        mini: true,
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildMealTypeSection(String type, List<MealModel> meals, MealProvider provider) {
    if (meals.isEmpty) return const SizedBox.shrink();

    final totalCalories = meals.fold(0, (sum, meal) => sum + meal.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '$totalCalories kcal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7FBEC),
                ),
              ),
            ],
          ),
        ),
        ...meals.map((meal) => Card(
              child: ListTile(
                title: Text(meal.foodName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${meal.calories} kcal',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => provider.deleteMeal(meal.id),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

