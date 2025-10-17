import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/meal_model.dart';
import '../models/weight_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<UserModel> getUser(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  static Future<void> updateUser(UserModel user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/${user.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
  }

  static Future<List<MealModel>> getMeals(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$baseUrl/meals?userId=$userId&date=$dateStr'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => MealModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load meals');
    }
  }

  static Future<void> addMeal(MealModel meal) async {
    final response = await http.post(
      Uri.parse('$baseUrl/meals'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(meal.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add meal');
    }
  }

  static Future<void> deleteMeal(String mealId) async {
    final response = await http.delete(Uri.parse('$baseUrl/meals/$mealId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete meal');
    }
  }

  static Future<List<WeightModel>> getWeights(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weights?userId=$userId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => WeightModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load weights');
    }
  }

  static Future<void> addWeight(WeightModel weight) async {
    final response = await http.post(
      Uri.parse('$baseUrl/weights'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(weight.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add weight');
    }
  }
}

