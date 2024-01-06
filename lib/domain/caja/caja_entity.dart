class CajaEntity {
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
  final int? usuarioApertura;
  final String? montoApertura;
  final String? horaCierre;
  final int? usuarioCierre;
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

  static List<CajaEntity> listGetCajaFromMap(
    List<dynamic> list,
  ) {
    return list.map((e) => getCajaFromMap(e as Map<String, dynamic>)).toList();
  }

  static CajaEntity getCajaFromMap(Map<String, dynamic> map) {
    return CajaEntity(
      id: map['id'],
      fecha: map['fecha'],
      horaApertura: map['horaApertura'],
      usuarioApertura: map['usuarioApertura'],
      montoApertura: map['montoApertura'],
      horaCierre: map['horaCierre'],
      usuarioCierre: map['usuarioCierre'],
      montoCierreReal: map['montoCierreReal'],
      montoCierreTeorico: map['montoCierreTeorico'],
      montoDiferencia: map['montoDiferencia'],
      totalEgresos: map['totalEgresos'],
      totalIngresos: map['totalIngresos'],
      estado: map['estado'],
      observaciones: map['observaciones'],
      eliminado: map['eliminado'],
      updatedAt: map['updatedAt'],
      createdAt: map['createdAt'],
      movimientos: map['movimientos'] != null
          ? MovimientosEntity.listMovimientosFromMap(map['movimientos'])
          : null,
    );
  }
}

class MovimientosEntity {
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
  });

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
      tipo: map['tipo'] != null
          ? TypeBoxEntity.getTypeFromMap(map['tipo'])
          : null,
    );
  }
}

class TypeBoxEntity {
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
}
