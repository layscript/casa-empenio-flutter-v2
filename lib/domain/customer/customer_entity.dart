import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  const CustomerEntity({
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.domicilio,
    required this.email,
    required this.celular,
    required this.prestamos,
    required this.prestamosAval,
    required this.pagos,
    required this.imagenUno,
    required this.imagenDos,
    required this.ventas,
    required this.updatedAt,
    required this.createdAt,
  });

  final String? dni;
  final String? nombres;
  final String? apellidos;
  final String? domicilio;
  final String? email;
  final String? celular;
  final List<LoansEntity>? prestamos;
  final List<LoansEntity>? prestamosAval;
  final List<PayEntity>? pagos;
  final List<SalesEntity>? ventas;
  final String? imagenUno;
  final String? imagenDos;
  final String? updatedAt;
  final String? createdAt;

  String get customerFullName => (dni == null || dni!.isEmpty || dni == 'null')
      ? '$nombres'
      : apellidos != "null null"
          ? '$nombres $apellidos'
          : '$nombres';

  @override
  String toString() {
    return '''
    dni: $dni,
    nombres: $nombres,
    apellidos: $apellidos,
    domicilio: $domicilio,
    email: $email,
    celular: $celular,
    prestamos: $prestamos,
    prestamosAval: $prestamosAval,
    pagos: $pagos,
    ventas: $ventas,
    imagenUno: $imagenUno,
    imagenDos: $imagenDos,
''';
  }

  static List<CustomerEntity> listGetCustomerFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getCustomerFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static CustomerEntity getCustomerFromMap(Map<String, dynamic> map) {
    print('ajsdkjksadl: ${map}');
    return CustomerEntity(
      dni: map['dni'],
      nombres: map['nombres'],
      apellidos: map['apellidos'],
      domicilio: map['domicilio'],
      email: map['email'],
      celular: map['celular'],
      imagenUno: map['imagen'],
      imagenDos: map['imagen2'],
      prestamos: map['prestamos'] != null
          ? LoansEntity.listGetSalesDetailFromMap(
              map['prestamos'] as List<dynamic>)
          : null,
      prestamosAval: map['prestamosAval'] != null
          ? LoansEntity.listGetSalesDetailFromMap(
              map['prestamosAval'] as List<dynamic>)
          : null,
      pagos: map['pagos'] != null
          ? PayEntity.listGetPayFromMap(
              map['pagos'] as List<dynamic>,
            )
          : null,
      ventas: map['ventas'] != null
          ? SalesEntity.listGetSalesFromMap(map['ventas'] as List<dynamic>)
          : null,
      updatedAt: map['updatedAt'],
      createdAt: map['createdAt'],
    );
  }

  @override
  List<Object?> get props => [
        dni,
        nombres,
        apellidos,
        domicilio,
        email,
        celular,
        prestamos,
        prestamosAval,
        pagos,
        ventas,
        imagenUno,
        imagenDos,
        updatedAt,
        createdAt,
      ];
}
