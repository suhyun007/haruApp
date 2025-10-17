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
      _user = await ApiService.getUser(userId);
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
}

