// CLASE DETALLE VENTA

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

class SalesDetailEntity extends Equatable {
  const SalesDetailEntity({
    required this.id,
    required this.cantidad,
    required this.precio,
    required this.venta,
    required this.bienGarantia,
  });

  final int? id;
  final int? cantidad;
  final int? precio;
  final WarrantyEntity? bienGarantia;
  final SalesEntity? venta;

  static List<SalesDetailEntity> listGetSalesDetailFromMap(
    Map<String, dynamic> map,
  ) {
    final list = map as List<dynamic>;
    return list
        .map((e) => getSalesDetailFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static SalesDetailEntity getSalesDetailFromMap(Map<String, dynamic> map) {
    return SalesDetailEntity(
      id: map['id'],
      cantidad: map['cantidad'],
      precio: map['precio'],
      venta: map['venta'],
      bienGarantia: WarrantyEntity.getWarrantyFromMap(map['bienGarantia']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        cantidad,
        precio,
        venta,
        bienGarantia,
      ];
}
