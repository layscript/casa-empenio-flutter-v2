part of 'users_bloc.dart';

sealed class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object> get props => [];
}

final class UsersInitial extends UsersState {}

final class UsersLoading extends UsersState {}

final class UsersLoaded extends UsersState {
  const UsersLoaded(this.listUsers);
  final List<User> listUsers;
}

final class UsersError extends UsersState {
  const UsersError(this.message);
  final String message;
}
