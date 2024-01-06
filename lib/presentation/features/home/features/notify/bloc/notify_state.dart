part of 'notify_bloc.dart';

enum NotifyStatus { initial, loading, error, loaded }

class NotifyState extends Equatable {
  const NotifyState({
    this.notifyStatus = NotifyStatus.initial,
    this.error,
    this.listSolicitud,
  });

  final NotifyStatus notifyStatus;
  final String? error;
  final List<SolicitudEntity>? listSolicitud;

  NotifyState copyWith({
    NotifyStatus? notifyStatus,
    List<SolicitudEntity>? listSolicitud,
    String? error,
  }) =>
      NotifyState(
        error: error ?? this.error,
        notifyStatus: notifyStatus ?? this.notifyStatus,
        listSolicitud: listSolicitud ?? this.listSolicitud,
      );

  @override
  List<Object?> get props => [
        notifyStatus,
        error,
        listSolicitud,
      ];
}
