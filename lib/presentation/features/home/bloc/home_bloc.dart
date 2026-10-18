import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
      {required Preferences preferences,
      required UserRepository userRepository})
      : _preferences = preferences,
        _userRepository = userRepository,
        super(const HomeState()) {
    on<GoToHome>(_onGoToHome);
    on<GoToOpenCaja>(_onGoToOpenCaja);
    on<GoToPage>(_onGoToPage);
    on<GetAllModulos>(_onGetAllModulos);
  }

  final UserRepository _userRepository;
  final Preferences _preferences;

  void _onGoToHome(GoToHome event, Emitter<HomeState> emit) {
    const inicio = ModulosEntity(
      id: 19,
      nombre: 'inicio',
    );
    emit(state.copyWith(selected: inicio));
  }

  void _onGetAllModulos(
    GetAllModulos event,
    Emitter<HomeState> emit,
  ) async {
    final getUser = await _userRepository.getUser(
      id: _preferences.token?.id ?? 1,
    );
    getUser.fold(
      (e) => emit(
        state.copyWith(
          modulos: _preferences.token?.role?.modulos,
        ),
      ),
      (user) {
        _preferences.setToken(user);

        final moduloInicio =
            user.role?.modulos?.where((modulo) => modulo.id == 19).toList();

        final otrosModulos = user.role?.modulos
            ?.where(
              (modulo) =>
                  modulo.id != 19 &&
                  modulo.id != 16 &&
                  modulo.id != 17 &&
                  modulo.id != 18,
            )
            .toList();

        final modulos = [
          ...moduloInicio!,
          ...otrosModulos!,
          ..._extrasAdministrador(user, otrosModulos!),
        ];
        emit(
          state.copyWith(
            modulos: modulos,
          ),
        );
      },
    );
  }

  /// Los administradores siempre ven Administración, Auditoría y Expedientes,
  /// aunque no estén creados ni asignados como módulos en el rol.
  List<ModulosEntity> _extrasAdministrador(
    UserEntity user,
    List<ModulosEntity> actuales,
  ) {
    final esAdmin = user.isAdmin == true ||
        (user.role?.nombre ?? '').toLowerCase().contains('admin');
    if (!esAdmin) return const <ModulosEntity>[];
    bool yaEsta(String clave) =>
        actuales.any((m) => m.nombre.toLowerCase().contains(clave));
    return <ModulosEntity>[
      if (!yaEsta('administraci'))
        const ModulosEntity(id: 9001, nombre: 'Administración'),
      if (!yaEsta('auditor'))
        const ModulosEntity(id: 9002, nombre: 'Auditoría'),
      if (!yaEsta('expediente'))
        const ModulosEntity(id: 9003, nombre: 'Expedientes'),
    ];
  }

  void _onGoToPage(GoToPage event, Emitter<HomeState> emit) {
    emit(state.copyWith(selected: event.e));
  }

  void _onGoToOpenCaja(GoToOpenCaja event, Emitter<HomeState> emit) {
    const caja = ModulosEntity(
      id: 12,
      nombre: 'caja',
    );
    emit(state.copyWith(selected: caja));
  }
}
