import 'package:casa_empenio_pe/domain/loans/loans_entity.dart';

class IncreaseEntity {
  const IncreaseEntity({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.observaciones,
    required this.url,
  });

  final int? id;
  final String? fecha;
  final String? monto;
  final String? observaciones;
  final String? url;

  static List<IncreaseEntity> listIncreaseFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getIncreaseFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static IncreaseEntity getIncreaseFromMap(Map<String, dynamic> map) {
    print('aumentosssss: $map');

    return IncreaseEntity(
      id: map['id'],
      fecha: map['fecha'],
      monto: map['monto'],
      observaciones: map['observaciones'],
      url: map['url'],
    );
  }
}
