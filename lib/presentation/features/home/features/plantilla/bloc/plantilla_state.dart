part of 'plantilla_bloc.dart';

enum PlantillaStatus { initial, loading, success, failure, navigate }

class PlantillaState extends Equatable {
  const PlantillaState({
    this.htmlContent = '',
    this.status = PlantillaStatus.initial,
    this.dialogStatus = PlantillaStatus.initial,
    this.error,
    this.plantillaSelected,
    this.plantillas = const <PlantillaEntity>[],
  });

  final String htmlContent;
  final PlantillaStatus status;
  final PlantillaStatus dialogStatus;
  final String? error;
  final String? plantillaSelected;
  final List<PlantillaEntity> plantillas;

  PlantillaState copyWith({
    String? htmlContent,
    PlantillaStatus? status,
    String? error,
    String? plantillaSelected,
    PlantillaStatus? dialogStatus,
    List<PlantillaEntity>? plantillas,
  }) {
    return PlantillaState(
      htmlContent: htmlContent ?? this.htmlContent,
      status: status ?? this.status,
      error: error,
      plantillaSelected: plantillaSelected ?? this.plantillaSelected,
      dialogStatus: dialogStatus ?? this.dialogStatus,
      plantillas: plantillas ?? this.plantillas,
    );
  }

  @override
  List<Object?> get props => [
        htmlContent,
        status,
        error,
        plantillaSelected,
        dialogStatus,
        plantillas,
      ];
}
