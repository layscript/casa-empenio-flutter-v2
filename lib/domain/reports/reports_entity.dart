import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

class ReportsPaymentEntity extends Equatable {
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
    this.medioPago,
    this.banco,
  });

  final String? medioPago;
  final String? banco;

  /// Texto listo para mostrar: Efectivo, Depósito · BCP, Yape...
  String get medioTexto {
    switch ((medioPago ?? (efectivo == false ? 'DEPOSITO' : 'EFECTIVO')).toUpperCase()) {
      case 'DEPOSITO':
        return (banco ?? '').trim().isEmpty ? '🏦 Depósito' : '🏦 Depósito · $banco';
      case 'YAPE':
        return '📱 Yape';
      case 'PLIN':
        return '📱 Plin';
      case 'OTRO':
        return '➕ Otro medio';
      default:
        return '💵 Efectivo';
    }
  }

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
      id: map['id'] as int,
      monto: map['monto'] as String?,
      fecha: map['fecha'] as String?,
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
      medioPago: map['medioPago'] as String?,
      banco: map['banco'] as String?,
      caja: map['caja'] != null
          ? CajaEntity.getCajaFromMap(
              map['caja'],
              false,
            )
          : null,
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

  @override
  List<Object?> get props => [
        id,
        monto,
        fecha,
        cliente,
        prestamo,
        usuario,
        updatedAt,
        createdAt,
        efectivo,
        caja,
        medioPago,
        banco,
      ];
}

class ReportsContractsEntity extends Equatable {
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

  @override
  List<Object?> get props => [
        id,
        fecha,
        monto,
        observaciones,
        prestamo,
      ];
}
