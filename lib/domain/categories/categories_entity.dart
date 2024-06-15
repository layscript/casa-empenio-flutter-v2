import 'package:equatable/equatable.dart';

class CategoriesEntity extends Equatable {
  const CategoriesEntity({
    required this.id,
    required this.descripcion,
    required this.updatedAt,
    required this.createdAt,
  });

  final int id;
  final String descripcion;
  final String updatedAt;
  final String createdAt;

  static List<CategoriesEntity> listGetCategoriesFromMap(
    Map<String, dynamic> map,
  ) {
    final list = map['body'] as List<dynamic>;
    return list
        .map((e) => getCategoriesFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static CategoriesEntity getCategoriesFromMap(Map<String, dynamic> map) {
    return CategoriesEntity(
      id: map['id'],
      createdAt: map['createdAt'],
      descripcion: map['descripcion'],
      updatedAt: map['updatedAt'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        descripcion,
        updatedAt,
        createdAt,
      ];
}
