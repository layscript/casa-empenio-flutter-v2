import 'package:equatable/equatable.dart';

class CustomerSunatEntity extends Equatable {
  final String? ruc;
  final String? dni;
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final HomeSunatEntity? domicilio;

  const CustomerSunatEntity({
    required this.ruc,
    required this.dni,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.domicilio,
  });

  String get customerDocument => ruc == null ? dni! : ruc!;

  String get customerFullName => ruc != null
      ? nombre ?? ''
      : '${nombre ?? ''} ${apellidoPaterno ?? ''} ${apellidoMaterno ?? ''}'.trim();

  static CustomerSunatEntity getCustomerSunatFromMap(Map<String, dynamic> map) {
    return CustomerSunatEntity(
      dni: map['dni'],
      nombre: map['nombre'],
      // El servicio de consulta de DNI entrega los dos apellidos al revés: aquí se ponen en su lugar.
      apellidoPaterno: map['apellido_materno'],
      apellidoMaterno: map['apellido_paterno'],
      ruc: map['ruc'],
      domicilio: map['domicilio'] != null
          ? HomeSunatEntity.getCustomerHomeSunatEntity(map['domicilio'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        ruc,
        dni,
        nombre,
        apellidoPaterno,
        apellidoMaterno,
        domicilio,
      ];
}

class HomeSunatEntity extends Equatable {
  final String? direccion;
  final String? distrito;
  final String? provincia;
  final String? departamento;
  final String? ubigeo;

  const HomeSunatEntity({
    required this.direccion,
    required this.distrito,
    required this.provincia,
    required this.departamento,
    required this.ubigeo,
  });

  static HomeSunatEntity getCustomerHomeSunatEntity(Map<String, dynamic> map) {
    return HomeSunatEntity(
      direccion: map['direccion'],
      distrito: map['distrito'],
      provincia: map['provincia'],
      departamento: map['departamento'],
      ubigeo: map['ubigeo'],
    );
  }

  @override
  List<Object?> get props => [
        direccion,
        distrito,
        provincia,
        departamento,
        ubigeo,
      ];
}
