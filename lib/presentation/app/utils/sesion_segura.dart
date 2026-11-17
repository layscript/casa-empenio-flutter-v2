import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pase de sesión firmado por el servidor. Se pide al iniciar sesión y se envía en todas las consultas.
class SesionSegura {
  static const _clave = 'sesion_token';
  static String? token;

  /// Sube de valor cuando el servidor dice que la sesión venció: la app cierra sesión.
  static final ValueNotifier<int> vencimientos = ValueNotifier<int>(0);

  static Future<void> cargar() async {
    try {
      token = (await SharedPreferences.getInstance()).getString(_clave);
    } catch (_) {}
  }

  static Future<void> guardar(String? valor) async {
    token = (valor == null || valor.isEmpty) ? null : valor;
    try {
      final p = await SharedPreferences.getInstance();
      if (token == null) {
        await p.remove(_clave);
      } else {
        await p.setString(_clave, token!);
      }
    } catch (_) {}
  }

  static Map<String, String> get encabezado =>
      (token == null || token!.isEmpty) ? const {} : {'x-sesion': token!};

  static void avisarVencida() => vencimientos.value++;
}

bool _esSesionVencida(DioException e) {
  if (e.response?.statusCode != 401) return false;
  try {
    final d = e.response?.data;
    final m = d is String ? json.decode(d) : d;
    return m is Map && m['code'] == 'SESION_REQUERIDA';
  } catch (_) {
    return false;
  }
}

/// Crea un Dio que envía el pase de sesión y avisa si el servidor lo rechaza.
Dio crearDio([BaseOptions? opciones]) {
  final d = Dio(opciones);
  agregarSesion(d);
  return d;
}

void agregarSesion(Dio d) {
  d.interceptors.add(InterceptorsWrapper(
    onRequest: (o, h) {
      final t = SesionSegura.token;
      if (t != null && t.isNotEmpty) o.headers['x-sesion'] = t;
      h.next(o);
    },
    onError: (e, h) {
      if (_esSesionVencida(e)) SesionSegura.avisarVencida();
      h.next(e);
    },
  ));
}
