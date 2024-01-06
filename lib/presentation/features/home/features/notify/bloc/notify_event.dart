part of 'notify_bloc.dart';

sealed class NotifyEvent extends Equatable {
  const NotifyEvent();

  @override
  List<Object> get props => [];
}

class GetSolicitudesNotify extends NotifyEvent {}

class ChangeStatusSolicitudesNotify extends NotifyEvent {
  const ChangeStatusSolicitudesNotify({
    required this.solicitudId,
    required this.prestamoId,
    required this.estado,
    required this.usuarioId,
  });

  final int solicitudId;
  final String prestamoId;
  final String estado;
  final int usuarioId;
}
