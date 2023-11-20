part of 'interests_bloc.dart';

sealed class InterestsEvent extends Equatable {
  const InterestsEvent();

  @override
  List<Object> get props => [];
}

class GetInterests extends InterestsEvent {}

class SaveInterest extends InterestsEvent {
  const SaveInterest({required this.data});
  final String data;
}

class UpdateInterest extends InterestsEvent {
  const UpdateInterest({required this.id, required this.data});
  final String data;
  final int id;
}

class DeleteInterest extends InterestsEvent {
  const DeleteInterest({required this.id});
  final int id;
}
