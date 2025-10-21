import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/diet_method_model.dart';
import '../models/user_model.dart';

class ApiService {
  // haruServer API 기본 URL
  static String get baseUrl {
    // 개발 환경: 로컬 서버
    if (kDebugMode) {
      // Android 에뮬레이터
      return 'http://10.0.2.2:3001/api';
      // iOS 시뮬레이터는 'http://localhost:3001/api' 사용 가능
    }
    // 프로덕션 환경: 실제 서버 URL
    return 'https://your-production-server.com/api'; // TODO: 실제 서버 URL로 변경
  }
  
  // 다이어트 방법 목록 조회
  static Future<List<DietMethodModel>> getDietMethods() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/diet-methods'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DietMethodModel.fromJson(json)).toList();
      } else {
        debugPrint('Error fetching diet methods: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching diet methods: $e');
      return [];
    }
  }

  // 사용자 생성
  static Future<Map<String, dynamic>?> createUser({
    required String nickname,
    required int age,
    required String gender,
    required double height,
    required String heightUnit,
    required double currentWeight,
    required String currentWeightUnit,
    required double targetWeight,
    required String targetWeightUnit,
    required String dietMethodId,
    required DateTime dietStartDate,
    int? dailyCalorieGoal,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nickname': nickname,
          'age': age,
          'gender': gender,
          'height': height,
          'heightUnit': heightUnit,
          'currentWeight': currentWeight,
          'currentWeightUnit': currentWeightUnit,
          'targetWeight': targetWeight,
          'targetWeightUnit': targetWeightUnit,
          'dietMethodId': dietMethodId,
          'dietStartDate': dietStartDate.toIso8601String().split('T')[0],
          'dailyCalorieGoal': dailyCalorieGoal ?? 2000,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint('Error creating user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
      return null;
    }
  }

  // 체중 기록 생성
  static Future<Map<String, dynamic>?> createWeightRecord({
    required String userId,
    required double weight,
    required String weightUnit,
    required DateTime date,
    String? memo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/weights'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'weight': weight,
          'weightUnit': weightUnit,
          'date': date.toIso8601String().split('T')[0],
          'memo': memo,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint('Error creating weight record: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating weight record: $e');
      return null;
    }
  }

  // 체중 기록 수정
  static Future<Map<String, dynamic>?> updateWeightRecord(
    String recordId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/weights/$recordId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Error updating weight record: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error updating weight record: $e');
      return null;
    }
  }

  // 사용자 정보 조회
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Error fetching user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  // 사용자 목록 조회 (최근 사용자 확인용)
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Error fetching users: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  // 체중 기록 조회
  static Future<List<Map<String, dynamic>>> getWeightRecords(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weights?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Error fetching weight records: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching weight records: $e');
      return [];
    }
  }

  // Meals API (기존 API 서비스와 호환)
  static Future<List<dynamic>> getMeals(String userId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/meals?userId=$userId&date=$dateStr'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Error fetching meals: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching meals: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> addMeal(dynamic meal) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/meals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(meal.toJson()),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint('Error adding meal: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error adding meal: $e');
      return null;
    }
  }

  static Future<bool> deleteMeal(String mealId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/meals/$mealId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting meal: $e');
      return false;
    }
  }

  // Weights API (Provider용 - 기존 API 서비스와 호환)
  static Future<List<dynamic>> getWeights(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weights?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Error fetching weights: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching weights: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> addWeight(dynamic weight) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/weights'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(weight.toJson()),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint('Error adding weight: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error adding weight: $e');
      return null;
    }
  }

  // User update API
  static Future<Map<String, dynamic>?> updateUser(dynamic user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Error updating user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      return null;
    }
  }
}