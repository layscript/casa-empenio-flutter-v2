import 'dart:developer';

import 'package:equatable/equatable.dart';

class HistorialEntity extends Equatable {
  const HistorialEntity({
    required this.id,
    required this.accion,
    required this.detalle,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String accion;
  final String detalle;
  final String createdAt;
  final String updatedAt;

  static List<HistorialEntity> listGetHistorialFromMap(
    Map<String, dynamic> map,
  ) {
    final list = map['body']?[0] as List<dynamic>;

    return list
        .map((e) => getHistorialFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static HistorialEntity getHistorialFromMap(Map<String, dynamic> map) {
    return HistorialEntity(
      id: map['id'],
      accion: map['accion'],
      detalle: map['detalle'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        accion,
        detalle,
        createdAt,
        updatedAt,
      ];
}
