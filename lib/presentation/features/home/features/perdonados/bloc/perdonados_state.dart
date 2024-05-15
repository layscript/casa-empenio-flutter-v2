part of 'perdonados_bloc.dart';

enum PerdonadosStatus { initial, loading, success, error }

class PerdonadosState extends Equatable {
  final DateTime startTimePayments;
  final DateTime endTimePayments;
  final PerdonadosStatus status;
  final List<PerdonadosEntity> listPerdonados;

  const PerdonadosState({
    required this.startTimePayments,
    required this.endTimePayments,
    required this.status,
    required this.listPerdonados,
  });

  PerdonadosState copyWith({
    DateTime? startTimePayments,
    DateTime? endTimePayments,
    PerdonadosStatus? status,
    List<PerdonadosEntity>? listPerdonados,
  }) {
    return PerdonadosState(
      startTimePayments: startTimePayments ?? this.startTimePayments,
      endTimePayments: endTimePayments ?? this.endTimePayments,
      status: status ?? this.status,
      listPerdonados: listPerdonados ?? this.listPerdonados,
    );
  }

  @override
  List<Object> get props => [
        startTimePayments,
        endTimePayments,
        status,
        listPerdonados,
      ];
}
