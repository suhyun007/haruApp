import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../services/api_service.dart';

class MealProvider with ChangeNotifier {
  List<MealModel> _meals = [];
  bool _isLoading = false;

  List<MealModel> get meals => _meals;
  bool get isLoading => _isLoading;

  int get totalCalories {
    return _meals.fold(0, (sum, meal) => sum + meal.calories);
  }

  Future<void> loadMeals(String userId, DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      _meals = await ApiService.getMeals(userId, date);
    } catch (e) {
      debugPrint('Error loading meals: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMeal(MealModel meal) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.addMeal(meal);
      _meals.add(meal);
    } catch (e) {
      debugPrint('Error adding meal: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteMeal(String mealId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.deleteMeal(mealId);
      _meals.removeWhere((meal) => meal.id == mealId);
    } catch (e) {
      debugPrint('Error deleting meal: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}

