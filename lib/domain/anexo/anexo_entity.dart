import 'package:casa_empenio_pe/domain/domain.dart';

class AnexoEntity {
  final int id;
  final String descripcion;
  final String url;
  final String tipo;
  final String updatedAt;
  final String createdAt;
  final String? deletedAt;
  final LoansEntity? prestamo;

  const AnexoEntity({
    required this.id,
    required this.descripcion,
    required this.url,
    required this.tipo,
    required this.updatedAt,
    required this.createdAt,
    required this.deletedAt,
    required this.prestamo,
  });

  static List<AnexoEntity> listGetAnexosFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getAnexosFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static AnexoEntity getAnexosFromMap(Map<String, dynamic> map) {
    return AnexoEntity(
      id: map['id'],
      updatedAt: map['updatedAt'],
      deletedAt: map['deletedAt'],
      descripcion: map['descripcion'],
      createdAt: map['createdAt'],
      tipo: map['tipo'],
      url: map['url'],
      prestamo: map['prestamo'] != null
          ? LoansEntity.getLoanFromMap(map['prestamo'])
          : null,
    );
  }
}
