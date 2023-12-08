import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';

class CustomerEntity {
  const CustomerEntity({
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.domicilio,
    required this.email,
    required this.celular,
    required this.prestamos,
    required this.prestamosAval,
    required this.pagos,
    required this.imagenUno,
    required this.imagenDos,
    required this.ventas,
    required this.updatedAt,
    required this.createdAt,
  });

  final String? dni;
  final String? nombres;
  final String? apellidos;
  final String? domicilio;
  final String? email;
  final String? celular;
  final List<LoansEntity>? prestamos;
  final List<LoansEntity>? prestamosAval;
  final List<PayEntity>? pagos;
  final List<SalesEntity>? ventas;
  final String? imagenUno;
  final String? imagenDos;
  final String? updatedAt;
  final String? createdAt;

  static List<CustomerEntity> listGetCustomerFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getCustomerFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static CustomerEntity getCustomerFromMap(Map<String, dynamic> map) {
    return CustomerEntity(
      dni: map['dni'],
      nombres: map['nombres'],
      apellidos: map['apellidos'],
      domicilio: map['domicilio'],
      email: map['email'],
      celular: map['celular'],
      imagenUno: map['imagen'],
      imagenDos: map['imagen2'],
      prestamos: map['prestamos'] != null
          ? LoansEntity.listGetSalesDetailFromMap(
              map['prestamos'] as List<dynamic>)
          : null,
      prestamosAval: map['prestamosAval'] != null
          ? LoansEntity.listGetSalesDetailFromMap(
              map['prestamosAval'] as List<dynamic>)
          : null,
      pagos: map['pagos'] != null
          ? PayEntity.listGetPayFromMap(
              map['pagos'] as List<dynamic>,
            )
          : null,
      ventas: map['ventas'] != null
          ? SalesEntity.listGetSalesFromMap(map['ventas'] as List<dynamic>)
          : null,
      updatedAt: map['updatedAt'],
      createdAt: map['createdAt'],
    );
  }
}
