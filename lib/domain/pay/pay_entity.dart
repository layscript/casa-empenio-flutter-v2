import 'package:casa_empenio_pe_dev/domain/domain.dart';

class PayEntity {
  const PayEntity({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.customer,
    required this.prestamo,
    required this.usuario,
    required this.updatedAt,
    required this.createdAt,
  });

  final int? id;
  final String? monto;
  final String? fecha;
  final CustomerEntity? customer;
  final LoansEntity? prestamo;
  final UserEntity? usuario;
  final String? updatedAt;
  final String? createdAt;

  static List<PayEntity> listGetPayFromMap(
    List<dynamic> list,
  ) {
    return list.map((e) => getPayFromMap(e as Map<String, dynamic>)).toList();
  }

  static PayEntity getPayFromMap(Map<String, dynamic> map) {
    return PayEntity(
      id: map['id'],
      monto: map['monto'],
      fecha: map['fecha'],
      customer: map['customer'] != null
          ? CustomerEntity.getCustomerFromMap(map['customer'])
          : null,
      prestamo: map['prestamo'] != null
          ? LoansEntity.getLoanFromMap(map['prestamo'])
          : null,
      usuario: map['usuario'] != null
          ? UserEntity.userFromMap(map['usuario'])
          : null,
      updatedAt: map['updatedAt'],
      createdAt: map['createdAt'],
    );
  }
}
