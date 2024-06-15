import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenKey = 'du18sj17';
const _loansKey = 'du1865z33';
const _refreshKey = 'fj1625z33';

class LocalPreferences implements Preferences {
  LocalPreferences(this._preferences);
  final SharedPreferences _preferences;

  @override
  UserEntity? get token {
    final userString = _preferences.getString(_tokenKey);
    if (userString != null) {
      final userMap = jsonDecode(userString) as Map<String, dynamic>;
      final user = UserEntity.userFromMap(userMap);
      return user;
    }
    return null;
  }

  @override
  Future<bool> setToken(UserEntity value) {
    final userString = jsonEncode(value.toJson());
    return _preferences.setString(_tokenKey, userString);
  }

  @override
  Future<void> removeToken() => _preferences.remove(_tokenKey);

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
