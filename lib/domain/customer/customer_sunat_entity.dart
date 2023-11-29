class CustomerSunatEntity {
  final String? dni;
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final HomeSunatEntity? domicilio;

  const CustomerSunatEntity({
    required this.dni,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.domicilio,
  });

  static CustomerSunatEntity getCustomerSunatFromMap(Map<String, dynamic> map) {
    return CustomerSunatEntity(
      dni: map['dni'],
      nombre: map['nombre'],
      apellidoPaterno: map['apellido_paterno'],
      apellidoMaterno: map['apellido_materno'],
      domicilio: map['domicilio'] != null
          ? HomeSunatEntity.getCustomerHomeSunatEntity(map['domicilio'])
          : null,
    );
  }
}

class HomeSunatEntity {
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
}
