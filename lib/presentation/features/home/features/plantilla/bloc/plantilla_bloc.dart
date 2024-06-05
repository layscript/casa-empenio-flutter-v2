import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'plantilla_event.dart';
part 'plantilla_state.dart';

class PlantillaBloc extends Bloc<PlantillaEvent, PlantillaState> {
  PlantillaBloc({required PlantillaRepository plantillaRepository})
      : _plantillaRepository = plantillaRepository,
        super(PlantillaInitial()) {
    on<GetPlantilla>(_onGetPlantilla);
    on<GeneratePlantilla>(_onGeneratePlantilla);
  }

  final PlantillaRepository _plantillaRepository;

  FutureOr<void> _onGetPlantilla(
    GetPlantilla event,
    Emitter<PlantillaState> emit,
  ) {}

  FutureOr<void> _onGeneratePlantilla(
    GeneratePlantilla event,
    Emitter<PlantillaState> emit,
  ) {}
}
