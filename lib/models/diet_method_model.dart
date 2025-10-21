class DietMethodModel {
  final String id;
  final String name;
  final String? shortDescription;
  final String? description;

  DietMethodModel({
    required this.id,
    required this.name,
    this.shortDescription,
    this.description,
  });

  factory DietMethodModel.fromJson(Map<String, dynamic> json) {
    return DietMethodModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortDescription: json['short_description'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_description': shortDescription,
      'description': description,
    };
  }
}
