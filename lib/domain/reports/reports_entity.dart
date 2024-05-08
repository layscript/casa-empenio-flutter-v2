import 'package:casa_empenio_pe/domain/domain.dart';

class ReportsPaymentEntity {
  const ReportsPaymentEntity({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.cliente,
    required this.prestamo,
    required this.usuario,
    required this.updatedAt,
    required this.createdAt,
    required this.efectivo,
    required this.caja,
  });

  final int? id;
  final String? monto;
  final String? fecha;
  final CustomerEntity? cliente;
  final LoansEntity? prestamo;
  final UserEntity? usuario;
  final String? updatedAt;
  final String? createdAt;
  final bool? efectivo;
  final CajaEntity? caja;

  static List<ReportsPaymentEntity> listGetReportsPaymentFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getReportsPaymentFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static ReportsPaymentEntity getReportsPaymentFromMap(
      Map<String, dynamic> map) {
    return ReportsPaymentEntity(
      id: map['id'],
      monto: map['monto'],
      fecha: map['fecha'],
      cliente: map['cliente'] != null
          ? CustomerEntity.getCustomerFromMap(map['cliente'])
          : null,
      prestamo: map['prestamo'] != null
          ? LoansEntity.getLoanFromMap(map['prestamo'])
          : null,
      usuario: map['usuario'] != null
          ? UserEntity.userFromMap(map['usuario'])
          : null,
      updatedAt: map['updatedAt'],
      createdAt: map['createdAt'],
      efectivo: map['efectivo'],
      caja: CajaEntity.getCajaFromMap(
        map['caja'],
        false,
      ),
    );
  }

  static List<ReportsPaymentEntity> filterDistinctByPrestamoCodigo(
      List<ReportsPaymentEntity> list) {
    Set<String?> uniqueCodigos = {};
    List<ReportsPaymentEntity> result = [];

    for (var report in list) {
      if (uniqueCodigos.add(report.prestamo?.codigo.toString())) {
        result.add(report);
      }
    }

    return result;
  }

  @override
  String toString() {
    return 'ReportsPaymentEntity( prestamo: ${prestamo?.codigoFormateado}  estado: ${prestamo?.estado})';
  }
}

class ReportsContractsEntity {
  const ReportsContractsEntity({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.observaciones,
    required this.prestamo,
  });

  final int? id;
  final String? fecha;
  final String? monto;
  final String? observaciones;
  final LoansEntity? prestamo;

  static List<ReportsContractsEntity> listGetReportsContractsFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getReportsContractsFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static ReportsContractsEntity getReportsContractsFromMap(
      Map<String, dynamic> map) {
    return ReportsContractsEntity(
      id: map['id'],
      fecha: map['fecha'],
      monto: map['monto'],
      observaciones: map['observaciones'],
      prestamo: map['prestamo'] != null
          ? LoansEntity.getLoanFromMap(
              map['prestamo'],
            )
          : null,
    );
  }

  @override
  String toString() {
    return 'ReportsContractsEntity( prestamo: ${prestamo?.codigoFormateado}  estado: ${prestamo?.estado})';
  }
}
