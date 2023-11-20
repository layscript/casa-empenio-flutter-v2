part of 'interests_bloc.dart';

sealed class InterestsState extends Equatable {
  const InterestsState();

  @override
  List<Object> get props => [];
}

final class InterestsInitial extends InterestsState {}

final class InterestsLoading extends InterestsState {}

final class InterestsLoaded extends InterestsState {
  const InterestsLoaded(this.listInterests);
  final List<Interests> listInterests;
}

final class InterestsError extends InterestsState {
  const InterestsError(this.message);
  final String message;
}
