part of 'plantilla_bloc.dart';

sealed class PlantillaEvent extends Equatable {
  const PlantillaEvent();

  @override
  List<Object> get props => [];
}

class GetPlantillas extends PlantillaEvent {}

class GetLastPlantilla extends PlantillaEvent {}

class GeneratePlantilla extends PlantillaEvent {
  final String url;
  const GeneratePlantilla(this.url);
}

class SelectedPlantillaByText extends PlantillaEvent {
  final String text;
  const SelectedPlantillaByText(this.text);
}
