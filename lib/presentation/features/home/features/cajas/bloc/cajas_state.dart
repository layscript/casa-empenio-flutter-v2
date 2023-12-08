part of 'cajas_bloc.dart';

enum CajasStatus { initial, loading, error, loaded, success, failure }

class CajasState extends Equatable {
  const CajasState({
    this.cajasStatus = CajasStatus.initial,
    this.listCajas,
    this.error,
    this.movements,
  });

  final CajasStatus cajasStatus;
  final List<CajaEntity>? listCajas;
  final CajaEntity? movements;

  final String? error;

  bool get isCajasLoading => cajasStatus == CajasStatus.loading;
  bool get isCajasError => cajasStatus == CajasStatus.error;

  bool get isCajasSuccess => cajasStatus == CajasStatus.success;
  bool get isCajasFailure => cajasStatus == CajasStatus.failure;

  CajasState copyWith({
    CajasStatus? cajasStatus,
    List<CajaEntity>? listCajas,
    CajaEntity? movements,
    String? error,
  }) =>
      CajasState(
        cajasStatus: cajasStatus ?? this.cajasStatus,
        listCajas: listCajas ?? this.listCajas,
        error: error ?? this.error,
        movements: movements,
      );

  @override
  List<Object?> get props => [
        cajasStatus,
        listCajas,
        error,
        movements,
      ];
}
