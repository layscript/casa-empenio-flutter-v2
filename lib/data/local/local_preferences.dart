import 'package:flutter/foundation.dart' show ValueNotifier;
import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenKey = 'du18sj17';
const _loansKey = 'du1865z33';
const _refreshKey = 'fj1625z33';
const _sucursalTrabajoKey = 'sj7731tr';

/// Vista previa del administrador: mira la app como la vería otro puesto.
/// Vive solo en memoria (no se guarda): al cerrar la app o salir de la vista, vuelve a ser administrador.
class VistaPrevia {
  static UserEntity? usuario; // lo que "ve" la app mientras dura la vista previa
  static UserEntity? real; // el administrador de verdad
  static final ValueNotifier<String?> puesto = ValueNotifier<String?>(null);

  static void salir() {
    usuario = null;
    real = null;
    puesto.value = null;
  }
}

class LocalPreferences implements Preferences {
  LocalPreferences(this._preferences);
  final SharedPreferences _preferences;

  @override
  UserEntity? get token {
    if (VistaPrevia.usuario != null) return VistaPrevia.usuario;
    final userString = _preferences.getString(_tokenKey);
    if (userString != null) {
      final userMap = jsonDecode(userString) as Map<String, dynamic>;
      final user = UserEntity.userFromMap(userMap);
      // El administrador sigue en la sucursal que eligió, aunque los datos se vuelvan a leer del servidor.
      final suc = sucursalTrabajo;
      if (user.isAdmin == true && suc != null && suc.id != user.sucursal?.id) {
        return UserEntity(
          id: user.id,
          nombre: user.nombre,
          apellido: user.apellido,
          userName: user.userName,
          oldUserName: user.oldUserName,
          email: user.email,
          avatar: user.avatar,
          celular: user.celular,
          role: user.role,
          pagos: user.pagos,
          prestamos: user.prestamos,
          createdAt: user.createdAt,
          prestamosAdmin: user.prestamosAdmin,
          updatedAt: user.updatedAt,
          ventas: user.ventas,
          isAdmin: user.isAdmin,
          sucursal: suc,
        );
      }
      return user;
    }
    return null;
  }

  @override
  SucursalEntity? get sucursalTrabajo {
    final t = _preferences.getString(_sucursalTrabajoKey);
    if (t == null) return null;
    try {
      return SucursalEntity.sucursalFromMap(jsonDecode(t) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setSucursalTrabajo(SucursalEntity? value) async {
    if (value == null) {
      await _preferences.remove(_sucursalTrabajoKey);
      return;
    }
    await _preferences.setString(
      _sucursalTrabajoKey,
      jsonEncode(<String, dynamic>{
        'id': value.id,
        'nombre': value.nombre,
        'direccion': value.direccion,
        'createdAt': value.createdAt,
        'updatedAt': value.updatedAt,
        'deletedAt': value.deletedAt,
        'telefono': value.telefono,
        'extas': value.extras,
      }),
    );
  }

  @override
  Future<bool> setToken(UserEntity value) {
    final userString = jsonEncode(value.toJson());
    return _preferences.setString(_tokenKey, userString);
  }

  @override
  Future<void> removeToken() async {
    await _preferences.remove(_tokenKey);
    await _preferences.remove(_sucursalTrabajoKey);
  }

  @override
  LoansPreferencesEntity? get getLoansPreferences {
    final loansString = _preferences.getString(_loansKey);
    if (loansString != null && loansString != "null") {
      final loansMap = jsonDecode(loansString) as Map<String, dynamic>;
      final loans = LoansPreferencesEntity.fromJson(loansMap);
      return loans;
    }
    return null;
  }

  @override
  Future<void> removeLoansPreferences() => _preferences.remove(_loansKey);

  @override
  Future<bool> setLoansPreferences(LoansPreferencesEntity value) {
    final loansString = jsonEncode(value.toJson());
    return _preferences.setString(_loansKey, loansString);
  }

  @override
  bool? get refresh => _preferences.getBool(_refreshKey);

  @override
  Future<void> removeRefresh() => _preferences.remove(_refreshKey);
  @override
  Future<bool> setRefresh(bool value) =>
      _preferences.setBool(_refreshKey, value);
}
