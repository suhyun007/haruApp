import 'package:flutter/material.dart';
import '../models/weight_model.dart';
import '../services/api_service.dart';

class WeightProvider with ChangeNotifier {
  List<WeightModel> _weights = [];
  bool _isLoading = false;

  List<WeightModel> get weights => _weights;
  bool get isLoading => _isLoading;

  Future<void> loadWeights(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final weightsData = await ApiService.getWeights(userId);
      _weights = weightsData.map((json) => WeightModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading weights: $e');
      _weights = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWeight(WeightModel weight) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.addWeight(weight);
      _weights.add(weight);
      _weights.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('Error adding weight: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}

