import 'package:casa_empenio_pe/data/data.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'historial_event.dart';
part 'historial_state.dart';

final _initialState = HistorialState(
  startSales: DateTime.now().subtract(const Duration(days: 1)),
  endSales: DateTime.now(),
);

class HistorialBloc extends Bloc<HistorialEvent, HistorialState> {
  HistorialBloc({
    required UserRepository userRepository,
    required HistorialRepository historialRepository,
    required SalesRepository salesRepository,
    required Preferences preferences,
  })  : _userRepository = userRepository,
        _historialRepository = historialRepository,
        _salesRepository = salesRepository,
        _preferences = preferences,
        super(_initialState) {
    on<GetAllHistorialEvent>(_onGetAllHistorialEvent);
    on<GetHistorialByDocumentEvent>(_onGetHistorialByDocumentEvent);
    on<GetHistorialUserVentasEvent>(_onGetHistorialUserVentasEvent);
  }

  final UserRepository _userRepository;
  final HistorialRepository _historialRepository;
  final SalesRepository _salesRepository;
  final Preferences _preferences;

  Future<void> _onGetAllHistorialEvent(
    GetAllHistorialEvent event,
    Emitter<HistorialState> emit,
  ) async {
    emit(state.copyWith(historialStatus: HistorialStatus.loading));
    final result = await _userRepository.getUsers(
      limit: 100,
      offset: 0,
    );
    result.fold(
      (error) => emit(
        state.copyWith(
          historialStatus: HistorialStatus.error,
          error: error,
        ),
      ),
      (users) => emit(
        state.copyWith(
          historialStatus: HistorialStatus.loaded,
          listUsers: users,
        ),
      ),
    );
  }

  Future<void> _onGetHistorialByDocumentEvent(
    GetHistorialByDocumentEvent event,
    Emitter<HistorialState> emit,
  ) async {
    emit(state.copyWith(historialDetailsStatus: HistorialStatus.loading));

    final result = await _historialRepository.getHistorialByUser(
      userId: event.userId,
    );

    result.fold(
      (error) => emit(
        state.copyWith(
          historialDetailsStatus: HistorialStatus.error,
        ),
      ),
      (listHistorial) => emit(
        state.copyWith(
          historialDetailsStatus: HistorialStatus.loaded,
          listHistorial: listHistorial,
        ),
      ),
    );
  }

  Future<void> _onGetHistorialUserVentasEvent(
    GetHistorialUserVentasEvent event,
    Emitter<HistorialState> emit,
  ) async {
    emit(state.copyWith(historialUserVentasStatus: HistorialStatus.loading));

    final result = await _salesRepository.getSalesByUserIdRangeDate(
      userId: event.userId,
      inicio: event.start ?? state.startSales,
      fin: event.end ?? state.endSales,
      // TODO:: ID SUCURSSCAL
      sucursalId: _preferences.token?.sucursal?.id ?? 1,
    );

    result.fold(
      (error) => emit(
        state.copyWith(
          historialUserVentasStatus: HistorialStatus.error,
        ),
      ),
      (listSales) => emit(
        state.copyWith(
          historialUserVentasStatus: HistorialStatus.loaded,
          listSales: listSales,
        ),
      ),
    );
  }
}
