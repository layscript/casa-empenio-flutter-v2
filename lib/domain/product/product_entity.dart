import 'dart:developer';

import 'package:casa_empenio_pe/domain/loans/loans_entity.dart';
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.descripcion,
    required this.categoria,
    required this.estado,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.serie,
    required this.placa,
    required this.carroceria,
    required this.motor,
    required this.anio,
    required this.valorizacion,
    required this.observaciones,
    required this.cantidad,
    required this.imagen,
    required this.activo,
    required this.updatedAt,
    required this.createdAt,
    required this.prestamo,
    required this.imagenDos,
    required this.imagenTres,
  });

  final int? id;
  final String? descripcion;
  final String? categoria;
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
  final String? imagen;
  final String? imagenDos;
  final String? imagenTres;
  final bool? activo;
  final String? updatedAt;
  final String? createdAt;
  final LoansEntity? prestamo;

  static List<ProductEntity> listGetProductsFromMap(
    Map<String, dynamic> map,
  ) {
    final list = map['body'] as List<dynamic>;
    return list
        .map((e) => getProductFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static ProductEntity getProductFromMap(Map<String, dynamic> map) {
    return ProductEntity(
      id: map['id'] as int?,
      categoria: map['categoria'] as String?,
      descripcion: map['descripcion'] as String?,
      estado: map['estado'] as String?,
      marca: map['marca'] as String?,
      modelo: map['modelo'] as String?,
      color: map['color'] as String?,
      serie: map['serie'] as String?,
      placa: map['placa'] as String?,
      carroceria: map['carroceria'] as String?,
      motor: map['motor'] as String?,
      anio: map['anio'] as int?,
      valorizacion: map['valorizacion'] as int?,
      observaciones: map['observaciones'] as String?,
      cantidad: map['cantidad'] as int?,
      imagen: map['imagen'] as String?,
      imagenDos: map['imagen2'] as String?,
      imagenTres: map['imagen3'] as String?,
      activo: map['activo'] as bool?,
      updatedAt: map['updatedAt'] as String?,
      createdAt: map['createdAt'] as String?,
      prestamo: map['prestamo'] == null
          ? null
          : LoansEntity.getLoanFromMap(map['prestamo']),
    );
  }

  bool get isProductPersonalizado => id.toString().startsWith('2000');

  @override
  List<Object?> get props => [
        id,
        descripcion,
        categoria,
        estado,
        marca,
        modelo,
        color,
        serie,
        placa,
        carroceria,
        motor,
        anio,
        valorizacion,
        observaciones,
        cantidad,
        imagen,
        activo,
        updatedAt,
        createdAt,
        prestamo,
        imagenDos,
        imagenTres,
      ];
}
