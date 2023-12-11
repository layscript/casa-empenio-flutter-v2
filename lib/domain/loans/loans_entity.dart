import 'dart:developer';

import 'package:casa_empenio_pe/domain/domain.dart';

class LoansEntity {
  const LoansEntity({
    required this.codigo,
    required this.codigoFormateado,
    required this.plazoDias,
    required this.interes,
    required this.fechaPago,
    required this.fechaCierre,
    required this.monto,
    required this.observaciones,
    required this.estado,
    required this.cerrado,
    required this.ganancia,
    required this.fecha,
    required this.updatedAt,
    required this.createdAt,
    required this.boleta,
    required this.notaCredito,
    required this.cliente,
    required this.admin,
    required this.aumentos,
    required this.aval,
    required this.imagenLiquidado,
    required this.pagos,
    required this.usuario,
    required this.eliminado,
    required this.bienesGarantia,
  });

  final int? codigo;
  final String? codigoFormateado;
  final int? plazoDias;
  final int? interes;
  final String? fechaPago;
  final String? fechaCierre;
  final String? monto;
  final String? observaciones;
  final String? estado;
  final bool? cerrado;
  final String? ganancia;
  final CustomerEntity? cliente;
  final CustomerEntity? aval;
  final List<PayEntity>? pagos;
  final UserEntity? usuario;
  final UserEntity? admin;
  final String? fecha;
  final bool? eliminado;
  final String? imagenLiquidado;
  final String? updatedAt;
  final String? createdAt;
  final List<IncreaseEntity>? aumentos;
  final TicketEntity? boleta;
  final List<CreditNoteEntity>? notaCredito;
  final List<WarrantyEntity>? bienesGarantia;

  @override
  String toString() {
    return '''
codigo: $codigo,
codigoFormateado: $codigoFormateado,
plazoDias: $plazoDias,
interes: $interes,
fechaPago: $fechaPago,
fechaCierre: $fechaCierre,
monto: $monto,
observaciones: $observaciones,
estado: $estado,
cerrado: $cerrado,
ganancia: $ganancia,
cliente: ${cliente.toString()},
aval: $aval, 
pagos: $pagos,
usuario: $usuario,
admin: $admin,
fecha: $fecha,
updatedAt: $updatedAt,
createdAt: $createdAt,
aumentos: $aumentos,
imagenLiquidado: $imagenLiquidado,
boleta: $boleta,
notaCredito: $notaCredito,
bienesGarantia: $bienesGarantia,
eliminado: $eliminado,
''';
  }

  static List<LoansEntity> listGetSalesDetailFromMap(
    List<dynamic> list,
  ) {
    return list.map((e) => getLoanFromMap(e as Map<String, dynamic>)).toList();
  }

  static LoansEntity getLoanFromMap(Map<String, dynamic> map) {
    log('askdjklsadads 2: $map');
    return LoansEntity(
      codigo: map['codigo'] as int?,
      codigoFormateado: map['codigoFormateado'] as String?,
      plazoDias: map['plazoDias'] as int?,
      interes: map['interes'] as int?,
      fechaPago: map['fechaPago'] as String?,
      fechaCierre: map['fechaCierre'] as String?,
      monto: map['monto'] as String?,
      observaciones: map['observaciones'] as String?,
      estado: map['estado'] as String?,
      cerrado: map['cerrado'] as bool?,
      ganancia: map['ganancia'] as String?,
      eliminado: map['eliminado'] as bool?,
      fecha: map['fecha'] as String?,
      updatedAt: map['updatedAt'] as String?,
      createdAt: map['createdAt'] as String?,
      imagenLiquidado: map['imagenLiquidado'] as String?,
      admin: map['admin'] != null ? UserEntity.userFromMap(map['admin']) : null,
      aumentos: map['aumentos'] != null
          ? IncreaseEntity.listIncreaseFromMap(map['aumentos'])
          : null,
      aval: map['aval'] != null
          ? CustomerEntity.getCustomerFromMap(map['aval'])
          : null,
      boleta: map['boleta'] != null
          ? TicketEntity.getTicketFromMap(map['boleta'])
          : null,
      cliente: map['cliente'] != null
          ? CustomerEntity.getCustomerFromMap(map['cliente'])
          : null,
      notaCredito: map['notaCredito'] != null
          ? CreditNoteEntity.listCreditNoteFromMap(
              map['notaCredito'] as List<dynamic>)
          : null,
      pagos: map['pagos'] != null
          ? PayEntity.listGetPayFromMap(map['pagos'] as List<dynamic>)
          : null,
      usuario: map['usuario'] != null
          ? UserEntity.userFromMap(map['usuario'])
          : null,
      bienesGarantia: map['bienesGarantia'] != null
          ? WarrantyEntity.listGetWarrantyFromMap(
              map['bienesGarantia'] as List<dynamic>,
            )
          : null,
    );
  }
}

// Boleta venta
class TicketSalesEntity {
  const TicketSalesEntity({
    required this.id,
    required this.serie,
    required this.correlativo,
    required this.fecha,
    required this.zip,
    required this.xml,
    required this.pdf,
    required this.venta,
  });

  final int? id;
  final String? serie;
  final int? correlativo;
  final String? fecha;
  final String? zip;
  final String? xml;
  final String? pdf;
  final SalesEntity? venta;

  static TicketSalesEntity getTicketSalesFromMap(Map<String, dynamic> map) {
    return TicketSalesEntity(
      id: map['id'],
      serie: map['serie'],
      correlativo: map['correlativo'],
      fecha: map['fecha'],
      zip: map['zip'],
      xml: map['xml'],
      pdf: map['pdf'],
      venta: map['venta'] != null
          ? SalesEntity.getSalesFromMap(map['venta'])
          : null,
    );
  }
}

// Boleta
class TicketEntity {
  const TicketEntity({
    required this.id,
    required this.serie,
    required this.fecha,
    required this.zip,
    required this.xml,
    required this.pdf,
    required this.correlativo,
    required this.prestamo,
  });

  final int? id;
  final String? serie;
  final int? correlativo;
  final String? fecha;
  final String? zip;
  final String? xml;
  final String? pdf;
  final LoansEntity? prestamo;

  static TicketEntity getTicketFromMap(Map<String, dynamic> map) {
    return TicketEntity(
      id: map['id'],
      serie: map['serie'],
      fecha: map['fecha'],
      zip: map['zip'],
      xml: map['xml'],
      pdf: map['pdf'],
      correlativo: map['correlativo'],
      prestamo: map['prestamo'] != null
          ? LoansEntity.getLoanFromMap(map['prestamo'])
          : null,
    );
  }
}

// Nota Credito
class CreditNoteEntity {
  final int? id;
  final String? serie;
  final int? correlativo;
  final String? fecha;
  final String? zip;
  final String? xml;
  final String? pdf;
  final SalesEntity? venta;
  final LoansEntity? prestamo;

  const CreditNoteEntity({
    required this.id,
    required this.serie,
    required this.correlativo,
    required this.fecha,
    required this.zip,
    required this.xml,
    required this.pdf,
    required this.venta,
    required this.prestamo,
  });

  static List<CreditNoteEntity> listCreditNoteFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getCreditNoteFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static CreditNoteEntity getCreditNoteFromMap(Map<String, dynamic> map) {
    return CreditNoteEntity(
      id: map['id'],
      serie: map['serie'],
      correlativo: map['correlativo'],
      fecha: map['fecha'],
      zip: map['zip'],
      xml: map['xml'],
      pdf: map['pdf'],
      venta: map['venta'] != null
          ? SalesEntity.getSalesFromMap(map['venta'])
          : null,
      prestamo: map['prestamo'] != null
          ? LoansEntity.getLoanFromMap(map['prestamo'])
          : null,
    );
  }
}
