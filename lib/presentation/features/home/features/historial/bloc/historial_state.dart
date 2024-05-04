part of 'historial_bloc.dart';

enum HistorialStatus { initial, loading, error, loaded }

class HistorialState extends Equatable {
  const HistorialState({
    this.historialStatus = HistorialStatus.initial,
    this.historialDetailsStatus = HistorialStatus.initial,
    this.listUsers,
    this.listSales,
    this.listHistorial,
    this.error,
    this.historialUserVentasStatus = HistorialStatus.initial,
    required this.startSales,
    required this.endSales,
  });

  final HistorialStatus historialStatus;
  final HistorialStatus historialDetailsStatus;
  final HistorialStatus historialUserVentasStatus;

  final List<UserEntity>? listUsers;
  final List<HistorialEntity>? listHistorial;
  final List<SalesEntity>? listSales;

  final DateTime startSales;
  final DateTime endSales;

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
    HistorialStatus? historialUserVentasStatus,
    List<UserEntity>? listUsers,
    List<HistorialEntity>? listHistorial,
    List<SalesEntity>? listSales,
    String? error,
    DateTime? startSales,
    DateTime? endSales,
  }) =>
      HistorialState(
        error: error ?? this.error,
        listHistorial: listHistorial ?? this.listHistorial,
        listSales: listSales ?? this.listSales,
        historialDetailsStatus:
            historialDetailsStatus ?? this.historialDetailsStatus,
        listUsers: listUsers ?? this.listUsers,
        historialStatus: historialStatus ?? this.historialStatus,
        historialUserVentasStatus:
            historialUserVentasStatus ?? this.historialUserVentasStatus,
        startSales: startSales ?? this.startSales,
        endSales: endSales ?? this.endSales,
      );

  @override
  List<Object?> get props => [
        historialStatus,
        historialDetailsStatus,
        historialUserVentasStatus,
        listUsers,
        listHistorial,
        listSales,
        error,
        startSales,
        endSales,
      ];
}
