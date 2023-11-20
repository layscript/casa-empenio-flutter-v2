class Product {
  const Product({
    required this.id,
    required this.descripcion,
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
  });

  final int? id;
  final String? descripcion;
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
  final bool? activo;
  final String? updatedAt;
  final String? createdAt;
  final Loan? prestamo;
}

class Loan {
  const Loan({
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
  final String? fecha;
  final String? updatedAt;
  final String? createdAt;
}
