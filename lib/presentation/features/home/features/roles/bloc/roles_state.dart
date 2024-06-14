part of 'roles_bloc.dart';

enum RolesStatus { initial, loading, error, loaded }

class RolesState extends Equatable {
  const RolesState({
    this.status = RolesStatus.initial,
    this.listRoles = const <RoleEntity>[],
    this.listModules = const <ModulosEntity>[],
    this.error,
  });

  final List<RoleEntity> listRoles;
  final List<ModulosEntity> listModules;

  final String? error;
  final RolesStatus status;

  RolesState copyWith({
    RolesStatus? status,
    List<RoleEntity>? listRoles,
    List<ModulosEntity>? listModules,
    String? error,
  }) =>
      RolesState(
        status: status ?? this.status,
        listRoles: listRoles ?? this.listRoles,
        error: error ?? this.error,
        listModules: listModules ?? this.listModules,
      );

  @override
  List<Object?> get props => [
        listRoles,
        error,
        status,
        listModules,
      ];
}
