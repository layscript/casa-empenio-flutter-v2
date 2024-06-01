import 'package:equatable/equatable.dart';

class SucursalEntity extends Equatable {
  final int id;
  final String nombre;
  final String direccion;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? telefono;
  final String? extras;

  const SucursalEntity({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.telefono,
    required this.extras,
  });

  static List<SucursalEntity> listGetSucursalesFromMap(
    Map<String, dynamic> map,
  ) {
    //final list = map['body'][0] as List<dynamic>;
    final list = map['body'] as List<dynamic>;
    return list.map((e) => sucursalFromMap(e as Map<String, dynamic>)).toList();
  }

  static SucursalEntity sucursalFromMap(Map<String, dynamic> map) {
    return SucursalEntity(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      direccion: map['direccion'] as String,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
      deletedAt: map['deletedAt'] as String?,
      extras: map['extas'] as String?,
      telefono: map['telefono'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        direccion,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
