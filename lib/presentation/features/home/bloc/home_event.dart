part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class GoToHome extends HomeEvent {}

class GoToLoans extends HomeEvent {}

class GoToReports extends HomeEvent {}

class GoToSales extends HomeEvent {}

class GoToProducts extends HomeEvent {}

class GoToUsers extends HomeEvent {}

class GoToInterests extends HomeEvent {}
