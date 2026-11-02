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
          ...modulosVisibles(user),
        ];
        emit(
          state.copyWith(
            modulos: modulos,
          ),
        );
      },
    );
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

/// Módulos que de verdad abren una pantalla en la app.
bool moduloFunciona(ModulosEntity m) {
  final n = m.nombre.toLowerCase();
  const claves = [
    'expediente', 'auditor', 'bitacora', 'bitácora', 'administraci',
    'recursos humanos', 'personal', 'adjudic', 'panel de sucursal',
  ];
  if (claves.any(n.contains)) return true;
  return (m.id >= 1 && m.id <= 15) || (m.id >= 9001 && m.id <= 9005);
}

/// Lista final de módulos para la pantalla de inicio y el menú:
/// quita los que no abren nada y agrega los del administrador.
List<ModulosEntity> modulosVisibles(UserEntity? user) {
  final base = (user?.role?.modulos ?? <ModulosEntity>[])
      .where((m) =>
          m.id != 19 && m.id != 16 && m.id != 17 && m.id != 18 && moduloFunciona(m))
      .toList();
  final esAdmin = user?.isAdmin == true ||
      (user?.role?.nombre ?? '').toLowerCase().contains('admin');
  if (esAdmin) {
    bool yaEsta(String clave) =>
        base.any((m) => m.nombre.toLowerCase().contains(clave));
    base.addAll(<ModulosEntity>[
      if (!yaEsta('recursos humanos') && !yaEsta('personal'))
        const ModulosEntity(id: 9005, nombre: 'Recursos Humanos'),
      if (!yaEsta('administraci'))
        const ModulosEntity(id: 9001, nombre: 'Administración'),
      if (!yaEsta('auditor') && !yaEsta('bitacora'))
        const ModulosEntity(id: 9002, nombre: 'Auditoría'),
      if (!yaEsta('expediente'))
        const ModulosEntity(id: 9003, nombre: 'Expedientes'),
      if (!yaEsta('panel de sucursal'))
        const ModulosEntity(id: 9004, nombre: 'Panel de Sucursales'),
    ]);
  }
  return base;
}
