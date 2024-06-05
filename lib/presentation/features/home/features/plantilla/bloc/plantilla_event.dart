part of 'plantilla_bloc.dart';

sealed class PlantillaEvent extends Equatable {
  const PlantillaEvent();

  @override
  List<Object> get props => [];
}

class GetPlantilla extends PlantillaEvent {}

class GeneratePlantilla extends PlantillaEvent {
  final String url;
  const GeneratePlantilla(this.url);
}
