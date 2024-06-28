import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

class SalesEntity extends Equatable {
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

  @override
  String toString() {
    return 'SalesEntity(id: $id, serie: $serie, correlativo: $correlativo, cod: $cod, fecha: $fecha, total: $total, cliente: $cliente, usuario: $usuario, boletaVenta: $boletaVenta, detallesVenta: $detallesVenta, notaCredito: $notaCredito)';
  }

  static List<SalesEntity> listGetSalesFromMap(
    List<dynamic> list,
  ) {
    return list.map((e) => getSalesFromMap(e as Map<String, dynamic>)).toList();
  }

  static SalesEntity getSalesFromMap(Map<String, dynamic> map) {
    log('abccccc: $map');
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

  @override
  List<Object?> get props => [
        id,
        serie,
        correlativo,
        cod,
        fecha,
        total,
        cliente,
        usuario,
        boletaVenta,
        detallesVenta,
        notaCredito,
      ];
}
