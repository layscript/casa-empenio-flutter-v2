import 'package:casa_empenio_pe/domain/domain.dart';

abstract class Preferences {
  UserEntity? get token;
  Future<bool> setToken(UserEntity value);
  Future<void> removeToken();

  LoansPreferencesEntity? get getLoansPreferences;
  Future<bool> setLoansPreferences(LoansPreferencesEntity value);
  Future<void> removeLoansPreferences();

  bool? get refresh;
  Future<bool> setRefresh(bool value);
  Future<void> removeRefresh();
}
