part of 'interests_bloc.dart';

enum InterestsStatus { initial, loading, error, loaded }

class InterestsState extends Equatable {
  const InterestsState({
    this.interestsStatus = InterestsStatus.initial,
    this.listInterests,
    this.error,
  });

  final InterestsStatus interestsStatus;
  final List<InterestsEntity>? listInterests;
  final String? error;

  bool get isInterestLoading => interestsStatus == InterestsStatus.loading;
  bool get isInteresError => interestsStatus == InterestsStatus.error;

  InterestsState copyWith({
    InterestsStatus? interestsStatus,
    List<InterestsEntity>? listInterests,
    String? error,
  }) =>
      InterestsState(
        error: error ?? this.error,
        listInterests: listInterests ?? this.listInterests,
        interestsStatus: interestsStatus ?? this.interestsStatus,
      );

  @override
  List<Object?> get props => [
        interestsStatus,
        listInterests,
        error,
      ];
}
