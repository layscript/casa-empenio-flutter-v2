part of 'users_bloc.dart';

enum UserStatus { initial, loading, error, loaded }

class UsersState extends Equatable {
  const UsersState({
    this.userStatus = UserStatus.initial,
    this.listUsers,
    this.error,
    this.listSucursales,
    this.listRoles,
  });

  final UserStatus userStatus;
  final List<UserEntity>? listUsers;
  final List<SucursalEntity>? listSucursales;
  final List<RoleEntity>? listRoles;

  final String? error;

  bool get isUserLoading => userStatus == UserStatus.loading;
  bool get isUserError => userStatus == UserStatus.error;

  UsersState copyWith({
    UserStatus? userStatus,
    List<UserEntity>? listUsers,
    String? error,
    List<SucursalEntity>? listSucursales,
    List<RoleEntity>? listRoles,
  }) =>
      UsersState(
        error: error ?? this.error,
        listUsers: listUsers ?? this.listUsers,
        userStatus: userStatus ?? this.userStatus,
        listSucursales: listSucursales ?? this.listSucursales,
        listRoles: listRoles ?? this.listRoles,
      );

  @override
  List<Object?> get props =>
      [userStatus, listUsers, error, listSucursales, listRoles];
}
