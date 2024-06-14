part of 'roles_bloc.dart';

sealed class RolesEvent extends Equatable {
  const RolesEvent();

  @override
  List<Object> get props => [];
}

final class GetRoles extends RolesEvent {
  const GetRoles();
}

final class SearchRolesByName extends RolesEvent {
  final String value;
  const SearchRolesByName({required this.value});
}

final class SaveRol extends RolesEvent {
  final String nombre;
  final List<ModulosEntity> modulos;

  const SaveRol({
    required this.nombre,
    required this.modulos,
  });
}

final class UpdateRol extends RolesEvent {
  final int id;
  final String nombre;
  final List<ModulosEntity> modulos;

  const UpdateRol({
    required this.id,
    required this.nombre,
    required this.modulos,
  });
}
