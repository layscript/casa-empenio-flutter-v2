part of 'reports_bloc.dart';

sealed class ReportsState extends Equatable {
  const ReportsState();
  
  @override
  List<Object> get props => [];
}

final class ReportsInitial extends ReportsState {}
