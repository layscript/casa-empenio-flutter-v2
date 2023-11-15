part of 'home_bloc.dart';

class HomeState extends Equatable {
  const HomeState({
    this.index = 0,
  });
  final int index;

  HomeState copyWith({int? index}) => HomeState(
        index: index ?? this.index,
      );

  @override
  List<Object> get props => [index];
}
