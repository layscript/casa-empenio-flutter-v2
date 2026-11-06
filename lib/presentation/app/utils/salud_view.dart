import 'dart:convert';
import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/actualizaciones.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================ AYUDAS
final Dio _dio = Dio(BaseOptions(
  baseUrl: endPointPrincipal,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(minutes: 5),
));

dynamic _cuerpo(Response<dynamic> r) {
  final d = r.data is String ? jsonDecode(r.data as String) : r.data;
  return d is Map ? d['body'] : null;
}

String _err(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['message'] != null) return d['message'].toString();
    return 'No hay conexión con el servidor';
  }
  return e.toString();
}

num _n(dynamic v) => v is num ? v : (num.tryParse('${v ?? ''}') ?? 0);
String _s(num v) => 'S/ ${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
String _dos(int n) => n.toString().padLeft(2, '0');

DateTime _lima(DateTime d) => d.toUtc().subtract(const Duration(hours: 5));
String _hoyLima() {
  final l = _lima(DateTime.now());
  return '${l.year}-${_dos(l.month)}-${_dos(l.day)}';
}

Map<String, dynamic> _mapa(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _lista(dynamic v) => v is List ? v.map((e) => _mapa(e)).toList() : <Map<String, dynamic>>[];

UserEntity? _usuario(BuildContext c) => c.read<Preferences>().token;

void _aviso(BuildContext c, String t, {bool error = false}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t), backgroundColor: error ? Colors.red.shade700 : null));
}

// ============================================================ ERRORES AUTOMÁTICOS DE LA APP
String? _ctxNombre;
int? _ctxId;
String? _ctxSucursal;
int _enviados = 0;
final Set<String> _vistos = {};

/// La app anota quién está trabajando para que el error diga de quién fue.
void recordarUsuarioParaErrores(UserEntity? u) {
  if (u == null) return;
  _ctxId = u.id;
  _ctxNombre = u.fullName;
  _ctxSucursal = u.sucursal?.nombre;
}

/// Manda al servidor, sin molestar a nadie, un error que salió en la app.
Future<void> reportarErrorAuto(Object error, StackTrace? stack, {String? pantalla}) async {
  try {
    if (error is DioException && error.response == null) return; // sin internet: no es un error de la app
    final msg = error.toString();
    final clave = msg.length > 150 ? msg.substring(0, 150) : msg;
    if (_vistos.contains(clave) || _enviados >= 30) return;
    _vistos.add(clave);
    _enviados++;
    await _dio.post('/salud/errores', data: {
      'mensaje': msg,
      'detalle': (stack ?? '').toString().split('\n').take(8).join('\n'),
      'ruta': pantalla ?? 'app',
      'usuarioId': _ctxId,
      'usuarioNombre': _ctxNombre,
      'sucursalNombre': _ctxSucursal,
      'version': kBuildActual > 0 ? '$kBuildActual' : 'prueba',
    });
  } catch (_) {}
}

// ============================================================ ALERTA DE CLIENTE MOROSO
final Set<String> _dnisAvisados = {};

/// Al escribir un DNI en un préstamo nuevo: si el cliente tiene mal historial en cualquier sucursal, avisa.
Future<void> revisarRiesgoCliente(BuildContext context, String dni) async {
  if (dni.length != 8 || _dnisAvisados.contains(dni)) return;
  _dnisAvisados.add(dni);
  try {
    final r = await _dio.get('/salud/cliente/$dni/riesgo');
    final d = _mapa(_cuerpo(r));
    final nivel = '${d['nivel']}';
    if (nivel == 'NINGUNO' || !context.mounted) return;
    final color = nivel == 'ALTO' ? Colors.red : (nivel == 'MEDIO' ? Colors.orange : Colors.amber.shade800);
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(nivel == 'ALTO' ? 'Cliente de RIESGO ALTO' : nivel == 'MEDIO' ? 'Cliente de riesgo medio' : 'Ojo con este cliente', style: TextStyle(color: color, fontSize: 17))),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${d['texto']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text('Préstamos en total: ${d['prestamos']}\nVencidos ahora: ${d['vencidosAhora']}\nBienes perdidos antes: ${d['perdidos']}\nMayor atraso: ${d['maxDiasVencido']} días\nDeuda pendiente: ${_s(_n(d['deudaPendiente']))}'),
            const SizedBox(height: 8),
            const Text('Se revisan TODAS las sucursales. Tú decides si prestas.', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Entendido'))],
      ),
    );
  } catch (_) {}
}

// ============================================================ PÁGINA PRINCIPAL: SALUD DEL SISTEMA
class SaludPage extends StatefulWidget {
  const SaludPage({super.key});

  @override
  State<SaludPage> createState() => _SaludPageState();
}

class _SaludPageState extends State<SaludPage> {
  Map<String, dynamic> _d = {};
  bool _cargando = true;
  bool _trabajando = false;
  String? _error;

  int get _uid => _usuario(context)?.id ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/salud/estado', queryParameters: {'usuarioId': _uid});
      _d = _mapa(_cuerpo(r));
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _copia() async {
    setState(() => _trabajando = true);
    try {
      final r = await _dio.post('/salud/respaldos', data: {'usuarioId': _uid});
      final c = _mapa(_cuerpo(r));
      if (mounted) _aviso(context, 'Copia lista: ${c['mb']} MB, ${c['filas']} registros');
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
    await _cargar();
    if (mounted) setState(() => _trabajando = false);
  }

  Future<void> _pruebas() async {
    setState(() => _trabajando = true);
    try {
      await _dio.post('/salud/pruebas', data: {'usuarioId': _uid});
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
    await _cargar();
    if (mounted) setState(() => _trabajando = false);
  }

  Future<void> _verCopias() async {
    try {
      final r = await _dio.get('/salud/respaldos', queryParameters: {'usuarioId': _uid});
      final l = _lista(_cuerpo(r));
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (c) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Copias guardadas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Toca "Bajar" para guardar una copia en tu celular o enviarla a tu correo. Así tienes otra copia fuera del servidor.', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              if (l.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Todavía no hay copias.')),
              for (final b in l)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text('${b['creadoLima']}'),
                  subtitle: Text('${b['mb']} MB', style: const TextStyle(fontSize: 11)),
                  trailing: TextButton(
                    onPressed: () => launchUrl(Uri.parse('$endPointPrincipal/salud/respaldos/${b['nombre']}/descargar?usuarioId=$_uid'), mode: LaunchMode.externalApplication),
                    child: const Text('Bajar'),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resp = _mapa(_d['respaldo']);
    final ultimo = resp['ultimo'] is Map ? _mapa(resp['ultimo']) : null;
    final pruebas = _d['pruebas'] is Map ? _mapa(_d['pruebas']) : null;
    final nuevos = _n(_d['erroresNuevos']).toInt();
    return Scaffold(
      appBar: AppBar(title: const Text('Salud del sistema')),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_cargando) const LinearProgressIndicator(),
            if (_error != null) Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
            if (_d.isNotEmpty) ...[
              Text('Hora de Lima: ${_d['horaLima']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Copia de seguridad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    if (ultimo == null)
                      const Text('Todavía no hay ninguna copia. La primera se hace sola a las 3:00 a. m. o ahora con el botón.')
                    else
                      Text('Última: ${ultimo['creadoLima']} (hace ${resp['horas']} h) · ${ultimo['mb']} MB\nCopias guardadas: ${resp['cantidad']}'),
                    const SizedBox(height: 6),
                    const Text('Se hace sola todos los días a las 3:00 a. m. (hora de Lima).', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, children: [
                      FilledButton.icon(onPressed: _trabajando ? null : _copia, icon: const Icon(Icons.save_alt), label: const Text('Hacer copia ahora')),
                      OutlinedButton.icon(onPressed: _verCopias, icon: const Icon(Icons.download), label: const Text('Ver / bajar')),
                    ]),
                  ]),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Expanded(child: Text('Pruebas automáticas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      if (pruebas != null)
                        Chip(
                          label: Text(_n(pruebas['alertas']) > 0 ? '${pruebas['alertas']} alerta(s)' : (_n(pruebas['fallaron']) > 0 ? '${pruebas['fallaron']} aviso(s)' : 'Todo bien')),
                          backgroundColor: _n(pruebas['alertas']) > 0 ? Colors.red.shade100 : (_n(pruebas['fallaron']) > 0 ? Colors.orange.shade100 : Colors.green.shade100),
                        ),
                    ]),
                    if (pruebas == null) const Text('Se corren solas todos los días a las 6:00 a. m. Toca el botón para correrlas ahora.', style: TextStyle(fontSize: 12.5)),
                    if (pruebas != null) ...[
                      Text('Última vez: ${pruebas['horaLima']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 6),
                      for (final p in _lista(pruebas['resultados']))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(p['ok'] == true ? Icons.check_circle : (p['nivel'] == 'ALERTA' ? Icons.error : Icons.warning_amber_rounded), size: 18, color: p['ok'] == true ? Colors.green : (p['nivel'] == 'ALERTA' ? Colors.red : Colors.orange)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${p['nombre']}', style: const TextStyle(fontSize: 13)),
                                if (p['ok'] != true && '${p['detalle']}'.isNotEmpty) Text('${p['detalle']}', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                              ]),
                            ),
                          ]),
                        ),
                    ],
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: _trabajando ? null : _pruebas, icon: const Icon(Icons.fact_check_outlined), label: const Text('Correr pruebas ahora')),
                  ]),
                ),
              ),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: Icon(Icons.bug_report_outlined, color: nuevos > 0 ? Colors.red : Colors.green),
                    title: const Text('Errores detectados'),
                    subtitle: Text(nuevos > 0 ? '$nuevos nuevo(s) por revisar' : 'Sin errores nuevos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ErroresPage()));
                      _cargar();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.insights, color: Colors.indigo),
                    title: const Text('Informe del dueño'),
                    subtitle: const Text('Todas las sucursales juntas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InformeDuenoPage())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.teal),
                    title: const Text('Registro de operaciones'),
                    subtitle: const Text('Para el contador y la UIF'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperacionesPage())),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================ ERRORES
class ErroresPage extends StatefulWidget {
  const ErroresPage({super.key});

  @override
  State<ErroresPage> createState() => _ErroresPageState();
}

class _ErroresPageState extends State<ErroresPage> {
  List<Map<String, dynamic>> _items = [];
  String _filtro = 'NUEVO';
  bool _cargando = true;
  String? _error;

  int get _uid => _usuario(context)?.id ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/salud/errores', queryParameters: {'usuarioId': _uid, if (_filtro != 'TODOS') 'estado': _filtro});
      _items = _lista(_mapa(_cuerpo(r))['items']);
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _estado(Map<String, dynamic> e, String estado) async {
    try {
      await _dio.put('/salud/errores/${e['id']}', data: {'usuarioId': _uid, 'estado': estado});
      if (mounted) Navigator.pop(context);
      _cargar();
    } catch (x) {
      if (mounted) _aviso(context, _err(x), error: true);
    }
  }

  String _paraClaude(Map<String, dynamic> e) =>
      'ERROR #${e['id']} (${e['origen']}) · ${e['veces']} vez/veces · última: ${e['ultimaVezLima']}\n'
      '${e['mensaje']}\nRuta/pantalla: ${e['ruta'] ?? ''}\nUsuario: ${e['usuarioNombre'] ?? ''} · ${e['sucursalNombre'] ?? ''} · versión ${e['version'] ?? ''}\n${e['detalle'] ?? ''}';

  void _detalle(Map<String, dynamic> e) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
          Text('Error #${e['id']} · ${e['origen']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('${e['mensaje']}'),
          const SizedBox(height: 8),
          Text('Pasó ${e['veces']} vez/veces. Primera: ${e['primeraVezLima']} · Última: ${e['ultimaVezLima']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if ('${e['ruta'] ?? ''}'.isNotEmpty) Text('Dónde: ${e['ruta']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (e['usuarioNombre'] != null) Text('Quién: ${e['usuarioNombre']} · ${e['sucursalNombre'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (e['version'] != null) Text('Versión de la app: ${e['version']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (e['detalle'] != null) ...[
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(8), color: Colors.grey.shade100, child: Text('${e['detalle']}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 4, children: [
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _paraClaude(e)));
                if (c.mounted) _aviso(c, 'Copiado. Pégalo en el chat con Claude para que lo corrija.');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar para Claude'),
            ),
            if (e['estado'] == 'NUEVO') OutlinedButton(onPressed: () => _estado(e, 'VISTO'), child: const Text('Ya lo vi')),
            if (e['estado'] != 'ARREGLADO') FilledButton(onPressed: () => _estado(e, 'ARREGLADO'), child: const Text('Está arreglado')),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Errores detectados')),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
            for (final f in const ['NUEVO', 'VISTO', 'ARREGLADO', 'TODOS'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f == 'NUEVO' ? 'Nuevos' : f == 'VISTO' ? 'Vistos' : f == 'ARREGLADO' ? 'Arreglados' : 'Todos'),
                  selected: _filtro == f,
                  onSelected: (_) {
                    _filtro = f;
                    _cargar();
                  },
                ),
              ),
          ]),
        ),
        if (_cargando) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargar,
            child: ListView(children: [
              if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
              if (!_cargando && _items.isEmpty && _error == null) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No hay errores aquí. 👍'))),
              for (final e in _items)
                ListTile(
                  leading: Icon(e['origen'] == 'PRUEBA' ? Icons.fact_check : (e['origen'] == 'APP' ? Icons.phone_android : Icons.dns), color: e['estado'] == 'NUEVO' ? Colors.red : Colors.grey),
                  title: Text('${e['mensaje']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                  subtitle: Text('${e['origen']} · ${e['veces']} vez/veces · ${e['ultimaVezLima']}', style: const TextStyle(fontSize: 11.5)),
                  onTap: () => _detalle(e),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ============================================================ INFORME DEL DUEÑO
class InformeDuenoPage extends StatefulWidget {
  const InformeDuenoPage({super.key});

  @override
  State<InformeDuenoPage> createState() => _InformeDuenoPageState();
}

class _InformeDuenoPageState extends State<InformeDuenoPage> {
  late String _mes;
  Map<String, dynamic> _d = {};
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mes = _hoyLima().substring(0, 7);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _mover(int delta) {
    final y = int.parse(_mes.substring(0, 4));
    final m = int.parse(_mes.substring(5, 7));
    final t = DateTime(y, m + delta, 1);
    final hoy = _hoyLima().substring(0, 7);
    final nuevo = '${t.year}-${_dos(t.month)}';
    if (nuevo.compareTo(hoy) > 0) return;
    _mes = nuevo;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/salud/informe', queryParameters: {'usuarioId': _usuario(context)?.id ?? 0, 'mes': _mes});
      _d = _mapa(_cuerpo(r));
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  static const _meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

  Widget _fila(String a, String b, {bool fuerte = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(children: [
          Expanded(child: Text(a, style: TextStyle(fontSize: 13, fontWeight: fuerte ? FontWeight.bold : FontWeight.normal))),
          Text(b, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      );

  Widget _bloque(Map<String, dynamic> f, {bool total = false}) => Card(
        color: total ? Colors.indigo.shade50 : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(total ? 'TODAS LAS SUCURSALES' : '${f['sucursal']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            _fila('Préstamos vigentes', '${f['vigentes']} · ${_s(_n(f['capitalVigente']))}'),
            _fila('Préstamos vencidos', '${f['vencidos']} · ${_s(_n(f['capitalVencido']))}', color: _n(f['vencidos']) > 0 ? Colors.red.shade700 : null),
            _fila('Morosidad (vencido / cartera)', '${_n(f['morosidadPct']).toStringAsFixed(1)} %', color: _n(f['morosidadPct']) >= 20 ? Colors.red.shade700 : null),
            const Divider(),
            _fila('Prestado este mes', '${f['nuevosMes']} · ${_s(_n(f['prestadoMes']))}'),
            _fila('Cobrado este mes', _s(_n(f['cobradoMes'])), fuerte: true),
            _fila('   de eso, intereses', _s(_n(f['interesMes']))),
            _fila('   de eso, capital recuperado', _s(_n(f['capitalRecuperadoMes']))),
            _fila('Ventas del mes', '${f['ventasMes']} · ${_s(_n(f['vendidoMes']))}'),
            const Divider(),
            _fila('Bienes perdidos (adjudicados/venta)', '${f['bienesPerdidos']} · ${_s(_n(f['capitalPerdido']))}'),
            if (!total && f['ultimaCaja'] != null) _fila('Última caja', '${f['ultimaCaja']}'),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final y = _mes.substring(0, 4);
    final m = int.parse(_mes.substring(5, 7));
    return Scaffold(
      appBar: AppBar(title: const Text('Informe del dueño')),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(onPressed: () => _mover(-1), icon: const Icon(Icons.chevron_left)),
            Text('${_meses[m - 1]} $y', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => _mover(1), icon: const Icon(Icons.chevron_right)),
          ]),
          if (_cargando) const LinearProgressIndicator(),
          if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!)),
          if (_d.isNotEmpty) ...[
            _bloque(_mapa(_d['total']), total: true),
            for (final s in _lista(_d['sucursales'])) _bloque(s),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Lo "cobrado" y "prestado" son del mes elegido. Los préstamos vigentes y vencidos son de hoy. Los números de intereses salen de cómo se registró cada pago.', style: TextStyle(fontSize: 11.5, color: Colors.black54)),
            ),
          ],
        ]),
      ),
    );
  }
}

// ============================================================ REGISTRO DE OPERACIONES
class OperacionesPage extends StatefulWidget {
  const OperacionesPage({super.key});

  @override
  State<OperacionesPage> createState() => _OperacionesPageState();
}

class _OperacionesPageState extends State<OperacionesPage> {
  late String _desde;
  late String _hasta;
  Map<String, dynamic> _d = {};
  bool _cargando = true;
  bool _bajando = false;
  String? _error;

  int get _uid => _usuario(context)?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _hasta = _hoyLima();
    _desde = '${_hasta.substring(0, 7)}-01';
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _elegir(bool desde) async {
    final base = DateTime.parse(desde ? _desde : _hasta);
    final f = await showDatePicker(context: context, initialDate: base, firstDate: DateTime(2023), lastDate: DateTime.now());
    if (f == null) return;
    final t = '${f.year}-${_dos(f.month)}-${_dos(f.day)}';
    if (desde) {
      _desde = t;
      if (_hasta.compareTo(_desde) < 0) _hasta = _desde;
    } else {
      _hasta = t;
      if (_desde.compareTo(_hasta) > 0) _desde = _hasta;
    }
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/salud/operaciones', queryParameters: {'usuarioId': _uid, 'desde': _desde, 'hasta': _hasta});
      _d = _mapa(_cuerpo(r));
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _excel() async {
    setState(() => _bajando = true);
    try {
      final r = await _dio.get<String>('/salud/operaciones/csv', queryParameters: {'usuarioId': _uid, 'desde': _desde, 'hasta': _hasta}, options: Options(responseType: ResponseType.plain));
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/operaciones_${_desde}_a_$_hasta.csv');
      await f.writeAsString(r.data ?? '');
      await OpenFile.open(f.path);
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
    if (mounted) setState(() => _bajando = false);
  }

  Future<void> _ajustes() async {
    final ctl = TextEditingController(text: _n(_d['umbral']).toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Monto alto'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Las operaciones desde este monto (S/) se marcan en naranja. Pregunta a tu contador desde qué monto debes reportar.', style: TextStyle(fontSize: 12.5)),
          const SizedBox(height: 8),
          TextField(controller: ctl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto en soles')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar'))],
      ),
    );
    if (ok != true) return;
    try {
      await _dio.put('/salud/config', data: {'usuarioId': _uid, 'umbralOperacion': num.tryParse(ctl.text.trim()) ?? 0});
      _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _lista(_d['items']);
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de operaciones'), actions: [IconButton(onPressed: _ajustes, icon: const Icon(Icons.tune), tooltip: 'Monto alto')]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _elegir(true), child: Text('Desde $_desde'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _elegir(false), child: Text('Hasta $_hasta'))),
          ]),
        ),
        if (_cargando) const LinearProgressIndicator(),
        if (_d.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              Expanded(child: Text('${_d['total']} operaciones · ${_s(_n(_d['montoTotal']))}\n${_d['altas']} de monto alto (desde ${_s(_n(_d['umbral']))})', style: const TextStyle(fontSize: 13))),
              FilledButton.icon(onPressed: _bajando ? null : _excel, icon: const Icon(Icons.table_view), label: const Text('Excel')),
            ]),
          ),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargar,
            child: ListView(children: [
              for (final o in items)
                ListTile(
                  dense: true,
                  tileColor: o['alta'] == true ? Colors.orange.shade50 : null,
                  leading: Icon(o['tipo'] == 'DESEMBOLSO' ? Icons.north_east : (o['tipo'] == 'VENTA' ? Icons.sell_outlined : Icons.south_west), color: o['alta'] == true ? Colors.deepOrange : Colors.black54),
                  title: Text('${o['tipo']} · ${o['cliente']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${o['fechaLima']} · ${o['sucursal']} · DNI ${o['dni']}', style: const TextStyle(fontSize: 11)),
                  trailing: Text(_s(_n(o['monto'])), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Aquí se muestran las 500 más recientes. El botón Excel baja TODAS las del periodo. Confirma con tu contador qué montos y qué plazos debes reportar a la UIF/SBS: este registro es la base, no reemplaza su consejo.', style: TextStyle(fontSize: 11.5, color: Colors.black54)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
