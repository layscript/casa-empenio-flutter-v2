part of 'sales_bloc.dart';

sealed class SalesState extends Equatable {
  const SalesState();
  
  @override
  List<Object> get props => [];
}

final class SalesInitial extends SalesState {}
