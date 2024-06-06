class ExpensesEntity {
  const ExpensesEntity({
    required this.id,
    required this.observaciones,
    required this.monto,
    required this.ventaId,
    required this.pagoId,
    required this.prestamoId,
    required this.compraId,
    required this.createdBy,
    required this.updatedAt,
    required this.createdAt,
    required this.suma,
    required this.eliminado,
    required this.tipo,
    required this.imagenes,
  });

  final int? id;
  final String? observaciones;
  final String? monto;
  final int? ventaId;
  final int? pagoId;
  final int? prestamoId;
  final int? compraId;
  final String? createdBy;
  final String? updatedAt;
  final String? createdAt;
  final bool? suma;
  final bool? eliminado;
  final TypeEntity? tipo;
  final List<Imagenes>? imagenes;

  static List<ExpensesEntity> listGetExpensesFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getExpensesFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static ExpensesEntity getExpensesFromMap(Map<String, dynamic> map) {
    return ExpensesEntity(
      id: map['id'],
      observaciones: map['observaciones'],
      monto: map['monto'],
      ventaId: map['ventaId'],
      pagoId: map['pagoId'],
      prestamoId: map['prestamoId'],
      compraId: map['compraId'],
      createdBy: map['createdBy'],
      updatedAt: map['updatedAt'],
      createdAt: map['createdAt'],
      suma: map['suma'],
      eliminado: map['eliminado'],
      tipo: map['tipo'] != null
          ? TypeEntity.getTypeEntityFromMap(map['tipo'])
          : null,
      imagenes: map['imagenes'] != null
          ? Imagenes.listGetImagenesFromMap(map['imagenes'])
          : null,
    );
  }
}

class TypeEntity {
  const TypeEntity({
    required this.id,
    required this.codigo,
    required this.descripcion,
    required this.eliminado,
    required this.updatedAt,
    required this.createdAt,
  });

  final int? id;
  final String? codigo;
  final String? descripcion;
  final bool? eliminado;
  final String? updatedAt;
  final String? createdAt;

  static TypeEntity getTypeEntityFromMap(Map<String, dynamic> map) {
    return TypeEntity(
      id: map['id'],
      codigo: map['codigo'],
      descripcion: map['descripcion'],
      eliminado: map['eliminado'],
      updatedAt: map['updatedAt'],
      createdAt: map['createdAt'],
    );
  }
}

class Imagenes {
  final int id;
  final String url;
  final String createdAt;

  const Imagenes({
    required this.id,
    required this.url,
    required this.createdAt,
  });

  static List<Imagenes> listGetImagenesFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getImagenesFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Imagenes getImagenesFromMap(Map<String, dynamic> map) {
    return Imagenes(
      id: map['id'],
      createdAt: map['created_at'],
      url: map['url'],
    );
  }
}
