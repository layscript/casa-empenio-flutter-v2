import 'package:equatable/equatable.dart';

class PlantillaEntity extends Equatable {
  const PlantillaEntity({
    required this.id,
    required this.html,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String html;
  final String createdAt;
  final String updatedAt;

  static List<PlantillaEntity> fromJsonList(List<dynamic> json) {
    return json.map((e) => PlantillaEntity.fromJson(e)).toList();
  }

  factory PlantillaEntity.fromJson(Map<String, dynamic> json) {
    return PlantillaEntity(
      id: json['id'] as int,
      html: json['html'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  @override
  List<Object?> get props => [id, html, createdAt, updatedAt];
}
