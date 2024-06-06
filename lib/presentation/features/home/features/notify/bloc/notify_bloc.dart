import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'notify_event.dart';
part 'notify_state.dart';

class NotifyBloc extends Bloc<NotifyEvent, NotifyState> {
  NotifyBloc({required SolicitudRepository solicitudRepository})
      : _solicitudRepository = solicitudRepository,
        super(const NotifyState()) {
    on<GetSolicitudesNotify>(_onGetSolicitudesNotify);
    on<ChangeStatusSolicitudesNotify>(_onChangeStatusSolicitudesNotify);
  }

  final SolicitudRepository _solicitudRepository;

  Future<void> _onGetSolicitudesNotify(
    GetSolicitudesNotify event,
    Emitter<NotifyState> emit,
  ) async {
    emit(state.copyWith(notifyStatus: NotifyStatus.loading));
    final result = await _solicitudRepository.getSolicitudes();

    result.fold(
      (error) {
        emit(
          state.copyWith(
            notifyStatus: NotifyStatus.error,
            error: error,
          ),
        );
      },
      (listSolicitud) => emit(
        state.copyWith(
          listSolicitud: listSolicitud,
          notifyStatus: NotifyStatus.loaded,
          error: '',
        ),
      ),
    );
  }

  Future<void> _onChangeStatusSolicitudesNotify(
    ChangeStatusSolicitudesNotify event,
    Emitter<NotifyState> emit,
  ) async {
    emit(state.copyWith(notifyStatus: NotifyStatus.loading));
    final result = await _solicitudRepository.updateSolicitud(
      solicitudId: event.solicitudId,
      prestamoId: event.prestamoId,
      estado: event.estado,
      usuarioId: event.usuarioId,
    );

    result.fold((error) {
      emit(
        state.copyWith(
          notifyStatus: NotifyStatus.error,
          error: error,
        ),
      );
    }, (success) {
      emit(
        state.copyWith(
          notifyStatus: NotifyStatus.loaded,
          error: '',
        ),
      );
      add(GetSolicitudesNotify());
    });
  }
}
