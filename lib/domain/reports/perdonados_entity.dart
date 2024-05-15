import 'dart:developer';

import 'package:casa_empenio_pe/domain/loans/loans_entity.dart';
import 'package:equatable/equatable.dart';

class PerdonadosEntity extends Equatable {
  const PerdonadosEntity({
    required this.id,
    required this.monto,
    required this.prestamo,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final int id;
  final String monto;
  final LoansEntity prestamo;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  static List<PerdonadosEntity> listGetForgivenessFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getForgivenessFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static PerdonadosEntity getForgivenessFromMap(Map<String, dynamic> map) {
    return PerdonadosEntity(
      id: map['id'] as int,
      monto: map['monto'] as String,
      prestamo: LoansEntity.getLoanFromMap(
        map['prestamo'],
      ),
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
      deletedAt: map['deletedAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        monto,
        prestamo,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
