import 'package:casa_empenio_pe/domain/auth/auth.dart';
import 'package:equatable/equatable.dart';

class SolicitudEntity extends Equatable {
  const SolicitudEntity({
    required this.id,
    required this.prestamoId,
    required this.estado,
    required this.usuario,
    required this.updatedAt,
    required this.createdAt,
  });

  final int id;
  final String prestamoId;
  final String estado;
  final UserEntity? usuario;
  final String? updatedAt;
  final String? createdAt;

  static List<SolicitudEntity> listGetSolicitudFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getSolicitudFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static SolicitudEntity getSolicitudFromMap(Map<String, dynamic> map) {
    return SolicitudEntity(
      id: map['id'],
      prestamoId: map['prestamoId'],
      estado: map['estado'],
      usuario: map['usuario'] != null
          ? UserEntity.userFromMap(map['usuario'])
          : null,
      updatedAt: map['updated_at'],
      createdAt: map['created_at'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        prestamoId,
        estado,
        usuario,
        updatedAt,
        createdAt,
      ];
}
