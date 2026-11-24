import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

class PayEntity extends Equatable {
  const PayEntity({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.customer,
    required this.prestamo,
    required this.usuario,
    required this.updatedAt,
    required this.createdAt,
    required this.url,
    this.urls = const [],
    this.tipoPago,
  });

  final int? id;
  final String? monto;
  final String? fecha;
  final CustomerEntity? customer;
  final LoansEntity? prestamo;
  final UserEntity? usuario;
  final String? updatedAt;
  final String? createdAt;
  final String? url;

  /// Todas las capturas del pago (si fueron varias); la primera es [url].
  final List<String> urls;
  final String? tipoPago;

  /// Capturas para mostrar: las varias si las hay, si no la de siempre.
  List<String> get fotos => urls.isNotEmpty ? urls : ((url ?? '').isNotEmpty ? [url!] : const []);

  static List<PayEntity> listGetPayFromMap(
    List<dynamic> list,
  ) {
    return list.map((e) => getPayFromMap(e as Map<String, dynamic>)).toList();
  }

  static PayEntity getPayFromMap(Map<String, dynamic> map) {
    return PayEntity(
      id: map['id'],
      url: map['url'],
      urls: _leerUrls(map['urls']),
      tipoPago: map['tipoPago']?.toString(),
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

  static List<String> _leerUrls(dynamic v) {
    try {
      final l = v is String && v.trim().isNotEmpty ? jsonDecode(v) : v;
      if (l is List) return l.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    } catch (_) {}
    return const [];
  }

  @override
  List<Object?> get props => [
        id,
        monto,
        fecha,
        customer,
        prestamo,
        usuario,
        updatedAt,
        createdAt,
        url,
        urls,
        tipoPago,
      ];
}
