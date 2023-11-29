part of 'users_bloc.dart';

enum UserStatus { initial, loading, error, loaded }

class UsersState extends Equatable {
  const UsersState({
    this.userStatus = UserStatus.initial,
    this.listUsers,
    this.error,
  });

  final UserStatus userStatus;
  final List<UserEntity>? listUsers;
  final String? error;

  bool get isUserLoading => userStatus == UserStatus.loading;
  bool get isUserError => userStatus == UserStatus.error;

  UsersState copyWith({
    UserStatus? userStatus,
    List<UserEntity>? listUsers,
    String? error,
  }) =>
      UsersState(
        error: error ?? this.error,
        listUsers: listUsers ?? this.listUsers,
        userStatus: userStatus ?? this.userStatus,
      );

  @override
  List<Object?> get props => [
        userStatus,
        listUsers,
        error,
      ];
}
