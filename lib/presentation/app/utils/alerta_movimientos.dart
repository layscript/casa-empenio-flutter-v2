import 'dart:async';
import 'dart:convert';

import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/sesion_segura.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Avisos de dinero en el celular del administrador: cada pago, préstamo, gasto o anulación
/// que se registra en cualquier sucursal suena y se muestra como notificación.
///  - Ingresos (pago, venta, ingreso): campana tipo caja / Yape.
///  - Egresos (préstamo entregado, gasto, aumento, compra): sonido agudo descendente, "se fue".
///  - Anulaciones: tres pitidos de alerta.
/// Funciona mientras la app esté abierta o en segundo plano (el sistema operativo puede dormirla si se cierra del todo).
class AlertaMovimientos {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final Dio _dio = crearDio(BaseOptions(
    baseUrl: endPointPrincipal,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  static const _kUltimo = 'avisos_ultimo_movimiento';
  static Timer? _timer;
  static bool _lista = false;
  static bool _consultando = false;
  static int? _usuarioId;

  static Future<void> _preparar() async {
    if (_lista) return;
    await _plugin.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await a?.requestNotificationsPermission();
    for (final c in _canales.entries) {
      await a?.createNotificationChannel(AndroidNotificationChannel(
        c.value.id,
        c.value.nombre,
        description: c.value.descripcion,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(c.key),
      ));
    }
    _lista = true;
  }

  /// Empieza a escuchar. Solo para el administrador: el servidor también lo verifica con [usuarioId].
  static Future<void> iniciar(int usuarioId) async {
    _usuarioId = usuarioId;
    if (_timer != null) return;
    try {
      await _preparar();
    } catch (_) {
      return; // sin permiso o sin soporte: la app sigue normal
    }
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => revisarYa());
    revisarYa();
  }

  static void detener() {
    _timer?.cancel();
    _timer = null;
    _usuarioId = null;
  }

  /// Pregunta al servidor si hay movimientos nuevos y avisa de cada uno.
  static Future<void> revisarYa() async {
    if (_consultando || !_lista || _usuarioId == null) return;
    _consultando = true;
    try {
      final sp = await SharedPreferences.getInstance();
      final desde = sp.getInt(_kUltimo);
      final r = await _dio.get('/finanza/movimiento/recientes', queryParameters: {'usuarioId': _usuarioId, if (desde != null) 'desde': desde});
      final d = r.data is String ? jsonDecode(r.data as String) : r.data;
      final b = (d is Map ? d['body'] : null) as Map?;
      if (b == null) return;
      final ultimo = (b['ultimoId'] as num?)?.toInt() ?? 0;
      final items = ((b['items'] as List?) ?? []).whereType<Map>().toList();
      if (desde == null) {
        await sp.setInt(_kUltimo, ultimo); // primera vez: no se repite lo antiguo
        return;
      }
      if (items.isEmpty) {
        if (ultimo > desde) await sp.setInt(_kUltimo, ultimo);
        return;
      }
      if (items.length > 5) {
        // muchos de golpe (la app estuvo cerrada): un solo resumen para no llenar la pantalla
        final ingresos = items.where((m) => m['suma'] == true).fold<double>(0, (a, m) => a + _monto(m));
        final egresos = items.where((m) => m['suma'] != true).fold<double>(0, (a, m) => a + _monto(m));
        await _mostrar(
          id: 'resumen'.hashCode,
          sonido: 'ingreso',
          titulo: '${items.length} movimientos nuevos',
          cuerpo: 'Entró S/ ${ingresos.toStringAsFixed(2)} · Salió S/ ${egresos.toStringAsFixed(2)}',
        );
      } else {
        for (final m in items) {
          await _mostrar(
            id: (m['id'] as num).toInt(),
            sonido: sonidoDe(m),
            titulo: tituloDe(m),
            cuerpo: cuerpoDe(m),
          );
          await Future<void>.delayed(const Duration(milliseconds: 1200)); // para que cada sonido se oiga
        }
      }
      final ultimoVisto = (items.last['id'] as num).toInt();
      await sp.setInt(_kUltimo, items.length >= 40 ? ultimoVisto : (ultimo > ultimoVisto ? ultimo : ultimoVisto));
    } on DioException catch (e) {
      // si el servidor dice que no es administrador, se deja de escuchar
      if (e.response?.statusCode == 403) detener();
    } catch (_) {
      // sin internet o servidor ocupado: se reintenta en 10 segundos
    } finally {
      _consultando = false;
    }
  }

  static double _monto(Map m) => (m['monto'] as num?)?.toDouble() ?? 0;

  /// Qué sonido corresponde a un movimiento.
  static String sonidoDe(Map m) {
    final clase = '${m['clase']}';
    if (clase == 'ANULACION') return 'anulacion';
    return m['suma'] == true ? 'ingreso' : 'egreso';
  }

  static String tituloDe(Map m) {
    final monto = 'S/ ${_monto(m).toStringAsFixed(2)}';
    final medio = '${m['medioPago'] ?? ''}';
    final medioTxt = (medio.isEmpty || medio == 'EFECTIVO') ? '' : ' · $medio';
    switch ('${m['clase']}') {
      case 'PAGO':
        return 'Pago recibido $monto$medioTxt';
      case 'VENTA':
        return 'Venta $monto$medioTxt';
      case 'INGRESO':
        return 'Ingreso $monto$medioTxt';
      case 'PRESTAMO':
        return 'Préstamo entregado $monto';
      case 'AUMENTO':
        return 'Aumento de préstamo $monto';
      case 'COMPRA':
        return 'Compra $monto';
      case 'ANULACION':
        return 'Movimiento anulado $monto';
      default:
        return 'Gasto $monto';
    }
  }

  static String cuerpoDe(Map m) {
    final partes = <String>[
      if ('${m['sucursal'] ?? ''}'.isNotEmpty) '${m['sucursal']}',
      if ('${m['usuario'] ?? ''}'.isNotEmpty) 'por ${m['usuario']}',
      if ('${m['observaciones'] ?? ''}'.trim().isNotEmpty) '${m['observaciones']}'.trim().split('\n').first,
    ];
    return partes.isEmpty ? '${m['tipo'] ?? ''}' : partes.join(' · ');
  }

  static Future<void> _mostrar({required int id, required String sonido, required String titulo, required String cuerpo}) async {
    final c = _canales[sonido]!;
    await _plugin.show(
      id,
      titulo,
      cuerpo,
      NotificationDetails(
        android: AndroidNotificationDetails(
          c.id,
          c.nombre,
          channelDescription: c.descripcion,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(sonido),
          styleInformation: BigTextStyleInformation(cuerpo),
        ),
      ),
    );
  }

  /// Para que el administrador oiga cómo suena cada tipo.
  static Future<void> probarSonidos() async {
    await _preparar();
    await _mostrar(id: 9001, sonido: 'ingreso', titulo: 'Pago recibido S/ 150.00 · YAPE', cuerpo: 'Así suena un ingreso');
    await Future<void>.delayed(const Duration(seconds: 3));
    await _mostrar(id: 9002, sonido: 'egreso', titulo: 'Préstamo entregado S/ 500.00', cuerpo: 'Así suena un egreso');
    await Future<void>.delayed(const Duration(seconds: 3));
    await _mostrar(id: 9003, sonido: 'anulacion', titulo: 'Movimiento anulado S/ 100.00', cuerpo: 'Así suena una anulación');
  }
}

class _Canal {
  const _Canal(this.id, this.nombre, this.descripcion);
  final String id;
  final String nombre;
  final String descripcion;
}

const _canales = <String, _Canal>{
  'ingreso': _Canal('mov_ingreso_v1', 'Ingresos de dinero', 'Pagos, ventas e ingresos: suena como caja registradora'),
  'egreso': _Canal('mov_egreso_v1', 'Egresos de dinero', 'Préstamos entregados, gastos y compras: sonido agudo descendente'),
  'anulacion': _Canal('mov_anulacion_v1', 'Anulaciones', 'Movimientos anulados o eliminados: tres pitidos'),
};
