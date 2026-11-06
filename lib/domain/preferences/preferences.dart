import 'package:casa_empenio_pe/domain/domain.dart';

abstract class Preferences {
  UserEntity? get token;
  Future<bool> setToken(UserEntity value);
  Future<void> removeToken();

  /// Sucursal en la que el administrador está trabajando (puede ser distinta a la suya).
  /// Se mantiene aunque la app vuelva a leer sus datos del servidor.
  SucursalEntity? get sucursalTrabajo;
  Future<void> setSucursalTrabajo(SucursalEntity? value);

  LoansPreferencesEntity? get getLoansPreferences;
  Future<bool> setLoansPreferences(LoansPreferencesEntity value);
  Future<void> removeLoansPreferences();

  bool? get refresh;
  Future<bool> setRefresh(bool value);
  Future<void> removeRefresh();
}
