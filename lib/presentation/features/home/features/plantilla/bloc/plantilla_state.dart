part of 'plantilla_bloc.dart';

sealed class PlantillaState extends Equatable {
  const PlantillaState();
  
  @override
  List<Object> get props => [];
}

final class PlantillaInitial extends PlantillaState {}
