import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> loadUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await ApiService.getUser(userId);
      if (userData != null) {
        _user = UserModel.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.updateUser(user);
      _user = user;
    } catch (e) {
      debugPrint('Error updating user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void createUser({
    required String id,
    required String name,
    required int age,
    required double height,
    required double currentWeight,
    required double targetWeight,
    required int dailyCalorieGoal,
    required String gender,
    String? dietMethodName,
    String? dietMethodDescription,
  }) {
    _user = UserModel(
      id: id,
      name: name,
      age: age,
      height: height,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      dailyCalorieGoal: dailyCalorieGoal,
      gender: gender,
      dietMethodName: dietMethodName,
      dietMethodDescription: dietMethodDescription,
    );
    notifyListeners();
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }
}

