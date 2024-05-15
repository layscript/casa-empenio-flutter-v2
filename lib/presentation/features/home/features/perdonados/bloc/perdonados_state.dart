part of 'perdonados_bloc.dart';

enum PerdonadosStatus { initial, loading, success, error }

class PerdonadosState extends Equatable {
  final DateTime startTimePayments;
  final DateTime endTimePayments;
  final PerdonadosStatus status;
  final List<PerdonadosEntity> listPerdonados;
  final String? message;

  const PerdonadosState({
    required this.startTimePayments,
    required this.endTimePayments,
    required this.status,
    required this.listPerdonados,
    required this.message,
  });

  PerdonadosState copyWith({
    DateTime? startTimePayments,
    DateTime? endTimePayments,
    PerdonadosStatus? status,
    List<PerdonadosEntity>? listPerdonados,
    String? message,
  }) {
    return PerdonadosState(
      startTimePayments: startTimePayments ?? this.startTimePayments,
      endTimePayments: endTimePayments ?? this.endTimePayments,
      status: status ?? this.status,
      listPerdonados: listPerdonados ?? this.listPerdonados,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        startTimePayments,
        endTimePayments,
        status,
        listPerdonados,
        message,
      ];
}
