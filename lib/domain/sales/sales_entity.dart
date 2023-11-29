import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';

class SalesEntity {
  const SalesEntity({
    required this.id,
    required this.serie,
    required this.correlativo,
    required this.cod,
    required this.fecha,
    required this.total,
    required this.cliente,
    required this.usuario,
    required this.boletaVenta,
    required this.detallesVenta,
    required this.notaCredito,
  });

  final int id;
  final String? serie;
  final int? correlativo;
  final String? cod;
  final String? fecha;
  final String? total;
  final CustomerEntity? cliente;
  final UserEntity? usuario;
  final List<SalesDetailEntity>? detallesVenta;
  final TicketSalesEntity? boletaVenta;
  final List<CreditNoteEntity>? notaCredito;

  static List<SalesEntity> listGetSalesFromMap(
    List<dynamic> list,
  ) {
    return list.map((e) => getSalesFromMap(e as Map<String, dynamic>)).toList();
  }

  static SalesEntity getSalesFromMap(Map<String, dynamic> map) {
    return SalesEntity(
      id: map['id'],
      serie: map['serie'],
      correlativo: map['correlativo'],
      cod: map['cod'],
      fecha: map['fecha'],
      total: map['total'],
      cliente: map['cliente'] != null
          ? CustomerEntity.getCustomerFromMap(map['cliente'])
          : null,
      boletaVenta: map['boletaVenta'] != null
          ? TicketSalesEntity.getTicketSalesFromMap(map['boletaVenta'])
          : null,
      detallesVenta: map['detallesVenta'] != null
          ? SalesDetailEntity.listGetSalesDetailFromMap(
              map['detallesVenta'],
            )
          : null,
      notaCredito: map['notaCredito'] != null
          ? CreditNoteEntity.listCreditNoteFromMap(map['notaCredito'])
          : null,
      usuario: map['usuario'] != null
          ? UserEntity.userFromMap(map['usuario'])
          : null,
    );
  }
}
