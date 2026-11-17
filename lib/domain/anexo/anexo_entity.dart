import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

/// Qué pasó en una visita al cliente.
const Map<String, String> etiquetasVisita = {
  'RECLAMO': 'El cliente vino a reclamar',
  'HABLO_CLIENTE': 'Se habló con el cliente',
  'HABLO_FAMILIAR': 'Se habló con un familiar',
  'NO_ESTABA': 'No estaba / nadie atendió',
  'DEJO_AVISO': 'Se dejó el aviso por escrito',
  'DIRECCION_ERRADA': 'Dirección errada o no existe',
  'SE_NEGO': 'Se negó a pagar o recoger',
};

class AnexoEntity extends Equatable {
  final int id;
  final String descripcion;
  final String url;
  final String tipo;
  final String updatedAt;
  final String createdAt;
  final String? deletedAt;
  final LoansEntity? prestamo;
  final String? resultado;
  final String? promesaFecha;
  final String? promesaMonto;
  final int? prorrogaDias;
  final String? usuarioNombre;

  /// Texto de lo que pasó en la visita.
  String get resultadoTexto => etiquetasVisita[resultado] ?? '';

  const AnexoEntity({
    required this.id,
    required this.descripcion,
    required this.url,
    required this.tipo,
    required this.updatedAt,
    required this.createdAt,
    required this.deletedAt,
    required this.prestamo,
    this.resultado,
    this.promesaFecha,
    this.promesaMonto,
    this.prorrogaDias,
    this.usuarioNombre,
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
      url: (map['url'] ?? '').toString(),
      resultado: map['resultado']?.toString(),
      promesaFecha: map['promesaFecha']?.toString(),
      promesaMonto: map['promesaMonto']?.toString(),
      prorrogaDias: map['prorrogaDias'] is num ? (map['prorrogaDias'] as num).toInt() : null,
      usuarioNombre: map['usuarioNombre']?.toString(),
      prestamo: map['prestamo'] != null
          ? LoansEntity.getLoanFromMap(map['prestamo'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        descripcion,
        url,
        tipo,
        updatedAt,
        createdAt,
        deletedAt,
        prestamo,
        resultado,
        promesaFecha,
        promesaMonto,
        prorrogaDias,
        usuarioNombre,
      ];
}
