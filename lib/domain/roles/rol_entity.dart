import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:equatable/equatable.dart';

class RoleEntity extends Equatable {
  const RoleEntity({
    required this.id,
    required this.nombre,
    required this.modulos,
  });

  final int id;
  final String nombre;
  final List<ModulosEntity>? modulos;

  static List<RoleEntity> listGetRolesFromMap(
    List<dynamic> list,
  ) {
    return list.map((e) => roleFromMap(e as Map<String, dynamic>)).toList();
  }

  static RoleEntity roleFromMap(Map<String, dynamic> map) => RoleEntity(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        modulos: map['modulos'] != null
            ? ModulosEntity.listGetModulosEntityFromMap(
                map['modulos'],
              )
            : null,
      );

  @override
  List<Object?> get props => [
        id,
        nombre,
        modulos,
      ];
}
