class ContratoEntity {
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
}

class PrendaEntity {
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
}
