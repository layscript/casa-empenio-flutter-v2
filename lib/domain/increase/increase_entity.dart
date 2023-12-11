import 'package:casa_empenio_pe/domain/loans/loans_entity.dart';

class IncreaseEntity {
  const IncreaseEntity({
    required this.id,
    required this.fecha,
    required this.monto,
    required this.observaciones,
/*     required this.prestamo,
 */  });

  final int? id;
  final String? fecha;
  final String? monto;
  final String? observaciones;
  /* final LoansEntity? prestamo; */

  static List<IncreaseEntity> listIncreaseFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getIncreaseFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static IncreaseEntity getIncreaseFromMap(Map<String, dynamic> map) {
    return IncreaseEntity(
      id: map['id'],
      fecha: map['fecha'],
      monto: map['monto'],
      observaciones: map['observaciones'],
      /* prestamo: map['prestamo'] != null
          ? LoansEntity.getLoanFromMap(map['prestamo'])
          : null, */
    );
  }
}
