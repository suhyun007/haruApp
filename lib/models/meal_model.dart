class MealModel {
  final String id;
  final String userId;
  final String mealType;
  final String foodName;
  final int calories;
  final DateTime date;

  MealModel({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.date,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      mealType: json['mealType'] ?? '',
      foodName: json['foodName'] ?? '',
      calories: json['calories'] ?? 0,
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mealType': mealType,
      'foodName': foodName,
      'calories': calories,
      'date': date.toIso8601String(),
    };
  }
}

