import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _isOnboardingCompleteKey = 'is_onboarding_complete';
  static const String _supabaseUserIdKey = 'supabase_user_id';

  // 사용자 정보 저장
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userKey, userJson);
    await prefs.setBool(_isOnboardingCompleteKey, true);
  }

  // 사용자 정보 불러오기
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      final userMap = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  // 온보딩 완료 여부 확인
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isOnboardingCompleteKey) ?? false;
  }

  // 사용자 정보 삭제 (로그아웃 등에 사용)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_isOnboardingCompleteKey);
    await prefs.remove(_supabaseUserIdKey);
  }

  // Supabase User ID 저장
  static Future<void> saveSupabaseUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_supabaseUserIdKey, userId);
  }

  // Supabase User ID 불러오기
  static Future<String?> getSupabaseUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_supabaseUserIdKey);
  }
}

