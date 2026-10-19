import 'package:equatable/equatable.dart';

class CategoriesEntity extends Equatable {
  const CategoriesEntity({
    required this.id,
    required this.descripcion,
    required this.updatedAt,
    required this.createdAt,
    this.padreId,
    this.ocultarBasicos = false,
    this.plantilla,
  });

  final int id;
  final String descripcion;
  final String updatedAt;
  final String createdAt;

  /// Si es subcategoría, id de la categoría principal
  final int? padreId;

  /// true = no se piden marca/modelo/color/estado (ej. terreno)
  final bool ocultarBasicos;
  final String? plantilla;

  static List<CategoriesEntity> listGetCategoriesFromMap(
    Map<String, dynamic> map,
  ) {
    final list = map['body'] as List<dynamic>;
    return list
        .map((e) => getCategoriesFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static CategoriesEntity getCategoriesFromMap(Map<String, dynamic> map) {
    return CategoriesEntity(
      id: map['id'],
      createdAt: map['createdAt'],
      descripcion: map['descripcion'],
      updatedAt: map['updatedAt'],
      padreId: (map['padreId'] as num?)?.toInt(),
      ocultarBasicos: map['ocultarBasicos'] == true || map['ocultarBasicos'] == 1,
      plantilla: map['plantilla']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        descripcion,
        updatedAt,
        createdAt,
        padreId,
        ocultarBasicos,
        plantilla,
      ];
}

/// Nombre para mostrar: "Vehículos › Moto" si es subcategoría.
String nombreCategoria(CategoriesEntity c, Iterable<CategoriesEntity>? todas) {
  if (c.padreId == null || todas == null) return c.descripcion;
  for (final p in todas) {
    if (p.id == c.padreId) return '${p.descripcion} › ${c.descripcion}';
  }
  return c.descripcion;
}

/// ¿En esta categoría (o su principal) se ocultan marca/modelo/color/estado?
bool categoriaOcultaBasicos(CategoriesEntity? c, Iterable<CategoriesEntity>? todas) {
  if (c == null) return false;
  if (c.ocultarBasicos) return true;
  if (c.padreId == null || todas == null) return false;
  for (final p in todas) {
    if (p.id == c.padreId) return p.ocultarBasicos;
  }
  return false;
}

/// Lista ordenada: cada categoría principal seguida de sus subcategorías.
List<CategoriesEntity> ordenarCategorias(Iterable<CategoriesEntity> todas) {
  final lista = todas.toList();
  final ids = lista.map((e) => e.id).toSet();
  final raices = lista.where((c) => c.padreId == null || !ids.contains(c.padreId)).toList()
    ..sort((a, b) => a.descripcion.toLowerCase().compareTo(b.descripcion.toLowerCase()));
  final out = <CategoriesEntity>[];
  for (final r in raices) {
    out.add(r);
    out.addAll(lista.where((c) => c.padreId == r.id && c.id != r.id).toList()
      ..sort((a, b) => a.descripcion.toLowerCase().compareTo(b.descripcion.toLowerCase())));
  }
  return out;
}
