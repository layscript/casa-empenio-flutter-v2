import 'package:casa_empenio_pe/domain/domain.dart';

abstract class Preferences {
  User? get token;
  Future<bool> setToken(User value);
  Future<void> removeToken();
}
