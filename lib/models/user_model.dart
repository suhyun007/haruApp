class UserModel {
  final String id;
  final String name;
  final int age;
  final double height;
  final double targetWeight;
  final double currentWeight;
  final int dailyCalorieGoal;
  final String gender;
  final String? dietMethodName;
  final String? dietMethodDescription;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.targetWeight,
    required this.currentWeight,
    required this.dailyCalorieGoal,
    required this.gender,
    this.dietMethodName,
    this.dietMethodDescription,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['nickname'] ?? json['name'] ?? '',
      age: json['age'] ?? 0,
      height: (json['height'] ?? 0).toDouble(),
      targetWeight: (json['targetWeight'] ?? 0).toDouble(),
      currentWeight: (json['currentWeight'] ?? 0).toDouble(),
      dailyCalorieGoal: json['dailyCalorieGoal'] ?? 0,
      gender: json['gender'] == 'female' ? '여성' : (json['gender'] == 'male' ? '남성' : json['gender']),
      dietMethodName: json['dietMethod']?['name'] ?? json['dietMethodName'],
      dietMethodDescription: json['dietMethod']?['description'] ?? json['dietMethodDescription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': name,
      'age': age,
      'height': height,
      'targetWeight': targetWeight,
      'currentWeight': currentWeight,
      'dailyCalorieGoal': dailyCalorieGoal,
      'gender': gender == '여성' ? 'female' : 'male',
      'dietMethodName': dietMethodName,
      'dietMethodDescription': dietMethodDescription,
    };
  }
}

