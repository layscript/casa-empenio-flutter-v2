part of 'perdonados_bloc.dart';

sealed class PerdonadosEvent extends Equatable {
  const PerdonadosEvent();

  @override
  List<Object> get props => [];
}

final class GetAllPerdonados extends PerdonadosEvent {
  final DateTime? inicio;
  final DateTime? fin;

  const GetAllPerdonados({
    required this.inicio,
    required this.fin,
  });
}
