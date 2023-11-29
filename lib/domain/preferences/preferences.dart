import 'package:casa_empenio_pe/domain/domain.dart';

abstract class Preferences {
  UserEntity? get token;
  Future<bool> setToken(UserEntity value);
  Future<void> removeToken();
}
