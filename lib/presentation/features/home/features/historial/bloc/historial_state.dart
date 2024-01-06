part of 'historial_bloc.dart';

enum HistorialStatus { initial, loading, error, loaded }

class HistorialState extends Equatable {
  const HistorialState({
    this.historialStatus = HistorialStatus.initial,
    this.historialDetailsStatus = HistorialStatus.initial,
    this.listUsers,
    this.listHistorial,
    this.error,
  });

  final HistorialStatus historialStatus;
  final HistorialStatus historialDetailsStatus;

  final List<UserEntity>? listUsers;
  final List<HistorialEntity>? listHistorial;
  final String? error;

  bool get isHistorialLoading => historialStatus == HistorialStatus.loading;
  bool get isHistorialError => historialStatus == HistorialStatus.error;

  bool get isHistorialDetailsLoading =>
      historialDetailsStatus == HistorialStatus.loading;

  bool get isHistorialDetailsError =>
      historialDetailsStatus == HistorialStatus.error;

  bool get isHistorialDetailsSuccess =>
      historialDetailsStatus == HistorialStatus.loaded;

  HistorialState copyWith({
    HistorialStatus? historialStatus,
    HistorialStatus? historialDetailsStatus,
    List<UserEntity>? listUsers,
    List<HistorialEntity>? listHistorial,
    String? error,
  }) =>
      HistorialState(
        error: error ?? this.error,
        listHistorial: listHistorial ?? this.listHistorial,
        historialDetailsStatus:
            historialDetailsStatus ?? this.historialDetailsStatus,
        listUsers: listUsers ?? this.listUsers,
        historialStatus: historialStatus ?? this.historialStatus,
      );

  @override
  List<Object?> get props => [
        historialStatus,
        historialDetailsStatus,
        listUsers,
        listHistorial,
        error,
      ];
}
