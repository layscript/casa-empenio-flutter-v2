part of 'plantilla_bloc.dart';

enum PlantillaStatus { initial, loading, success, failure, navigate }

class PlantillaState extends Equatable {
  const PlantillaState({
    this.htmlContent = '',
    this.status = PlantillaStatus.initial,
    this.error,
  });

  final String htmlContent;
  final PlantillaStatus status;
  final String? error;

  PlantillaState copyWith({
    String? htmlContent,
    PlantillaStatus? status,
    String? error,
  }) {
    return PlantillaState(
      htmlContent: htmlContent ?? this.htmlContent,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        htmlContent,
        status,
        error,
      ];
}
