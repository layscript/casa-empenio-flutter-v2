class ModulosEntity {
  final int id;
  final String nombre;

  const ModulosEntity({
    required this.id,
    required this.nombre,
  });

  static List<ModulosEntity> listGetModulosEntityFromMap(
    List<dynamic> list,
  ) {
    return list
        .map((e) => getModulosEntityFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static ModulosEntity getModulosEntityFromMap(Map<String, dynamic> map) {
    return ModulosEntity(
      id: map['id'],
      nombre: map['nombre'],
    );
  }
}
