import 'dart:async';

import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'plantilla_event.dart';
part 'plantilla_state.dart';

class PlantillaBloc extends Bloc<PlantillaEvent, PlantillaState> {
  PlantillaBloc({required PlantillaRepository plantillaRepository})
      : _plantillaRepository = plantillaRepository,
        super(const PlantillaState()) {
    on<GetPlantilla>(_onGetPlantilla);
    on<GeneratePlantilla>(_onGeneratePlantilla);
  }

  final PlantillaRepository _plantillaRepository;

  Future<void> _onGetPlantilla(
    GetPlantilla event,
    Emitter<PlantillaState> emit,
  ) async {
    emit(state.copyWith(status: PlantillaStatus.loading));
    try {
      final plantilla = await _plantillaRepository.getPlantilla();
      plantilla.fold(
        (error) {
          emit(state.copyWith(status: PlantillaStatus.failure, error: error));
        },
        (success) {
          emit(
            state.copyWith(
              status: PlantillaStatus.success,
              htmlContent: success,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PlantillaStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGeneratePlantilla(
    GeneratePlantilla event,
    Emitter<PlantillaState> emit,
  ) async {
    try {
      final plantilla = await _plantillaRepository.setPlantilla(event.url);
      plantilla.fold(
        (error) {
          emit(state.copyWith(status: PlantillaStatus.failure, error: error));
        },
        (success) {
          emit(
            state.copyWith(
              status: PlantillaStatus.navigate,
              htmlContent: success,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PlantillaStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }
}
