import 'package:casa_empenio_pe/presentation/app/utils/vigilante_sesion.dart';
import 'dart:async';

import 'package:casa_empenio_pe/data/local/local_preferences.dart' show VistaPrevia;
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required UserRepository userRepository,
    required Preferences preferences,
    required ModulosRepository modulosRepository,
  })  : _userRepository = userRepository,
        _preferences = preferences,
        _modulosRepository = modulosRepository,
        super(const AuthInitial()) {
    on<LogIn>(_onLogIn);
    on<SignOff>(_onSignOff);
    on<GetSession>(_onGetSession);
    on<RefreshDataUser>(_onRefreshDataUser);
    on<CambiarSucursal>(_onCambiarSucursal);
    on<VerComo>(_onVerComo);
  }

  final UserRepository _userRepository;
  final ModulosRepository _modulosRepository;
  final Preferences _preferences;
  Future<void> _onLogIn(LogIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _userRepository.logIn(
      email: event.username,
      password: event.password,
    );

    await result.fold(
      (error) async {
        if (!emit.isDone) emit(AuthError(message: error));
      },
      (user) async {
        final modules = await _modulosRepository.getAllModulos(
          limit: 100,
        );

        await modules.fold(
          (error) async {
            if (!emit.isDone) emit(AuthError(message: error));
          },
          (modulos) async {
            await _preferences.setSucursalTrabajo(null); // al iniciar sesión se empieza en la sucursal propia
            await _preferences.setToken(user);
            if (!emit.isDone) {
              emit(
                Authenticated(
                  _preferences.token ?? user,
                  modulos,
                ),
              );
            }
          },
        );
      },
    );
  }

  /// El administrador pasa a trabajar en otra sucursal sin cerrar sesión.
  /// Todo lo que haga (pagos, cajas, préstamos) queda en la sucursal elegida.
  Future<void> _onCambiarSucursal(
      CambiarSucursal event, Emitter<AuthState> emit) async {
    final u = _preferences.token;
    if (u == null || u.isAdmin != true) return;
    final nuevo = UserEntity(
      id: u.id,
      nombre: u.nombre,
      apellido: u.apellido,
      userName: u.userName,
      oldUserName: u.oldUserName,
      email: u.email,
      avatar: u.avatar,
      celular: u.celular,
      role: u.role,
      pagos: null,
      prestamos: null,
      createdAt: u.createdAt,
      prestamosAdmin: null,
      updatedAt: u.updatedAt,
      ventas: null,
      isAdmin: u.isAdmin,
      sucursal: event.sucursal,
    );
    await _preferences.setSucursalTrabajo(event.sucursal);
    await _preferences.setToken(nuevo);
    await _preferences.removeLoansPreferences();
    emit(Authenticated(_preferences.token ?? nuevo, state.modulos ?? []));
  }

  /// Vista previa: el administrador mira la app como la ve otro puesto. No se guarda ni se puede modificar nada.
  Future<void> _onVerComo(VerComo event, Emitter<AuthState> emit) async {
    final base = VistaPrevia.real ?? _preferences.token;
    if (event.rol == null) {
      VistaPrevia.salir();
      final real = _preferences.token;
      if (real != null) emit(Authenticated(real, state.modulos ?? []));
      return;
    }
    if (base == null || base.isAdmin != true) return;
    final r = event.rol!;
    final esAdminRol = const ['administrador', 'administradora', 'admin'].contains(r.nombre.toLowerCase().trim());
    VistaPrevia.real = base;
    VistaPrevia.usuario = UserEntity(
      id: base.id,
      nombre: base.nombre,
      apellido: base.apellido,
      userName: base.userName,
      oldUserName: base.oldUserName,
      email: base.email,
      avatar: base.avatar,
      celular: base.celular,
      role: r,
      pagos: null,
      prestamos: null,
      createdAt: base.createdAt,
      prestamosAdmin: null,
      updatedAt: base.updatedAt,
      ventas: null,
      isAdmin: esAdminRol,
      sucursal: base.sucursal,
    );
    VistaPrevia.puesto.value = r.nombre;
    emit(Authenticated(VistaPrevia.usuario!, state.modulos ?? []));
  }

  Future<void> _onSignOff(SignOff event, Emitter<AuthState> emit) async {
    VistaPrevia.salir();
    await _preferences.removeRefresh();
    await _preferences.removeLoansPreferences();
    await _preferences.removeToken();
    await olvidarDiaSesion();
    emit(const UnAuthenticated());
  }

  Future<void> _onGetSession(GetSession event, Emitter<AuthState> emit) async {
    await Future.delayed(const Duration(seconds: 2), () {});
    final token = _preferences.token;
    if (token == null) {
      emit(const UnAuthenticated());
    } else {
      emit(
        Authenticated(
          token,
          state.modulos ?? [],
        ),
      );
    }
  }

  Future<void> _onRefreshDataUser(
    RefreshDataUser event,
    Emitter<AuthState> emit,
  ) async {
    //emit(AuthLoading());
    //await Future.delayed(const Duration(milliseconds: 200), () {});
    if (_preferences.refresh == true) {
      final result = await _userRepository.getUser(
        id: _preferences.token?.id ?? 1,
      );

      result.fold(
        (error) async {
          // Un fallo momentáneo del servidor no debe sacar a la persona de la app:
          // se queda con su sesión actual y se vuelve a intentar después.
          final actual = _preferences.token;
          if (actual == null) {
            emit(const UnAuthenticated());
          } else {
            emit(Authenticated(actual, state.modulos ?? []));
          }
        },
        (user) async {
          await _preferences.setToken(user);
          _preferences.setRefresh(false);
          emit(
            Authenticated(
              _preferences.token ?? user,
              state.modulos ?? [],
            ),
          );
        },
      );
    }
  }
}
