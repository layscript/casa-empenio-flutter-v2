part of 'historial_bloc.dart';

sealed class HistorialEvent extends Equatable {
  const HistorialEvent();

  @override
  List<Object> get props => [];
}

class GetAllHistorialEvent extends HistorialEvent {}

class GetHistorialByDocumentEvent extends HistorialEvent {
  const GetHistorialByDocumentEvent(this.userId);
  final int userId;
}

class GetHistorialUserVentasEvent extends HistorialEvent {
  const GetHistorialUserVentasEvent({
    required this.userId,
    required this.start,
    required this.end,
  });
  final int userId;
  final DateTime? start;
  final DateTime? end;
}
