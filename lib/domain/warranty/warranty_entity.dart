import 'package:casa_empenio_pe/domain/domain.dart';

class WarrantyEntity {
  const WarrantyEntity({
    required this.id,
    required this.description,
    required this.estado,
    required this.color,
    required this.marca,
    required this.serie,
    required this.modelo,
    required this.prestamo,
    required this.activo,
    required this.anio,
    required this.cantidad,
    required this.carroceria,
    required this.createdAt,
    required this.detallesVenta,
    required this.imagen,
    required this.motor,
    required this.observaciones,
    required this.placa,
    required this.updatedAt,
    required this.valorizacion,
  });

  final int? id;
  final String? description;
  final String? estado;
  final String? marca;
  final String? modelo;
  final String? color;
  final String? serie;
  final String? placa;
  final String? carroceria;
  final String? motor;
  final int? anio;
  final int? valorizacion;
  final String? observaciones;
  final int? cantidad;
  final LoansEntity? prestamo;
  final SalesDetailEntity? detallesVenta;
  final String? imagen;
  final bool? activo;
  final String? updatedAt;
  final String? createdAt;

  static List<WarrantyEntity> listGetWarrantyFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getWarrantyFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static WarrantyEntity getWarrantyFromMap(Map<String, dynamic> map) {
    return WarrantyEntity(
      id: map['id'],
      description: map['descripcion'],
      estado: map['estado'],
      color: map['color'],
      marca: map['marca'],
      serie: map['serie'],
      modelo: map['modelo'],
      prestamo: map['prestamo'] != null
          ? LoansEntity.getLoanFromMap(map['prestamo'])
          : null,
      activo: map['activo'],
      anio: map['anio'],
      cantidad: map['cantidad'],
      carroceria: map['carroceria'],
      createdAt: map['createdAt'],
      detallesVenta: map['detallesVenta'] != null
          ? SalesDetailEntity.getSalesDetailFromMap(map['detallesVenta'])
          : null,
      imagen: map['imagen'],
      motor: map['motor'],
      observaciones: map['observaciones'],
      placa: map['placa'],
      updatedAt: map['updatedAt'],
      valorizacion: map['valorizacion'],
    );
  }
}
