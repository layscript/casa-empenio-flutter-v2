import 'dart:async';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'perdonados_event.dart';
part 'perdonados_state.dart';

final _initialState = PerdonadosState(
  startTimePayments: DateTime.now(),
  endTimePayments: DateTime.now(),
  status: PerdonadosStatus.initial,
  listPerdonados: const [],
  message: null,
);

class PerdonadosBloc extends Bloc<PerdonadosEvent, PerdonadosState> {
  PerdonadosBloc({
    required ReportsRepository reportsRepository,
    required Preferences preferences,
  })  : _reportsRepository = reportsRepository,
        _preferences = preferences,
        super(_initialState) {
    on<GetAllPerdonados>(_onGetAllPerdonados);
  }

  final ReportsRepository _reportsRepository;
  final Preferences _preferences;

  Future<void> _onGetAllPerdonados(
    GetAllPerdonados event,
    Emitter<PerdonadosState> emit,
  ) async {
    emit(
      state.copyWith(
        startTimePayments: event.inicio,
        endTimePayments: event.fin,
        status: PerdonadosStatus.loading,
      ),
    );

    final result = await _reportsRepository.getForgivenessByRangeDate(
      inicio: event.inicio ?? state.startTimePayments,
      fin: event.fin ?? state.endTimePayments,
      usuarioId: _preferences.token?.id ?? 1,
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
    );

    result.fold(
      (error) {
        emit(
          state.copyWith(
            listPerdonados: [],
            status: PerdonadosStatus.error,
            message: error,
          ),
        );
      },
      (data) {
        emit(
          state.copyWith(
            listPerdonados: data,
            status: PerdonadosStatus.success,
          ),
        );
      },
    );
  }
}
