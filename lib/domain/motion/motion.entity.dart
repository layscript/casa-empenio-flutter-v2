import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

class MotionEntity extends Equatable {
  const MotionEntity({
    required this.id,
    required this.observaciones,
    required this.monto,
    required this.ventaId,
    required this.pagoId,
    required this.prestamoId,
    required this.compraId,
    required this.createdBy,
    required this.updatedAt,
    required this.createdAt,
    required this.suma,
    required this.eliminado,
    required this.tipo,
  });

  final int? id;
  final String? observaciones;
  final String? monto;
  final int? ventaId;
  final int? pagoId;
  final int? prestamoId;
  final int? compraId;
  final String? createdBy;
  final String? updatedAt;
  final String? createdAt;
  final bool? suma;
  final bool? eliminado;
  final TypeEntity? tipo;

  static List<MotionEntity> listGetMotionFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getMotionFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static MotionEntity getMotionFromMap(Map<String, dynamic> map) {
    return MotionEntity(
      id: map['id'],
      observaciones: map['observaciones'],
      monto: map['monto'],
      ventaId: map['ventaId'],
      pagoId: map['pagoId'],
      prestamoId: map['prestamoId'],
      compraId: map['compraId'],
      createdBy: map['createdBy'],
      updatedAt: map['updatedAt'],
      createdAt: map['createdAt'],
      suma: map['suma'],
      eliminado: map['eliminado'],
      tipo: map['tipo'] != null
          ? TypeEntity.getTypeEntityFromMap(map['tipo'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        observaciones,
        monto,
        ventaId,
        pagoId,
        prestamoId,
        compraId,
        createdBy,
        updatedAt,
        createdAt,
        suma,
        eliminado,
        tipo,
      ];
}
