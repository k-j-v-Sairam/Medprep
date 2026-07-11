import 'dart:convert';

class CustomExam {
  final String id;
  final String name;
  final DateTime date;

  const CustomExam({
    required this.id,
    required this.name,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
    };
  }

  factory CustomExam.fromMap(Map<String, dynamic> map) {
    return CustomExam(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CustomExam.fromJson(String source) => CustomExam.fromMap(json.decode(source));
}
