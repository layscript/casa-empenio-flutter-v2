import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenKey = 'du18sj17';

class LocalPreferences implements Preferences {
  LocalPreferences(this._preferences);
  final SharedPreferences _preferences;

  @override
  UserEntity? get token {
    final userString = _preferences.getString(_tokenKey);
    if (userString != null) {
      final userMap = jsonDecode(userString) as Map<String, dynamic>;
      final user = UserEntity.fromJson(userMap);
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
}
