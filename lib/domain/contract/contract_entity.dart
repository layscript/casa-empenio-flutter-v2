import 'package:equatable/equatable.dart';

class ContratoEntity extends Equatable {
  const ContratoEntity({
    required this.numero,
    required this.nombre,
    required this.dni,
    required this.domicilio,
    required this.fechaVencimiento,
    required this.monto,
    required this.montoPagar,
    required this.prendas,
    required this.nombreAval,
    required this.dniAval,
    required this.interes,
  });

  final int numero;
  final String nombre;
  final String dni;
  final String domicilio;
  final DateTime fechaVencimiento;
  final double monto;
  final double montoPagar;
  final List<PrendaEntity> prendas;
  final String nombreAval;
  final String dniAval;
  final double interes;

  toJson() {
    final fecha = DateTime.now();

    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];

    return {
      'codigo': numero,
      'nombre': nombre,
      'dni': dni,
      'domicilio': domicilio,
      'fechaVencimiento':
          '${fechaVencimiento.day}/${fechaVencimiento.month.toString().padLeft(2, '0')}/${fechaVencimiento.year}',
      'monto': monto,
      'montoPagar': montoPagar,
      'prendas': prendas.map((e) => e.toJson()).toList(),
      'nombreAval': nombreAval,
      'dniAval': dniAval,
      'interes': interes,
      'fecha': '${fecha.day} de ${meses[fecha.month - 1]} del ${fecha.year}',
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return ContratoEntity(
      numero: int.parse(json['numero'].toString()),
      nombre: json['nombre'],
      dni: json['dni'],
      domicilio: json['domicilio'],
      fechaVencimiento: DateTime.parse(json['fechaVencimiento']),
      monto: double.parse(json['monto']),
      montoPagar: double.parse(json['montoPagar']),
      prendas: (json['prendas'] as List)
          .map((e) => PrendaEntity.fromJson(e))
          .toList(),
      nombreAval: json['nombreAval'],
      dniAval: json['dniAval'],
      interes: double.parse(json['interes']),
    );
  }

  @override
  List<Object?> get props => [
        numero,
        nombre,
        dni,
        domicilio,
        fechaVencimiento,
        monto,
        montoPagar,
        prendas,
        nombreAval,
        dniAval,
        interes,
      ];
}

class PrendaEntity extends Equatable {
  const PrendaEntity({
    required this.nombre,
    required this.marca,
    required this.modelo,
    required this.serie,
    required this.color,
    required this.estado,
  });

  final String? nombre;
  final String? marca;
  final String? modelo;
  final String? serie;
  final String? color;
  final String? estado;

  toJson() {
    return {
      'nombre': nombre,
      'marca': marca,
      'modelo': modelo,
      'serie': serie,
      'color': color,
      'estado': estado,
    };
  }

  factory PrendaEntity.fromJson(Map<String, dynamic> json) {
    return PrendaEntity(
      nombre: json['nombre'],
      marca: json['marca'],
      modelo: json['modelo'],
      serie: json['serie'],
      color: json['color'],
      estado: json['estado'],
    );
  }

  @override
  List<Object?> get props => [
        nombre,
        marca,
        modelo,
        serie,
        color,
        estado,
      ];
}
