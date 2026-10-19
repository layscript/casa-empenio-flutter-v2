import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

class CajaEntity extends Equatable {
  const CajaEntity({
    required this.id,
    required this.fecha,
    required this.horaApertura,
    required this.usuarioApertura,
    required this.montoApertura,
    required this.horaCierre,
    required this.usuarioCierre,
    required this.montoCierreReal,
    required this.montoCierreTeorico,
    required this.montoDiferencia,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.estado,
    required this.observaciones,
    required this.eliminado,
    required this.updatedAt,
    required this.createdAt,
    required this.movimientos,
  });

  final int? id;
  final String? fecha;
  final String? horaApertura;
  final UserEntity? usuarioApertura;
  final String? montoApertura;
  final String? horaCierre;
  final UserEntity? usuarioCierre;
  final String? montoCierreReal;
  final String? montoCierreTeorico;
  final String? montoDiferencia;
  final String? totalIngresos;
  final String? totalEgresos;
  final String? estado;
  final String? observaciones;
  final bool? eliminado;
  final String? updatedAt;
  final String? createdAt;
  final List<MovimientosEntity>? movimientos;

  CajaEntity copyWith({
    int? id,
    String? fecha,
    String? horaApertura,
    UserEntity? usuarioApertura,
    String? montoApertura,
    String? horaCierre,
    UserEntity? usuarioCierre,
    String? montoCierreReal,
    String? montoCierreTeorico,
    String? montoDiferencia,
    String? totalIngresos,
    String? totalEgresos,
    String? estado,
    String? observaciones,
    bool? eliminado,
    String? updatedAt,
    String? createdAt,
    List<MovimientosEntity>? movimientos,
  }) {
    return CajaEntity(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      horaApertura: horaApertura ?? this.horaApertura,
      usuarioApertura: usuarioApertura ?? this.usuarioApertura,
      montoApertura: montoApertura ?? this.montoApertura,
      horaCierre: horaCierre ?? this.horaCierre,
      usuarioCierre: usuarioCierre ?? this.usuarioCierre,
      montoCierreReal: montoCierreReal ?? this.montoCierreReal,
      montoCierreTeorico: montoCierreTeorico ?? this.montoCierreTeorico,
      montoDiferencia: montoDiferencia ?? this.montoDiferencia,
      totalIngresos: totalIngresos ?? this.totalIngresos,
      totalEgresos: totalEgresos ?? this.totalEgresos,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      eliminado: eliminado ?? this.eliminado,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      movimientos: movimientos ?? this.movimientos,
    );
  }

  static List<CajaEntity> listGetCajaFromMap(
    List<dynamic> list,
    bool newMovimientos,
  ) {
    return list
        .map((e) => getCajaFromMap(
              e,
              newMovimientos,
            ))
        .toList();
  }

  static CajaEntity getCajaFromMap(
    dynamic map,
    bool newMovimientos,
  ) {
    return CajaEntity(
      id: map?['id'],
      fecha: map?['fecha'],
      horaApertura: map?['horaApertura'],
      usuarioApertura: map['usuarioApertura'] != null
          ? map['usuarioApertura'] is int
              ? null
              : UserEntity.userFromMap(map?['usuarioApertura'])
          : null,
      montoApertura: map?['montoApertura'],
      horaCierre: map?['horaCierre'],
      usuarioCierre: map['usuarioCierre'] != null
          ? map['usuarioCierre'] is int
              ? null
              : UserEntity.userFromMap(map?['usuarioCierre'])
          : null,
      montoCierreReal: map?['montoCierreReal'],
      montoCierreTeorico: map?['montoCierreTeorico'],
      montoDiferencia: map?['montoDiferencia'],
      totalEgresos: map?['totalEgresos'],
      totalIngresos: map?['totalIngresos'],
      estado: map?['estado'],
      observaciones: map?['observaciones'],
      eliminado: map?['eliminado'],
      updatedAt: map?['updatedAt'],
      createdAt: map?['createdAt'],
      movimientos: map?['movimientos'] != null
          ? MovimientosEntity.listMovimientosFromMap(map?['movimientos'])
              .where((element) => element.tipo?.descripcion != 'Venta')
              .toList()
          : null,

      /* movimientos: map?['movimientos'] != null
          ? newMovimientos
              ? MovimientosEntity.listMovimientosFromMap(map?['movimientos'])
                  .where((element) => element.tipo?.descripcion != 'Venta')
                  .toList()
              : MovimientosEntity.listMovimientosFromMap(map?['movimientos'])
                  .toList()
          : null, */
    );
  }

  @override
  List<Object?> get props => [
        id,
        fecha,
        horaApertura,
        usuarioApertura,
        montoApertura,
        horaCierre,
        usuarioCierre,
        montoCierreReal,
        montoCierreTeorico,
        montoDiferencia,
        totalIngresos,
        totalEgresos,
        estado,
        observaciones,
        eliminado,
        updatedAt,
        createdAt,
        movimientos,
      ];
}

class MovimientosEntity extends Equatable {
  const MovimientosEntity({
    required this.id,
    required this.observaciones,
    required this.monto,
    required this.ventaId,
    required this.pagoId,
    required this.prestamoId,
    required this.createdBy,
    required this.suma,
    required this.eliminado,
    required this.createdAt,
    required this.updatedAt,
    required this.tipo,
    this.medioPago,
    this.banco,
    this.usuarioId,
    this.usuarioNombre,
    this.clienteNombre,
    this.clienteDni,
    this.prestamoCodigo,
    this.interesMonto,
    this.capitalMonto,
    this.motivoAnulacion,
  });

  /// Cuánto de lo cobrado fue interés y cuánto capital (pagos y renovaciones)
  final double? interesMonto;
  final double? capitalMonto;
  final String? motivoAnulacion;

  /// Quién registró el movimiento y a qué cliente/préstamo corresponde
  /// (el servidor lo calcula; los movimientos antiguos pueden no traerlo).
  final int? usuarioId;
  final String? usuarioNombre;
  final String? clienteNombre;
  final String? clienteDni;
  final String? prestamoCodigo;

  /// EFECTIVO | DEPOSITO | YAPE | PLIN | OTRO (null = efectivo, datos antiguos)
  final String? medioPago;
  final String? banco;

  final int? id;
  final String? observaciones;
  final String? monto;
  final int? ventaId;
  final int? pagoId;
  final int? prestamoId;
  final String? createdBy;
  final bool? suma;
  final bool? eliminado;
  final TypeBoxEntity? tipo;
  final String? createdAt;
  final String? updatedAt;

  MovimientosEntity copyWith({
    int? id,
    String? observaciones,
    String? monto,
    int? ventaId,
    int? pagoId,
    int? prestamoId,
    String? createdBy,
    bool? suma,
    bool? eliminado,
    String? createdAt,
    String? updatedAt,
    TypeBoxEntity? tipo,
    String? medioPago,
    String? banco,
    int? usuarioId,
    String? usuarioNombre,
    String? clienteNombre,
    String? clienteDni,
    String? prestamoCodigo,
    double? interesMonto,
    double? capitalMonto,
    String? motivoAnulacion,
  }) {
    return MovimientosEntity(
      interesMonto: interesMonto ?? this.interesMonto,
      capitalMonto: capitalMonto ?? this.capitalMonto,
      motivoAnulacion: motivoAnulacion ?? this.motivoAnulacion,
      usuarioId: usuarioId ?? this.usuarioId,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteDni: clienteDni ?? this.clienteDni,
      prestamoCodigo: prestamoCodigo ?? this.prestamoCodigo,
      medioPago: medioPago ?? this.medioPago,
      banco: banco ?? this.banco,
      id: id ?? this.id,
      observaciones: observaciones ?? this.observaciones,
      monto: monto ?? this.monto,
      ventaId: ventaId ?? this.ventaId,
      pagoId: pagoId ?? this.pagoId,
      prestamoId: prestamoId ?? this.prestamoId,
      createdBy: createdBy ?? this.createdBy,
      suma: suma ?? this.suma,
      eliminado: eliminado ?? this.eliminado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tipo: tipo ?? this.tipo,
    );
  }

  static List<MovimientosEntity> listMovimientosFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getMovimientosFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static MovimientosEntity getMovimientosFromMap(Map<String, dynamic> map) {
    return MovimientosEntity(
      id: map['id'],
      observaciones: map['observaciones'],
      monto: map['monto'],
      ventaId: map['ventaId'],
      pagoId: map['pagoId'],
      prestamoId: map['prestamoId'],
      createdBy: map['createdBy'],
      suma: map['suma'],
      eliminado: map['eliminado'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      medioPago: map['medioPago'] as String?,
      banco: map['banco'] as String?,
      usuarioId: map['usuarioId'] as int?,
      usuarioNombre: map['usuarioNombre'] as String?,
      clienteNombre: map['clienteNombre'] as String?,
      clienteDni: map['clienteDni']?.toString(),
      prestamoCodigo: map['prestamoCodigo']?.toString(),
      interesMonto: double.tryParse('${map['interesMonto'] ?? ''}'),
      capitalMonto: double.tryParse('${map['capitalMonto'] ?? ''}'),
      motivoAnulacion: map['motivoAnulacion']?.toString(),
      tipo: map['tipo'] != null
          ? TypeBoxEntity.getTypeFromMap(map['tipo'])
          : null,
    );
  }

  @override
  String toString() {
    return 'MovimientosEntity(id: $id, observaciones: $observaciones, monto: $monto, ventaId: $ventaId, pagoId: $pagoId, prestamoId: $prestamoId, createdBy: $createdBy, suma: $suma, eliminado: $eliminado, createdAt: $createdAt, updatedAt: $updatedAt, tipo: ${tipo?.codigo})';
  }

  @override
  List<Object?> get props => [
        id,
        observaciones,
        monto,
        ventaId,
        pagoId,
        prestamoId,
        createdBy,
        suma,
        eliminado,
        createdAt,
        updatedAt,
        tipo,
        medioPago,
        banco,
        usuarioId,
        usuarioNombre,
        clienteNombre,
        clienteDni,
        prestamoCodigo,
        interesMonto,
        capitalMonto,
        motivoAnulacion,
      ];
}

class TypeBoxEntity extends Equatable {
  const TypeBoxEntity({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.eliminado,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String? codigo;
  final String? descripcion;
  final bool? eliminado;
  final String? createdAt;
  final String? updatedAt;

  TypeBoxEntity copyWith({
    int? id,
    String? codigo,
    String? descripcion,
    bool? eliminado,
    String? createdAt,
    String? updatedAt,
  }) {
    return TypeBoxEntity(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      eliminado: eliminado ?? this.eliminado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static TypeBoxEntity getTypeFromMap(Map<String, dynamic> map) {
    return TypeBoxEntity(
      id: map['id'],
      eliminado: map['eliminado'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      codigo: map['codigo'],
      descripcion: map['descripcion'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        codigo,
        descripcion,
        eliminado,
        createdAt,
        updatedAt,
      ];
}
