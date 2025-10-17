class WeightModel {
  final String id;
  final String userId;
  final double weight;
  final DateTime date;

  WeightModel({
    required this.id,
    required this.userId,
    required this.weight,
    required this.date,
  });

  factory WeightModel.fromJson(Map<String, dynamic> json) {
    return WeightModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }
}

