class UserModel {
  final String id;
  final String name;
  final double targetWeight;
  final double currentWeight;
  final int dailyCalorieGoal;

  UserModel({
    required this.id,
    required this.name,
    required this.targetWeight,
    required this.currentWeight,
    required this.dailyCalorieGoal,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      targetWeight: (json['targetWeight'] ?? 0).toDouble(),
      currentWeight: (json['currentWeight'] ?? 0).toDouble(),
      dailyCalorieGoal: json['dailyCalorieGoal'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetWeight': targetWeight,
      'currentWeight': currentWeight,
      'dailyCalorieGoal': dailyCalorieGoal,
    };
  }
}

