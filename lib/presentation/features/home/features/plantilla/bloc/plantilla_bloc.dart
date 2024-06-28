import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'plantilla_event.dart';
part 'plantilla_state.dart';

class PlantillaBloc extends Bloc<PlantillaEvent, PlantillaState> {
  PlantillaBloc({required PlantillaRepository plantillaRepository})
      : _plantillaRepository = plantillaRepository,
        super(const PlantillaState()) {
    on<GetPlantillas>(_onGetPlantillas);
    on<GetLastPlantilla>(_onGetLastPlantilla);
    on<GeneratePlantilla>(_onGeneratePlantilla);
    on<SelectedPlantillaByText>(_onSelectedPlantillaByText);
  }

  final PlantillaRepository _plantillaRepository;

  Future<void> _onGetPlantillas(
    GetPlantillas event,
    Emitter<PlantillaState> emit,
  ) async {
    emit(
      state.copyWith(
        dialogStatus: PlantillaStatus.loading,
        plantillaSelected: state.plantillaSelected,
      ),
    );
    try {
      final getPlantillas = await _plantillaRepository.getPlantillas();
      getPlantillas.fold(
        (error) {
          emit(
            state.copyWith(
              dialogStatus: PlantillaStatus.failure,
              error: error,
              plantillaSelected: state.plantillaSelected,
            ),
          );
        },
        (plantillas) {
          emit(
            state.copyWith(
              dialogStatus: PlantillaStatus.success,
              plantillas: plantillas,
              plantillaSelected: state.plantillaSelected,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          dialogStatus: PlantillaStatus.failure,
          error: e.toString(),
          plantillaSelected: '',
        ),
      );
    }
  }

  Future<void> _onGetLastPlantilla(
    GetLastPlantilla event,
    Emitter<PlantillaState> emit,
  ) async {
    if (state.status == PlantillaStatus.loading) return;
    emit(state.copyWith(
      status: PlantillaStatus.loading,
      plantillaSelected: '',
    ));
    try {
      final plantilla = await _plantillaRepository.getPlantilla();
      plantilla.fold(
        (error) {
          emit(
            state.copyWith(
              status: PlantillaStatus.failure,
              error: error,
              plantillaSelected: '',
            ),
          );
        },
        (success) {
          emit(
            state.copyWith(
              status: PlantillaStatus.success,
              htmlContent: success,
              plantillaSelected: success,
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
          emit(
            state.copyWith(
              status: PlantillaStatus.failure,
              error: error,
              plantillaSelected: '',
            ),
          );
        },
        (success) {
          emit(
            state.copyWith(
              status: PlantillaStatus.navigate,
              htmlContent: success,
              plantillaSelected: '',
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PlantillaStatus.failure,
          error: e.toString(),
          plantillaSelected: '',
        ),
      );
    }
  }

  Future<void> _onSelectedPlantillaByText(
    SelectedPlantillaByText event,
    Emitter<PlantillaState> emit,
  ) async {
    emit(
      state.copyWith(
        plantillaSelected: event.text,
      ),
    );
  }
}
