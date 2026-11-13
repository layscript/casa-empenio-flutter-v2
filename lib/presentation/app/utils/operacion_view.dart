import 'dart:convert';

import 'package:casa_empenio_pe/data/local/local_preferences.dart' show VistaPrevia;
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart' show AuthBloc, VerComo;
import 'package:image_picker/image_picker.dart';

// ============================================================ AYUDAS
final Dio _dio = Dio(BaseOptions(
  baseUrl: endPointPrincipal,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(minutes: 2),
))
  ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
    if (VistaPrevia.usuario != null && o.method.toUpperCase() != 'GET') {
      return h.reject(
        DioException(requestOptions: o, type: DioExceptionType.badResponse, response: Response<dynamic>(requestOptions: o, statusCode: 400, data: {'message': 'Estás en VISTA PREVIA: solo puedes mirar. Toca "Salir" en la franja naranja.'})),
        true,
      );
    }
    h.next(o);
  }));

dynamic _cuerpo(Response<dynamic> r) {
  try {
    final d = r.data is String ? jsonDecode(r.data as String) : r.data;
    if (d is Map) return d['body'];
  } catch (_) {}
  throw 'El servidor todavía no tiene esta función (se está actualizando). Espera unos minutos y vuelve a intentar.';
}

String _err(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['message'] != null) return d['message'].toString();
    return 'No hay conexión con el servidor';
  }
  return e.toString();
}

Map<String, dynamic> _mapa(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _lista(dynamic v) => v is List ? v.map((e) => _mapa(e)).toList() : <Map<String, dynamic>>[];
int _uid(BuildContext c) => c.read<Preferences>().token?.id ?? 0;
int? _sid(BuildContext c) => c.read<Preferences>().token?.sucursal?.id;

void _aviso(BuildContext c, String t, {bool error = false}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t), backgroundColor: error ? Colors.red.shade700 : null));
}

/// Abre la cámara, sube la foto y devuelve la ruta guardada (o null si cancela).
Future<String?> _tomarYSubir(BuildContext c, {bool frontal = false}) async {
  final x = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: 70,
    maxWidth: 1600,
    preferredCameraDevice: frontal ? CameraDevice.front : CameraDevice.rear,
  );
  if (x == null) return null;
  final r = await _dio.post<dynamic>('/operacion/archivo', data: FormData.fromMap({'archivo': await MultipartFile.fromFile(x.path, filename: x.name)}));
  return (_cuerpo(r) as Map)['url'].toString();
}

Widget _foto(String ruta, {double size = 90}) => Builder(
      builder: (c) => GestureDetector(
        onTap: () => showDialog<void>(context: c, builder: (_) => Dialog(child: InteractiveViewer(child: Image.network('$endPointPrincipal/$ruta')))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network('$endPointPrincipal/$ruta', width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: size * 0.6)),
        ),
      ),
    );

Color _colorSem(String s) => s == 'VERDE' ? Colors.green : s == 'AMARILLO' ? Colors.orange : s == 'ROJO' ? Colors.red : Colors.purple;

Future<bool> _fotoMasNota(BuildContext context, {required String titulo, required Future<void> Function(String? foto, String nota) enviar, bool exigeFoto = true, List<Widget> extra = const []}) async {
  String? foto;
  final nota = TextEditingController();
  String? error;
  bool ocupado = false;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dc) => StatefulBuilder(
      builder: (dc, set) => AlertDialog(
        title: Text(titulo),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            ...extra,
            if (foto != null) _foto(foto!, size: 140),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: Text(foto == null ? 'Tomar foto' : 'Cambiar foto'),
              onPressed: ocupado
                  ? null
                  : () async {
                      set(() => ocupado = true);
                      try {
                        final f = await _tomarYSubir(dc);
                        if (f != null) foto = f;
                      } catch (e) {
                        error = _err(e);
                      }
                      set(() => ocupado = false);
                    },
            ),
            TextField(controller: nota, decoration: const InputDecoration(labelText: 'Nota (opcional)'), maxLines: 2),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
          ]),
        ),
        actions: [
          TextButton(onPressed: ocupado ? null : () => Navigator.pop(dc, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: ocupado
                ? null
                : () async {
                    if (exigeFoto && foto == null) {
                      set(() => error = 'Falta la foto');
                      return;
                    }
                    set(() { ocupado = true; error = null; });
                    try {
                      await enviar(foto, nota.text.trim());
                      if (dc.mounted) Navigator.pop(dc, true);
                    } catch (e) {
                      set(() { ocupado = false; error = _err(e); });
                    }
                  },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  return ok == true;
}

// ============================================================ MI DÍA (trabajador)
class MiDiaPage extends StatefulWidget {
  const MiDiaPage({super.key});
  @override
  State<MiDiaPage> createState() => _MiDiaPageState();
}

class _MiDiaPageState extends State<MiDiaPage> {
  Map<String, dynamic>? _d;
  String? _error;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await _dio.get<dynamic>('/operacion/mi-dia', queryParameters: {'usuarioId': _uid(context)});
      if (mounted) setState(() { _d = _mapa(_cuerpo(r)); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  Future<void> _marcar(String tipo) async {
    setState(() => _ocupado = true);
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1200, preferredCameraDevice: CameraDevice.front);
      if (x == null) { setState(() => _ocupado = false); return; }
      await _dio.post<dynamic>('/operacion/asistencia', data: FormData.fromMap({'usuarioId': _uid(context), 'tipo': tipo, 'archivo': await MultipartFile.fromFile(x.path, filename: x.name)}));
      if (mounted) _aviso(context, tipo == 'ENTRADA' ? 'Entrada marcada' : 'Salida marcada');
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
    if (mounted) setState(() => _ocupado = false);
  }

  Future<void> _hacerTarea(Map<String, dynamic> t) async {
    final ok = await _fotoMasNota(context, titulo: t['nombre'].toString(), exigeFoto: t['tipo'] != 'CHECK', enviar: (f, n) async {
      await _dio.post<dynamic>('/operacion/tareas/hecha', data: {'usuarioId': _uid(context), 'plantillaId': t['id'], 'fotos': [if (f != null) f], 'nota': n});
    });
    if (ok) { if (mounted) _aviso(context, 'Tarea cumplida'); await _cargar(); }
  }

  Future<void> _prender(Map<String, dynamic> v, Map<String, dynamic>? tarea, {String resultado = 'PRENDIO'}) async {
    final ok = await _fotoMasNota(
      context,
      titulo: resultado == 'NO_ARRANCA' ? 'No arranca: ${v['codigo']}' : resultado == 'PRUEBA_CLIENTE' ? 'Prueba de cliente: ${v['codigo']}' : 'Prendido: ${v['codigo']}',
      exigeFoto: resultado != 'PRUEBA_CLIENTE',
      extra: [Text('${v['descripcion']}', style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 6)],
      enviar: (f, n) async {
        await _dio.post<dynamic>('/operacion/vehiculos/${v['id']}/prender', data: {'usuarioId': _uid(context), 'resultado': resultado, 'foto': f, 'nota': n, 'plantillaId': tarea?['id']});
      },
    );
    if (ok) { if (mounted) _aviso(context, 'Registrado'); await _cargar(); }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi día'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)]),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!, style: const TextStyle(color: Colors.red))))
          : d == null
              ? const Center(child: CircularProgressIndicator())
              : d['sinEnlace'] == true
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Tu usuario todavía no está enlazado con un trabajador.\nPídele al administrador que lo enlace (Administración → Operación → Equipo).', textAlign: TextAlign.center)))
                  : RefreshIndicator(onRefresh: _cargar, child: _cuerpoUi(d)),
    );
  }

  Widget _cuerpoUi(Map<String, dynamic> d) {
    final tr = _mapa(d['trabajador']);
    final a = d['asistencia'] == null ? null : _mapa(d['asistencia']);
    final tareas = _lista(d['tareas']);
    final sug = _lista(d['sugeridos']);
    final res = _mapa(d['resumen']);
    final tieneEntrada = a != null && a['entrada'] != null;
    final tieneSalida = a != null && a['salida'] != null;
    final vehTarea = tareas.where((t) => t['tipo'] == 'VEHICULOS' && t['estado'] != 'HECHA').toList();
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text('Hola, ${tr['nombre']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text('Hoy ${d['hoy']} · ${d['ahora']} (hora de Lima)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 10),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mi asistencia', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(tieneEntrada ? 'Entrada: ${a['entrada']}${tieneSalida ? '   Salida: ${a['salida']}' : ''}' : 'Todavía no marcaste entrada'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: FilledButton.icon(icon: const Icon(Icons.login), label: const Text('Entrada'), onPressed: _ocupado || tieneEntrada ? null : () => _marcar('ENTRADA'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.logout), label: const Text('Salida'), onPressed: _ocupado || !tieneEntrada || tieneSalida ? null : () => _marcar('SALIDA'))),
            ]),
          ]),
        ),
      ),
      if (tr['tareasDiarias'] != true)
        const Padding(padding: EdgeInsets.all(12), child: Text('No tienes tareas diarias asignadas.'))
      else ...[
        const SizedBox(height: 6),
        Text('Mis tareas: ${res['hechas']} de ${res['total']} hechas${(res['atrasadas'] ?? 0) > 0 ? ' · ${res['atrasadas']} atrasadas' : ''}', style: TextStyle(fontWeight: FontWeight.bold, color: (res['atrasadas'] ?? 0) > 0 ? Colors.red : null)),
        for (final t in tareas)
          Card(
            color: t['estado'] == 'HECHA' ? Colors.green.shade50 : t['estado'] == 'ATRASADA' ? Colors.red.shade50 : null,
            child: ListTile(
              leading: Icon(t['estado'] == 'HECHA' ? Icons.check_circle : t['estado'] == 'ATRASADA' ? Icons.warning_amber : Icons.radio_button_unchecked, color: t['estado'] == 'HECHA' ? Colors.green : t['estado'] == 'ATRASADA' ? Colors.red : Colors.grey),
              title: Text('${t['nombre']}'),
              subtitle: Text('${t['turnoNombre']} · hasta ${t['limite']}${t['tipo'] == 'VEHICULOS' ? ' · ${t['hechas']}/${t['requeridas']} vehículos' : ''}${t['descripcion'] != null ? '\n${t['descripcion']}' : ''}'),
              isThreeLine: t['descripcion'] != null,
              trailing: t['estado'] == 'HECHA' || t['tipo'] == 'VEHICULOS' ? null : IconButton(icon: Icon(t['tipo'] == 'CHECK' ? Icons.task_alt : Icons.photo_camera, color: Colors.indigo), onPressed: () => _hacerTarea(t)),
            ),
          ),
        if (sug.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('Vehículos que toca prender (los más urgentes primero)', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final v in sug)
            Card(
              child: ListTile(
                leading: v['foto'] != null ? _foto(v['foto'].toString(), size: 48) : CircleAvatar(backgroundColor: _colorSem('${v['semaforo']}'), child: const Icon(Icons.two_wheeler, color: Colors.white)),
                title: Text('${v['codigo']} · ${v['descripcion']}'),
                subtitle: Text('${v['diasTxt']}'),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (x) => _prender(v, vehTarea.isEmpty ? null : vehTarea.first, resultado: x),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'PRENDIO', child: Text('Lo prendí (foto)')),
                    PopupMenuItem(value: 'NO_ARRANCA', child: Text('No arranca (foto)')),
                    PopupMenuItem(value: 'PRUEBA_CLIENTE', child: Text('Se probó con un cliente')),
                  ],
                ),
                onTap: () => _prender(v, vehTarea.isEmpty ? null : vehTarea.first),
              ),
            ),
        ],
      ],
    ]);
  }
}

// ============================================================ ENTREGA / RECEPCIÓN DEL BIEN (dentro del préstamo)
class MovimientosBienPage extends StatefulWidget {
  const MovimientosBienPage({super.key, required this.codigo});
  final int codigo;
  @override
  State<MovimientosBienPage> createState() => _MovimientosBienPageState();
}

class _MovimientosBienPageState extends State<MovimientosBienPage> {
  List<Map<String, dynamic>>? _l;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await _dio.get<dynamic>('/operacion/movimientos-bien/prestamo/${widget.codigo}');
      if (mounted) setState(() { _l = _lista(_cuerpo(r)); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  Future<void> _nuevo(String tipo) async {
    final estado = TextEditingController();
    String? foto2;
    final ok = await _fotoMasNota(
      context,
      titulo: tipo == 'RECEPCION' ? 'Registrar recepción' : 'Registrar entrega',
      extra: [TextField(controller: estado, decoration: const InputDecoration(labelText: 'Estado del bien (ej. sin rayones, funciona)')), const SizedBox(height: 6)],
      enviar: (f, n) async {
        if (estado.text.trim().isEmpty) throw 'Describe el estado del bien';
        await _dio.post<dynamic>('/operacion/movimientos-bien', data: {'usuarioId': _uid(context), 'prestamoCodigo': widget.codigo, 'tipo': tipo, 'fotos': [f, if (foto2 != null) foto2], 'estadoBien': estado.text.trim(), 'nota': n});
      },
    );
    if (ok) { if (mounted) _aviso(context, 'Registrado en el historial'); await _cargar(); }
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    return Scaffold(
      appBar: AppBar(title: Text('Entregas · Préstamo #${widget.codigo.toString().padLeft(6, '0')}')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FloatingActionButton.extended(heroTag: 'rec', onPressed: () => _nuevo('RECEPCION'), icon: const Icon(Icons.move_to_inbox), label: const Text('Recepción')),
        const SizedBox(width: 12),
        FloatingActionButton.extended(heroTag: 'ent', onPressed: () => _nuevo('ENTREGA'), icon: const Icon(Icons.outbox), label: const Text('Entrega')),
      ]),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : l == null
              ? const Center(child: CircularProgressIndicator())
              : l.isEmpty
                  ? const Center(child: Text('Todavía no hay recepciones ni entregas.'))
                  : ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), children: [
                      for (final m in l)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${m['tipo'] == 'RECEPCION' ? 'RECEPCIÓN' : 'ENTREGA'} · ${m['horaLima']}', style: TextStyle(fontWeight: FontWeight.bold, color: m['tipo'] == 'RECEPCION' ? Colors.blue : Colors.green.shade700)),
                              Text('Por: ${m['usuarioNombre'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('Estado: ${m['estadoBien'] ?? ''}'),
                              if (m['nota'] != null) Text('Nota: ${m['nota']}'),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, runSpacing: 6, children: [for (final f in (m['fotos'] is List ? m['fotos'] as List : [])) _foto(f.toString())]),
                            ]),
                          ),
                        ),
                    ]),
    );
  }
}

// ============================================================ PANEL DEL ADMINISTRADOR
class OperacionAdminPage extends StatelessWidget {
  const OperacionAdminPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Operación diaria'),
          bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'Cumplimiento'), Tab(text: 'Equipo'), Tab(text: 'Tareas'), Tab(text: 'Vehículos')]),
        ),
        body: const TabBarView(children: [_CumplimientoTab(), _EquipoTab(), _TareasTab(), _VehiculosTab()]),
      ),
    );
  }
}

class _CumplimientoTab extends StatefulWidget {
  const _CumplimientoTab();
  @override
  State<_CumplimientoTab> createState() => _CumplimientoTabState();
}

class _CumplimientoTabState extends State<_CumplimientoTab> {
  Map<String, dynamic>? _d;
  String? _error;
  int _dias = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    try {
      final r = await _dio.get<dynamic>('/operacion/cumplimiento', queryParameters: {'usuarioId': _uid(context), 'dias': _dias});
      if (mounted) setState(() { _d = _mapa(_cuerpo(r)); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))));
    if (d == null) return const Center(child: CircularProgressIndicator());
    final tr = _lista(d['trabajadores']);
    final ev = _lista(d['evidencias']);
    final v = _mapa(d['vehiculos']);
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        Row(children: [
          const Text('Últimos '),
          DropdownButton<int>(value: _dias, items: const [7, 15, 30].map((x) => DropdownMenuItem(value: x, child: Text('$x días'))).toList(), onChanged: (x) { setState(() => _dias = x ?? 7); _cargar(); }),
          const Spacer(),
          Text('${d['desde']} → ${d['hasta']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        const Text('Solo se cuentan los días en que el trabajador marcó entrada. Esto es un aviso, no bloquea nada.', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        if (tr.isEmpty) const Text('No hay trabajadores con tareas diarias. Actívalos en la pestaña Equipo.'),
        for (final t in tr)
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: (t['pct'] ?? 0) >= 80 ? Colors.green : (t['pct'] ?? 0) >= 50 ? Colors.orange : Colors.red, child: Text('${t['pct']}%', style: const TextStyle(color: Colors.white, fontSize: 11))),
              title: Text('${t['nombre']}'),
              subtitle: Text('${t['hechas']} de ${t['esperadas']} tareas · ${t['diasTrabajados']} días${(t['atrasadasHoy'] ?? 0) > 0 ? ' · ${t['atrasadasHoy']} atrasadas hoy' : ''}'),
            ),
          ),
        const SizedBox(height: 8),
        const Text('Vehículos en exhibición', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 8, children: [
          Chip(avatar: const CircleAvatar(backgroundColor: Colors.green, radius: 6), label: Text('Al día ${v['verde']}')),
          Chip(avatar: const CircleAvatar(backgroundColor: Colors.orange, radius: 6), label: Text('Atención ${v['amarillo']}')),
          Chip(avatar: const CircleAvatar(backgroundColor: Colors.red, radius: 6), label: Text('Urgentes ${v['rojo']}')),
          Chip(avatar: const CircleAvatar(backgroundColor: Colors.purple, radius: 6), label: Text('No arrancan ${v['fallas']}')),
        ]),
        for (final u in _lista(v['urgentes'])) Text('• ${u['codigo']} ${u['descripcion']} — ${u['diasTxt']}', style: const TextStyle(fontSize: 13)),
        for (final u in _lista(v['noArrancan'])) Text('⚠ ${u['codigo']} ${u['descripcion']} no arranca', style: const TextStyle(fontSize: 13, color: Colors.purple)),
        const SizedBox(height: 10),
        const Text('Evidencias de hoy', style: TextStyle(fontWeight: FontWeight.bold)),
        if (ev.isEmpty) const Text('Aún no hay evidencias hoy.'),
        for (final e in ev)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e['hora']} · ${e['titulo']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${e['quien'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Wrap(spacing: 6, children: [for (final f in (e['fotos'] is List ? e['fotos'] as List : [])) _foto(f.toString(), size: 70)]),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _EquipoTab extends StatefulWidget {
  const _EquipoTab();
  @override
  State<_EquipoTab> createState() => _EquipoTabState();
}

class _EquipoTabState extends State<_EquipoTab> {
  Map<String, dynamic>? _d;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    try {
      final r = await _dio.get<dynamic>('/operacion/vinculos', queryParameters: {'usuarioId': _uid(context)});
      if (mounted) setState(() { _d = _mapa(_cuerpo(r)); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  Future<void> _guardar(Map<String, dynamic> t, {int? usuarioId, bool? tareas, bool quitar = false}) async {
    try {
      await _dio.put<dynamic>('/operacion/vincular', data: {'adminId': _uid(context), 'trabajadorId': t['id'], 'usuarioId': quitar ? null : (usuarioId ?? t['usuarioId']), 'tareasDiarias': tareas ?? t['tareasDiarias']});
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  Future<void> _darAcceso(Map<String, dynamic> t) async {
    final usuario = TextEditingController(text: (t['dni'] ?? '').toString());
    final clave = TextEditingController(text: (t['dni'] ?? '').toString());
    final sel = <String>{};
    String? error;
    bool ocupado = false;
    const opciones = {'ADMIN': 'Administrador (dueño, ve todo)', 'GERENTE': 'Gerente (encargado de tienda)', 'VENDEDOR': 'Vendedor', 'RECEPCION': 'Recepción', 'MANTENIMIENTO': 'Mantenimiento'};
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, set) => AlertDialog(
          title: Text('Dar acceso a ${t['nombre']}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: usuario, autocorrect: false, decoration: const InputDecoration(labelText: 'Usuario (mínimo 4 letras, sin espacios)')),
              TextField(controller: clave, decoration: const InputDecoration(labelText: 'Contraseña (mínimo 6)')),
              const SizedBox(height: 10),
              const Text('Puesto (puede tener varios si es Vendedor / Recepción / Mantenimiento):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              for (final e in opciones.entries)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.value),
                  value: sel.contains(e.key),
                  onChanged: (v) => set(() {
                    if (v == true) {
                      if (e.key == 'ADMIN' || e.key == 'GERENTE') sel.clear();
                      else { sel.remove('ADMIN'); sel.remove('GERENTE'); }
                      sel.add(e.key);
                    } else {
                      sel.remove(e.key);
                    }
                  }),
                ),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            ]),
          ),
          actions: [
            TextButton(onPressed: ocupado ? null : () => Navigator.pop(dc, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: ocupado ? null : () async {
                set(() { ocupado = true; error = null; });
                try {
                  await _dio.post<dynamic>('/operacion/dar-acceso', data: {'adminId': _uid(context), 'trabajadorId': t['id'], 'userName': usuario.text, 'password': clave.text, 'puestos': sel.toList(), 'sucursalId': t['sucursalId'] ?? _sid(context)});
                  if (dc.mounted) Navigator.pop(dc, true);
                } catch (e) {
                  set(() { ocupado = false; error = _err(e); });
                }
              },
              child: const Text('Crear acceso'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) { if (mounted) _aviso(context, 'Acceso creado. Entrégale su usuario y contraseña.'); await _cargar(); }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))));
    final d = _d;
    if (d == null) return const Center(child: CircularProgressIndicator());
    final ts = _lista(d['trabajadores']);
    final us = _lista(d['usuarios']);
    return ListView(padding: const EdgeInsets.all(12), children: [
      const Text('Solo los trabajadores registrados en Recursos Humanos pueden tener acceso a la app. Si falta alguien, primero regístralo en Recursos Humanos. Aquí le creas su usuario y se enlaza solo con su asistencia y tareas.', style: TextStyle(fontSize: 12, color: Colors.grey)),
      for (final t in ts)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${t['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (t['cargo'] != null) Text('${t['cargo']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              DropdownButton<int?>(
                isExpanded: true,
                value: us.any((u) => u['id'] == t['usuarioId']) ? t['usuarioId'] as int? : null,
                hint: const Text('Sin usuario enlazado'),
                items: [const DropdownMenuItem<int?>(value: null, child: Text('Sin usuario enlazado')), for (final u in us) DropdownMenuItem<int?>(value: u['id'] as int, child: Text('${u['nombre']} (${u['userName']})'))],
                onChanged: (x) => x == null ? _guardar(t, quitar: true) : _guardar(t, usuarioId: x),
              ),
              if (t['usuarioId'] == null) FilledButton.tonalIcon(icon: const Icon(Icons.key), label: const Text('Dar acceso a la app'), onPressed: () => _darAcceso(t)),
              SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, title: const Text('Tiene tareas diarias'), value: t['tareasDiarias'] == true, onChanged: (x) => _guardar(t, tareas: x)),
            ]),
          ),
        ),
    ]);
  }
}

const _turnos = {'APERTURA': 'Apertura', 'MANANA': 'Mañana', 'MEDIODIA': 'Mediodía', 'TARDE': 'Tarde', 'CIERRE': 'Cierre'};

class _TareasTab extends StatefulWidget {
  const _TareasTab();
  @override
  State<_TareasTab> createState() => _TareasTabState();
}

class _TareasTabState extends State<_TareasTab> {
  List<Map<String, dynamic>>? _l;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    try {
      final r = await _dio.get<dynamic>('/operacion/plantillas', queryParameters: {'usuarioId': _uid(context)});
      if (mounted) setState(() { _l = _lista(_cuerpo(r)); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  Future<void> _editar([Map<String, dynamic>? t]) async {
    final nombre = TextEditingController(text: '${t?['nombre'] ?? ''}');
    final desc = TextEditingController(text: '${t?['descripcion'] ?? ''}');
    final cant = TextEditingController(text: '${t?['cantidad'] ?? 1}');
    String turno = '${t?['turno'] ?? 'APERTURA'}';
    String tipo = '${t?['tipo'] ?? 'FOTO'}';
    bool activo = t?['activo'] != false;
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, set) => AlertDialog(
          title: Text(t == null ? 'Nueva tarea' : 'Editar tarea'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre (ej. Limpiar exhibición)')),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Detalle (opcional)')),
              DropdownButton<String>(isExpanded: true, value: turno, items: _turnos.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (x) => set(() => turno = x ?? turno)),
              DropdownButton<String>(isExpanded: true, value: tipo, items: const [DropdownMenuItem(value: 'FOTO', child: Text('Se cumple con foto')), DropdownMenuItem(value: 'CHECK', child: Text('Se cumple marcando (sin foto)')), DropdownMenuItem(value: 'VEHICULOS', child: Text('Prender vehículos'))], onChanged: (x) => set(() => tipo = x ?? tipo)),
              if (tipo == 'VEHICULOS') TextField(controller: cant, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cuántos vehículos prender')),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Activa'), value: activo, onChanged: (x) => set(() => activo = x)),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  final body = {'adminId': _uid(context), 'nombre': nombre.text, 'descripcion': desc.text, 'turno': turno, 'tipo': tipo, 'cantidad': int.tryParse(cant.text) ?? 1, 'activo': activo};
                  if (t == null) {
                    await _dio.post<dynamic>('/operacion/plantillas', data: body);
                  } else {
                    await _dio.put<dynamic>('/operacion/plantillas/${t['id']}', data: body);
                  }
                  if (dc.mounted) Navigator.pop(dc, true);
                } catch (e) {
                  set(() => error = _err(e));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))));
    final l = _l;
    if (l == null) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _editar(), icon: const Icon(Icons.add), label: const Text('Nueva tarea')),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Cargar tareas sugeridas (vendedor, recepción, mantenimiento)'),
          onPressed: () async {
            try {
              final r = _mapa(_cuerpo(await _dio.post<dynamic>('/operacion/plantillas/sugeridas', data: {'adminId': _uid(context)})));
              if (mounted) _aviso(context, 'Se agregaron ${r['creadas']} tareas. Puedes editarlas o apagarlas.');
              await _cargar();
            } catch (e) {
              if (mounted) _aviso(context, _err(e), error: true);
            }
          },
        ),
        if (l.isEmpty) const Text('Aún no hay tareas. Toca el botón de arriba para cargar un juego completo y luego ajústalo.'),
        for (final t in l)
          Card(
            child: ListTile(
              title: Text('${t['nombre']}', style: TextStyle(decoration: t['activo'] == false ? TextDecoration.lineThrough : null)),
              subtitle: Text('${_turnos[t['turno']] ?? t['turno']} · ${t['tipo'] == 'VEHICULOS' ? 'Prender ${t['cantidad']} vehículos' : t['tipo'] == 'CHECK' ? 'Se marca' : 'Con foto'}'),
              trailing: const Icon(Icons.edit),
              onTap: () => _editar(t),
            ),
          ),
      ]),
    );
  }
}

class _VehiculosTab extends StatefulWidget {
  const _VehiculosTab();
  @override
  State<_VehiculosTab> createState() => _VehiculosTabState();
}

class _VehiculosTabState extends State<_VehiculosTab> {
  Map<String, dynamic>? _d;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    try {
      final r = await _dio.get<dynamic>('/operacion/vehiculos', queryParameters: {'usuarioId': _uid(context)});
      if (mounted) setState(() { _d = _mapa(_cuerpo(r)); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  Future<void> _editar([Map<String, dynamic>? v]) async {
    final desc = TextEditingController(text: '${v?['descripcion'] ?? ''}');
    final tipo = TextEditingController(text: '${v?['tipo'] ?? ''}');
    String? foto = v?['foto']?.toString();
    String estado = '${v?['estado'] ?? 'OK'}';
    String? error;
    bool ocupado = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, set) => AlertDialog(
          title: Text(v == null ? 'Nuevo vehículo (código automático)' : 'Editar ${v['codigo']}'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Qué es (ej. Motocar rojo 2019)')),
              TextField(controller: tipo, decoration: const InputDecoration(labelText: 'Tipo (moto lineal, motocar, motor...)')),
              if (foto != null) _foto(foto!, size: 120),
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: Text(foto == null ? 'Foto de referencia' : 'Cambiar foto'),
                onPressed: ocupado ? null : () async {
                  set(() => ocupado = true);
                  try { final f = await _tomarYSubir(dc); if (f != null) foto = f; } catch (e) { error = _err(e); }
                  set(() => ocupado = false);
                },
              ),
              if (v != null) DropdownButton<String>(isExpanded: true, value: estado, items: const [DropdownMenuItem(value: 'OK', child: Text('Funciona')), DropdownMenuItem(value: 'NO_ARRANCA', child: Text('No arranca'))], onChanged: (x) => set(() => estado = x ?? estado)),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            ]),
          ),
          actions: [
            if (v != null) TextButton(onPressed: () async { try { await _dio.put<dynamic>('/operacion/vehiculos/${v['id']}', data: {'adminId': _uid(context), 'activo': false}); if (dc.mounted) Navigator.pop(dc, true); } catch (e) { set(() => error = _err(e)); } }, child: const Text('Dar de baja', style: TextStyle(color: Colors.red))),
            TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: ocupado ? null : () async {
                try {
                  final body = {'adminId': _uid(context), 'descripcion': desc.text, 'tipo': tipo.text, 'foto': foto, 'estado': estado, 'sucursalId': v == null ? _sid(context) : v['sucursalId']};
                  if (v == null) { await _dio.post<dynamic>('/operacion/vehiculos', data: body); } else { await _dio.put<dynamic>('/operacion/vehiculos/${v['id']}', data: body); }
                  if (dc.mounted) Navigator.pop(dc, true);
                } catch (e) { set(() => error = _err(e)); }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))));
    final d = _d;
    if (d == null) return const Center(child: CircularProgressIndicator());
    final items = _lista(d['items']);
    final r = _mapa(d['resumen']);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _editar(), icon: const Icon(Icons.add), label: const Text('Nuevo vehículo')),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), children: [
        Text('${r['total']} vehículos · prendidos hoy: ${r['prendidosHoy']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        if (items.isEmpty) const Text('Aún no registraste vehículos. Toca "Nuevo vehículo": el código (EXH-001...) se pone solo.'),
        for (final v in items)
          Card(
            child: ListTile(
              leading: v['foto'] != null ? _foto(v['foto'].toString(), size: 48) : CircleAvatar(backgroundColor: _colorSem('${v['semaforo']}'), child: const Icon(Icons.two_wheeler, color: Colors.white)),
              title: Text('${v['codigo']} · ${v['descripcion']}'),
              subtitle: Text('${v['estado'] == 'NO_ARRANCA' ? 'NO ARRANCA · ' : ''}${v['diasTxt']}'),
              trailing: Icon(Icons.circle, color: _colorSem('${v['semaforo']}'), size: 16),
              onTap: () => _editar(v),
            ),
          ),
      ]),
    );
  }
}


// ============================================================ AVISOS DEL GERENTE (solo administrador)
class AvisosGerentePage extends StatefulWidget {
  const AvisosGerentePage({super.key});
  @override
  State<AvisosGerentePage> createState() => _AvisosGerentePageState();
}

class _AvisosGerentePageState extends State<AvisosGerentePage> {
  Map<String, dynamic>? _d;
  List<Map<String, dynamic>> _puestos = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Options _op() => Options(headers: {'x-usuario-id': _uid(context).toString()});

  Future<void> _cargar() async {
    try {
      final a = await _dio.get<dynamic>('/acceso/avisos', options: _op());
      final p = await _dio.get<dynamic>('/acceso/autonomia', options: _op());
      if (mounted) setState(() { _d = _mapa(_cuerpo(a)); _puestos = _lista(_cuerpo(p)); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  Future<void> _visto() async {
    try {
      await _dio.put<dynamic>('/acceso/avisos/visto', options: _op());
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  Future<void> _cambiar(Map<String, dynamic> p, bool v) async {
    try {
      await _dio.put<dynamic>('/acceso/autonomia/${p['id']}', data: {'activo': v}, options: _op());
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    final items = d == null ? <Map<String, dynamic>>[] : _lista(d['items']);
    return Scaffold(
      appBar: AppBar(title: const Text('Acciones del gerente'), actions: [if (d != null && (d['nuevos'] ?? 0) > 0) TextButton(onPressed: _visto, child: const Text('Marcar vistos'))]),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))))
          : d == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(padding: const EdgeInsets.all(12), children: [
                    const Text('¿Qué puestos pueden actuar por su cuenta?', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Si activas un puesto (ej. Gerente), cuando el sistema le bloquee una acción podrá hacerla igual escribiendo un motivo. Dura 15 minutos y una sola vez, queda registrado y te aparece aquí.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    for (final p in _puestos) SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text('${p['nombre']}'), value: p['autonomo'] == true, onChanged: (v) => _cambiar(p, v)),
                    const Divider(),
                    Text('Lo que hicieron sin esperarte (${d['nuevos']} nuevos)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (items.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Nadie ha actuado por su cuenta todavía.')),
                    for (final x in items)
                      Card(
                        color: x['nuevo'] == true ? Colors.orange.shade50 : null,
                        child: ListTile(
                          leading: Icon(Icons.shield_moon_outlined, color: x['nuevo'] == true ? Colors.deepOrange : Colors.grey),
                          title: Text('${x['usuario']} (${x['rol'] ?? ''})'),
                          subtitle: Text('Quiso: ${x['accion']} en ${x['moduloNombre']}\nMotivo: ${x['motivo'] ?? ''}\n${x['fecha']}'),
                          isThreeLine: true,
                        ),
                      ),
                  ]),
                ),
    );
  }
}

/// Opción del menú para el administrador, con globo rojo si hay avisos nuevos.
class AvisosGerenteTile extends StatefulWidget {
  const AvisosGerenteTile({super.key});
  @override
  State<AvisosGerenteTile> createState() => _AvisosGerenteTileState();
}

class _AvisosGerenteTileState extends State<AvisosGerenteTile> {
  int _n = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final r = await _dio.get<dynamic>('/acceso/avisos', options: Options(headers: {'x-usuario-id': _uid(context).toString()}));
        if (mounted) setState(() => _n = (_mapa(_cuerpo(r))['nuevos'] as num?)?.toInt() ?? 0);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Badge(isLabelVisible: _n > 0, label: Text('$_n'), child: const Icon(Icons.gavel_outlined, color: Colors.deepOrange)),
      title: const Text('Acciones del gerente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(_n > 0 ? '$_n aviso(s) nuevo(s): lo que hicieron sin esperarte' : 'Lo que hicieron sin esperarte y con qué motivo', style: const TextStyle(fontSize: 11)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AvisosGerentePage()));
      },
    );
  }
}

// ============================================================ ¿QUÉ VE CADA PUESTO? (solo administrador)
class QueVeCadaPuestoPage extends StatefulWidget {
  const QueVeCadaPuestoPage({super.key});
  @override
  State<QueVeCadaPuestoPage> createState() => _QueVeCadaPuestoPageState();
}

class _QueVeCadaPuestoPageState extends State<QueVeCadaPuestoPage> {
  Map<String, dynamic>? _d;
  String? _error;
  int? _sel;

  Options _op() => Options(headers: {'x-usuario-id': _uid(context).toString()});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    try {
      final r = await _dio.get<dynamic>('/acceso/resumen', options: _op());
      if (mounted) setState(() { _d = _mapa(_cuerpo(r)); _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  Future<void> _encender() async {
    try {
      await _dio.put<dynamic>('/acceso/estado', data: {'activo': true}, options: _op());
      if (mounted) _aviso(context, 'Bloqueos encendidos');
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      appBar: AppBar(title: const Text('¿Qué ve cada puesto?')),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red))))
          : d == null
              ? const Center(child: CircularProgressIndicator())
              : _cuerpoUi(d),
    );
  }

  Widget _cuerpoUi(Map<String, dynamic> d) {
    final modulos = _lista(d['modulos']);
    final puestos = _lista(d['puestos']);
    if (puestos.isEmpty) return const Center(child: Text('No hay puestos creados.'));
    final p = puestos.firstWhere((x) => x['id'] == _sel, orElse: () => puestos.first);
    final ids = (p['modulosIds'] is List ? p['modulosIds'] as List : []).map((e) => (e as num).toInt()).toSet();
    final bloqueos = _lista(p['bloqueos']);
    final personas = (p['personas'] is List ? p['personas'] as List : []).map((e) => e.toString()).toList();
    final ve = modulos.where((m) => ids.contains((m['id'] as num).toInt())).toList();
    final noVe = modulos.where((m) => !ids.contains((m['id'] as num).toInt())).toList();
    return ListView(padding: const EdgeInsets.all(12), children: [
      if (d['restriccionesActivas'] != true)
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ojo: los bloqueos están APAGADOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              const Text('Mientras estén apagados, nadie queda limitado para crear, editar, eliminar o anular. Solo funciona lo de "qué módulos ve" cada puesto.', style: TextStyle(fontSize: 12)),
              TextButton(onPressed: _encender, child: const Text('Encender los bloqueos')),
            ]),
          ),
        ),
      FilledButton.icon(
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Asignar según sus funciones y ordenar'),
        onPressed: () async {
          final seguro = await showDialog<bool>(
            context: context,
            builder: (dc) => AlertDialog(
              title: const Text('¿Asignar y ordenar?'),
              content: const Text('Crea los puestos que falten (Vendedor, Recepción, Mantenimiento y sus combinaciones) y les pone los módulos que corresponden a sus funciones. NO cambia los puestos que ya tienen módulos. Luego ordena de más a menos módulos: Administrador, Gerente y el resto.'),
              actions: [TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dc, true), child: const Text('Sí, hacerlo'))],
            ),
          );
          if (seguro != true) return;
          try {
            final r = _mapa(_cuerpo(await _dio.post<dynamic>('/operacion/configurar-puestos', data: {'adminId': _uid(context)})));
            final sin = (r['sinCoincidencia'] is List ? r['sinCoincidencia'] as List : []);
            if (mounted) _aviso(context, sin.isEmpty ? 'Listo. Revisa abajo y corrige lo que falte.' : 'Listo, pero a ${sin.join(', ')} no le encontré módulos por nombre: asígnalos en Administración → Puestos y módulos.');
            await _cargar();
          } catch (e) {
            if (mounted) _aviso(context, _err(e), error: true);
          }
        },
      ),
      const SizedBox(height: 8),
      const Text('Los puestos se muestran de arriba (más módulos) hacia abajo (menos). Toca uno para ver el detalle:', style: TextStyle(fontSize: 13)),
      Wrap(spacing: 6, children: [for (final x in puestos) ChoiceChip(label: Text('${x['nombre']}'), selected: x['id'] == p['id'], onSelected: (_) => setState(() => _sel = (x['id'] as num).toInt()))]),
      const SizedBox(height: 10),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p['nombre']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(personas.isEmpty ? 'Nadie tiene este puesto todavía' : 'Lo tienen: ${personas.join(', ')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            if (p['esAdmin'] == true) const Text('Es administrador: ve y puede hacer TODO.', style: TextStyle(fontWeight: FontWeight.w600)),
            if (p['esAdmin'] != true && p['autonomo'] == true)
              const Text('Si le bloquean algo, puede hacerlo igual escribiendo un motivo. Tú recibes el aviso.', style: TextStyle(color: Colors.deepOrange, fontSize: 13)),
            const SizedBox(height: 8),
            Text('✅ VE (${ve.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            Wrap(spacing: 6, runSpacing: 2, children: [for (final m in ve) Chip(visualDensity: VisualDensity.compact, label: Text('${m['nombre']}', style: const TextStyle(fontSize: 12)), backgroundColor: Colors.green.shade50)]),
            if (ve.isEmpty) const Text('No ve ningún módulo', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Text('🚫 NO VE (${noVe.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Wrap(spacing: 6, runSpacing: 2, children: [for (final m in noVe) Chip(visualDensity: VisualDensity.compact, label: Text('${m['nombre']}', style: const TextStyle(fontSize: 12, color: Colors.grey)))]),
            const SizedBox(height: 8),
            Text('✋ NO PUEDE HACER (${bloqueos.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            if (bloqueos.isEmpty) Text(p['esAdmin'] == true ? 'Nada: es administrador.' : 'No tiene ninguna acción bloqueada (puede crear, editar, eliminar y anular en lo que ve).', style: const TextStyle(fontSize: 12)),
            Wrap(spacing: 6, runSpacing: 2, children: [for (final b in bloqueos) Chip(visualDensity: VisualDensity.compact, label: Text('${b['accion']} en ${b['modulo']}', style: const TextStyle(fontSize: 12)), backgroundColor: Colors.red.shade50)]),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      const Text('Comparar todos los puestos', style: TextStyle(fontWeight: FontWeight.bold)),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 14,
          headingRowHeight: 40,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          columns: [const DataColumn(label: Text('Módulo')), for (final x in puestos) DataColumn(label: Text('${x['nombre']}', style: const TextStyle(fontSize: 12)))],
          rows: [
            for (final m in modulos)
              DataRow(cells: [
                DataCell(Text('${m['nombre']}', style: const TextStyle(fontSize: 12))),
                for (final x in puestos) DataCell(Center(child: (x['modulosIds'] is List && (x['modulosIds'] as List).any((e) => (e as num).toInt() == (m['id'] as num).toInt())) ? const Icon(Icons.check_circle, color: Colors.green, size: 18) : const Icon(Icons.remove, color: Colors.grey, size: 18))),
              ]),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const Text('Para cambiar lo que ve un puesto: Administración → Puestos y módulos. Para bloquear acciones: Administración → Permisos.', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}

class QueVeCadaPuestoTile extends StatelessWidget {
  const QueVeCadaPuestoTile({super.key});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.visibility_outlined, color: Colors.blueGrey),
      title: const Text('¿Qué ve cada puesto?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: const Text('Resumen fácil de lo que ve y no puede hacer cada uno', style: TextStyle(fontSize: 11)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QueVeCadaPuestoPage()));
      },
    );
  }
}


// ============================================================ VER LA APP COMO OTRO PUESTO (solo administrador)
class VerComoTile extends StatelessWidget {
  const VerComoTile({super.key});

  Future<void> _elegir(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final nav = Navigator.of(context);
    nav.pop(); // cierra el menú
    final ctx = nav.context;
    List<Map<String, dynamic>> roles = [];
    try {
      final r = await _dio.get<dynamic>('/auth/roles', queryParameters: {'limit': 200, 'offset': 0});
      dynamic b = r.data is Map ? (r.data as Map)['body'] : r.data;
      if (b is List && b.isNotEmpty && b.first is List) b = b.first;
      roles = _lista(b);
    } catch (e) {
      if (ctx.mounted) _aviso(ctx, _err(e), error: true);
      return;
    }
    if (!ctx.mounted) return;
    final elegido = await showModalBottomSheet<Map<String, dynamic>>(
      context: ctx,
      showDragHandle: true,
      builder: (sc) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          const Text('Ver la app como…', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Verás exactamente los módulos de ese puesto. Solo es para mirar: no se guarda nada. Para salir, toca "Salir" en la franja naranja.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          for (final r in roles)
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text('${r['nombre']}'),
              subtitle: Text('${(r['modulos'] is List ? (r['modulos'] as List).length : 0)} módulos'),
              onTap: () => Navigator.pop(sc, r),
            ),
        ]),
      ),
    );
    if (elegido == null) return;
    bloc.add(VerComo(RoleEntity.roleFromMap(elegido)));
    if (ctx.mounted) Navigator.of(ctx).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: VistaPrevia.puesto,
      builder: (c, puesto, _) => ListTile(
        leading: const Icon(Icons.switch_account_outlined, color: Colors.deepOrange),
        title: const Text('Ver la app como otro puesto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(puesto == null ? 'Gerente, cajero, vendedor… ve lo que ellos ven' : 'Ahora ves como: $puesto', style: const TextStyle(fontSize: 11)),
        onTap: () => _elegir(c),
      ),
    );
  }
}


// ============================================================ TIENDA Y ALMACÉN (vendedor: consultar y cuidar; sin vender)
String _soles(dynamic v) {
  if (v == null) return '—';
  final n = (v as num).toDouble();
  final partes = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2).split('.');
  final ent = partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return 'S/ ${partes.length > 1 ? '$ent.${partes[1]}' : ent}';
}

Color _colorBien(String s) => s == 'FALLA' ? Colors.purple : s == 'ROJO' ? Colors.red : s == 'AMARILLO' ? Colors.orange : Colors.green;

class TiendaTile extends StatefulWidget {
  const TiendaTile({super.key});
  @override
  State<TiendaTile> createState() => _TiendaTileState();
}

class _TiendaTileState extends State<TiendaTile> {
  int _n = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final r = await _dio.get<dynamic>('/operacion/tienda/resumen', queryParameters: {'usuarioId': _uid(context)});
        final m = _mapa(_cuerpo(r));
        if (mounted) setState(() => _n = ((m['pendientes'] as num?)?.toInt() ?? 0) + ((m['fallasTienda'] as num?)?.toInt() ?? 0));
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.storefront_outlined, color: Colors.deepOrange),
      title: const Text('Tienda y almacén', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: const Text('Mi lista, precios, prender, limpiar y fallas', style: TextStyle(fontSize: 11)),
      trailing: _n > 0 ? CircleAvatar(radius: 11, backgroundColor: Colors.red, child: Text('$_n', style: const TextStyle(color: Colors.white, fontSize: 11))) : null,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TiendaPage()));
      },
    );
  }
}

class TiendaPage extends StatefulWidget {
  const TiendaPage({super.key, this.initialTab = 0});

  /// 0 = Mi lista, 1 = A la venta (buscador con filtros), 2 = Mapa.
  final int initialTab;
  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

/// Zonas ya usadas en la tienda (para sugerirlas al ubicar un bien).
List<String> _zonasConocidas = [];

class _TiendaPageState extends State<TiendaPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _esGerente = false;
  Map<String, dynamic> _resumen = {};
  List<Map<String, dynamic>> _mia = [];
  List<Map<String, dynamic>> _venta = [];
  List<Map<String, dynamic>> _fallas = [];
  List<Map<String, dynamic>> _grupos = [];
  List<Map<String, dynamic>> _zonas = [];
  List<Map<String, dynamic>> _zonasMapa = [];
  int _sinUbicar = 0;
  int _sinUbicarMapa = 0;
  int _totalVenta = 0;
  String _grupo = '';
  String _zona = '';
  String _color = '';
  String _marca = '';
  List<Map<String, dynamic>> _colores = [];
  List<Map<String, dynamic>> _marcas = [];
  String _grupoMia = '';
  bool _compacto = true;
  bool _modoSel = false;
  final Set<int> _sel = {};
  bool _cargando = true;
  String? _error;
  final _codigo = TextEditingController();
  final _buscar = TextEditingController();
  bool _agregando = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this, initialIndex: widget.initialTab.clamp(0, 3));
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _tab.dispose();
    _codigo.dispose();
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final uid = _uid(context);
      final rl = _mapa(_cuerpo(await _dio.get<dynamic>('/operacion/tienda/lista', queryParameters: {'usuarioId': uid})));
      _mia = _lista(rl['items']);
      final rr = _mapa(_cuerpo(await _dio.get<dynamic>('/operacion/tienda/resumen', queryParameters: {'usuarioId': uid})));
      _resumen = _mapa(rl['resumen']);
      _esGerente = rr['esGerente'] == true;
      if (_esGerente) {
        final rf = _mapa(_cuerpo(await _dio.get<dynamic>('/operacion/tienda/fallas', queryParameters: {'usuarioId': uid})));
        _fallas = _lista(rf['items']);
      }
      await _buscarVenta(sinCargando: true);
      await _cargarMapa();
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  /// Foto general de la tienda por zonas (sin filtros), para la pestaña Mapa.
  Future<void> _cargarMapa() async {
    try {
      final r = _mapa(_cuerpo(await _dio.get<dynamic>('/operacion/tienda/catalogo', queryParameters: {'usuarioId': _uid(context), 'limit': 1})));
      _zonasMapa = _lista(r['zonas']);
      _sinUbicarMapa = (r['sinUbicar'] as num?)?.toInt() ?? 0;
      _zonasConocidas = [for (final z in (r['todasZonas'] is List ? r['todasZonas'] as List : const [])) z.toString()];
    } catch (_) {}
  }

  Future<void> _buscarVenta({bool sinCargando = false}) async {
    try {
      final r = _mapa(_cuerpo(await _dio.get<dynamic>('/operacion/tienda/catalogo', queryParameters: {'usuarioId': _uid(context), 'q': _buscar.text.trim(), 'grupo': _grupo, 'zona': _zona, 'color': _color, 'marca': _marca, 'limit': 150})));
      _venta = _lista(r['items']);
      _totalVenta = (r['total'] as num?)?.toInt() ?? _venta.length;
      _grupos = _lista(r['grupos']);
      _zonas = _lista(r['zonas']);
      _colores = _lista(r['colores']);
      _marcas = _lista(r['marcas']);
      _sinUbicar = (r['sinUbicar'] as num?)?.toInt() ?? 0;
      if (!sinCargando && mounted) setState(() {});
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  Future<void> _agregarPorCodigo() async {
    final t = _codigo.text.trim();
    if (t.isEmpty) return;
    setState(() => _agregando = true);
    try {
      final r = _mapa(_cuerpo(await _dio.post<dynamic>('/operacion/tienda/lista', data: {'usuarioId': _uid(context), 'codigo': t})));
      if (r['agregado'] == false && r['candidatos'] is List) {
        final cands = _lista(r['candidatos']);
        if (!mounted) return;
        final elegido = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (dc) => SimpleDialog(
            title: const Text('Hay varios, ¿cuál es?'),
            children: [for (final c in cands) SimpleDialogOption(onPressed: () => Navigator.pop(dc, c), child: Text('${c['codigo']} · ${c['descripcion']}'))],
          ),
        );
        if (elegido != null && mounted) {
          await _dio.post<dynamic>('/operacion/tienda/lista', data: {'usuarioId': _uid(context), 'bienId': elegido['id']});
        }
      } else if (r['yaEstaba'] == true && mounted) {
        _aviso(context, 'Ya estaba en tu lista');
      } else if (mounted) {
        _aviso(context, 'Agregado: ${_mapa(r['item'])['descripcion'] ?? ''}');
      }
      _codigo.clear();
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
    if (mounted) setState(() => _agregando = false);
  }

  Future<void> _agregarTodo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        title: const Text('Agregar todo lo que está a la venta'),
        content: const Text('Se agrega a tu lista todo lo que hay a la venta en tu sucursal. Después puedes quitar lo que no está a tu cargo.'),
        actions: [TextButton(onPressed: () => Navigator.pop(dc, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dc, true), child: const Text('Agregar todo'))],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final r = _mapa(_cuerpo(await _dio.post<dynamic>('/operacion/tienda/lista/todo', data: {'usuarioId': _uid(context), 'sucursalId': _sid(context)})));
      if (mounted) _aviso(context, 'Se agregaron ${r['agregados']} (ya estaban ${r['yaEstaban']})');
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  Future<void> _abrir(Map<String, dynamic> b) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _BienPage(bienId: (b['id'] as num).toInt())));
    if (mounted) _cargar();
  }

  /// Pide la zona y la guarda para uno o varios bienes.
  Future<void> _ubicarVarios(List<int> ids) async {
    final ok = await _pedirUbicacion(context, ids, null);
    if (ok == true && mounted) {
      setState(() {
        _modoSel = false;
        _sel.clear();
      });
      await _cargar();
    }
  }

  Widget _chip(String t, Color c) => Container(
        margin: const EdgeInsets.only(right: 6, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.5))),
        child: Text(t, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
      );

  String _ubic(Map<String, dynamic> b) {
    final u = b['ubicacion'];
    if (u is! Map) return '';
    final d = (u['detalle'] ?? '').toString();
    return '${u['zona']}${d.isEmpty ? '' : ' · $d'}';
  }

  /// Fila corta para ver mucho de un vistazo.
  Widget _fila(Map<String, dynamic> b, {bool conAgregar = false, bool seleccionable = false}) {
    final sem = (b['semaforo'] ?? 'VERDE').toString();
    final id = (b['id'] as num).toInt();
    final ub = _ubic(b);
    return InkWell(
      onTap: seleccionable ? () => setState(() => _sel.contains(id) ? _sel.remove(id) : _sel.add(id)) : () => _abrir(b),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(children: [
          if (seleccionable) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(_sel.contains(id) ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.blue)),
          Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: _colorBien(sem), shape: BoxShape.circle)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${b['codigo']}${(b['placa'] ?? '').toString().isNotEmpty ? ' · ${b['placa']}' : ''}${(b['codigoAnterior'] ?? '').toString().isNotEmpty ? ' · ant. ${b['codigoAnterior']}' : ''}', style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
              Text('${b['descripcion'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              Text(ub.isEmpty ? '📍 sin ubicar' : '📍 $ub', style: TextStyle(fontSize: 11, color: ub.isEmpty ? Colors.orange : Colors.blueGrey)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(b['precioVenta'] != null ? _soles(b['precioVenta']) : 'sin precio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: b['precioVenta'] != null ? const Color(0xFF1B5E20) : Colors.orange)),
            if (b['falla'] != null) const Text('FALLA', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.w700)),
          ]),
          if (conAgregar && !seleccionable)
            b['enMiLista'] == true
                ? const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.check_circle, color: Colors.green, size: 22))
                : IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Agregar a mi lista',
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    onPressed: () async {
                      try {
                        await _dio.post<dynamic>('/operacion/tienda/lista', data: {'usuarioId': _uid(context), 'bienId': b['id']});
                        await _cargar();
                      } catch (e) {
                        if (mounted) _aviso(context, _err(e), error: true);
                      }
                    },
                  ),
        ]),
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> b, {bool conAgregar = false}) {
    final pend = _lista(b['pendientes']);
    final sem = (b['semaforo'] ?? 'VERDE').toString();
    final foto = (b['imagen'] ?? '').toString();
    final ub = _ubic(b);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _colorBien(sem).withOpacity(0.6), width: 1.2)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrir(b),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: foto.isEmpty
                  ? Container(width: 70, height: 70, color: Colors.grey.shade200, child: Icon(b['esVehiculo'] == true ? Icons.two_wheeler : Icons.inventory_2_outlined, color: Colors.grey))
                  : Image.network('$endPointPrincipal/$foto', width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${b['codigo']}${(b['placa'] ?? '').toString().isNotEmpty ? '  ·  ${b['placa']}' : ''}${(b['codigoAnterior'] ?? '').toString().isNotEmpty ? '  ·  ant. ${b['codigoAnterior']}' : ''}', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                Text('${b['descripcion'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                if (b['precioVenta'] != null)
                  Text(_soles(b['precioVenta']), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)))
                else
                  const Text('Sin precio todavía', style: TextStyle(fontSize: 12, color: Colors.orange)),
                if (b['precioMinimo'] != null || b['precioMaximo'] != null)
                  Text('Mín ${_soles(b['precioMinimo'])}  ·  Máx ${_soles(b['precioMaximo'])}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                Text(ub.isEmpty ? '📍 sin ubicar' : '📍 $ub', style: TextStyle(fontSize: 12, color: ub.isEmpty ? Colors.orange : Colors.blueGrey, fontWeight: FontWeight.w600)),
                Wrap(children: [
                  if (b['falla'] != null) _chip('FALLA', Colors.purple),
                  for (final p in pend.where((p) => p['cuidado'] != 'FALLA')) _chip('${p['texto']}${p['dias'] == null ? ' (nunca)' : ' · ${p['dias']} d'}', p['estado'] == 'ATRASADO' ? Colors.red : Colors.orange),
                  if (pend.isEmpty && b['falla'] == null) _chip('Al día', Colors.green),
                ]),
              ]),
            ),
            if (conAgregar)
              b['enMiLista'] == true
                  ? const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.check_circle, color: Colors.green))
                  : IconButton(
                      tooltip: 'Agregar a mi lista',
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      onPressed: () async {
                        try {
                          await _dio.post<dynamic>('/operacion/tienda/lista', data: {'usuarioId': _uid(context), 'bienId': b['id']});
                          await _cargar();
                        } catch (e) {
                          if (mounted) _aviso(context, _err(e), error: true);
                        }
                      },
                    ),
          ]),
        ),
      ),
    );
  }

  Widget _resumenFila() {
    Widget n(String t, dynamic v, Color c) => Expanded(
          child: Column(children: [Text('${v ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)), Text(t, style: const TextStyle(fontSize: 11, color: Colors.black54))]),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(children: [n('Atrasados', _resumen['rojo'], Colors.red), n('Toca hoy', _resumen['amarillo'], Colors.orange), n('Al día', _resumen['verde'], Colors.green), n('Con falla', _resumen['fallas'], Colors.purple)]),
    );
  }

  /// Fila de botones para filtrar (grupo o zona). `vacio` es el texto de "todos".
  Widget _filtros(List<Widget> hijos) => SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: hijos));

  Widget _boton(String t, bool activo, VoidCallback f, {Color color = Colors.blue}) => Padding(
        padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
        child: ChoiceChip(label: Text(t, style: TextStyle(fontSize: 12, color: activo ? Colors.white : Colors.black87)), selected: activo, selectedColor: color, onSelected: (_) => f(), visualDensity: VisualDensity.compact),
      );

  Widget _listaMia() {
    final grupos = <String, int>{};
    for (final b in _mia) {
      final g = (b['grupo'] ?? 'OTRO').toString();
      grupos[g] = (grupos[g] ?? 0) + 1;
    }
    final vis = _grupoMia.isEmpty ? _mia : _mia.where((b) => b['grupo'] == _grupoMia).toList();
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(children: [
            Expanded(child: TextField(controller: _codigo, textCapitalization: TextCapitalization.characters, onSubmitted: (_) => _agregarPorCodigo(), decoration: const InputDecoration(labelText: 'Código, código anterior o placa', hintText: 'Ej. VEH-003, 011864 o ABC-123', prefixIcon: Icon(Icons.qr_code_2), border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 8),
            FilledButton(onPressed: _agregando ? null : _agregarPorCodigo, child: _agregando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Agregar')),
          ]),
        ),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _agregarTodo, icon: const Icon(Icons.playlist_add), label: const Text('Agregar todo lo que está a la venta'))),
        if (_mia.isNotEmpty) _resumenFila(),
        if (grupos.length > 1)
          _filtros([
            _boton('Todos (${_mia.length})', _grupoMia.isEmpty, () => setState(() => _grupoMia = '')),
            for (final e in grupos.entries) _boton('${_nombreGrupo(e.key)} (${e.value})', _grupoMia == e.key, () => setState(() => _grupoMia = e.key)),
          ]),
        if (_mia.isEmpty)
          const Padding(padding: EdgeInsets.all(28), child: Text('Tu lista está vacía.\nEscribe un código o placa arriba, o entra a "A la venta" y toca + en lo que está a tu cargo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))),
        for (final b in vis) _compacto ? _fila(b) : _tarjeta(b),
        const SizedBox(height: 24),
      ]),
    );
  }

  String _nombreGrupo(String clave) {
    const n = {'CELULAR': 'Celulares', 'LAPTOP': 'Laptops', 'MOTO_LINEAL': 'Moto lineal', 'MOTOCAR': 'Motocar', 'AUTO': 'Autos', 'MOTOR': 'Motores', 'TV_AUDIO': 'TV y audio', 'HERRAMIENTA': 'Herramientas', 'JOYA': 'Joyas', 'OTRO': 'Otros'};
    return n[clave] ?? clave;
  }

  Widget _tabVenta() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: TextField(controller: _buscar, onSubmitted: (_) => _buscarVenta(), decoration: InputDecoration(labelText: 'Código, código anterior, placa o nombre', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _buscarVenta), border: const OutlineInputBorder(), isDense: true)),
      ),
      _filtros([
        _boton('Todos', _grupo.isEmpty, () {
          _grupo = '';
          _zona = '';
          _color = '';
          _marca = '';
          _buscarVenta();
        }),
        for (final g in _grupos)
          _boton('${g['nombre']} (${g['n']})', _grupo == g['clave'], () {
            _grupo = '${g['clave']}';
            _zona = '';
            _color = '';
            _marca = '';
            _buscarVenta();
          }),
      ]),
      if (_zonas.isNotEmpty || _sinUbicar > 0)
        _filtros([
          _boton('📍 Toda la tienda', _zona.isEmpty, () {
            _zona = '';
            _buscarVenta();
          }, color: Colors.teal),
          for (final z in _zonas)
            _boton('${z['zona']} (${z['n']})', _zona == z['zona'], () {
              _zona = '${z['zona']}';
              _color = '';
              _marca = '';
              _buscarVenta();
            }, color: Colors.teal),
          if (_sinUbicar > 0)
            _boton('Sin ubicar ($_sinUbicar)', _zona == '__NONE__', () {
              _zona = '__NONE__';
              _buscarVenta();
            }, color: Colors.orange),
        ]),
      if (_colores.length > 1)
        _filtros([
          const Padding(padding: EdgeInsets.only(right: 6), child: Center(child: Text('Color:', style: TextStyle(fontSize: 12, color: Colors.black54)))),
          for (final c in _colores)
            _boton('${c['nombre']} (${c['n']})', _color == c['clave'], () {
              _color = _color == c['clave'] ? '' : '${c['clave']}';
              _buscarVenta();
            }, color: Colors.deepPurple),
        ]),
      if (_marcas.length > 1)
        _filtros([
          const Padding(padding: EdgeInsets.only(right: 6), child: Center(child: Text('Marca:', style: TextStyle(fontSize: 12, color: Colors.black54)))),
          for (final c in _marcas)
            _boton('${c['nombre']} (${c['n']})', _marca == c['clave'], () {
              _marca = _marca == c['clave'] ? '' : '${c['clave']}';
              _buscarVenta();
            }, color: Colors.indigo),
        ]),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Expanded(child: Text('$_totalVenta a la venta${_totalVenta > _venta.length ? ' (mostrando ${_venta.length}, filtra para afinar)' : ''}', style: const TextStyle(fontSize: 12, color: Colors.black54))),
          if (_grupo.isNotEmpty || _zona.isNotEmpty || _color.isNotEmpty || _marca.isNotEmpty || _buscar.text.isNotEmpty)
            TextButton(
              onPressed: () {
                _grupo = '';
                _zona = '';
                _color = '';
                _marca = '';
                _buscar.clear();
                _buscarVenta();
              },
              child: const Text('Limpiar filtros'),
            ),
          IconButton(visualDensity: VisualDensity.compact, tooltip: _compacto ? 'Ver con fotos' : 'Ver lista corta', icon: Icon(_compacto ? Icons.view_agenda_outlined : Icons.view_list), onPressed: () => setState(() => _compacto = !_compacto)),
          TextButton(
            onPressed: () => setState(() {
              _modoSel = !_modoSel;
              _sel.clear();
            }),
            child: Text(_modoSel ? 'Cancelar' : 'Ubicar varios'),
          ),
        ]),
      ),
      if (_modoSel)
        Container(
          color: Colors.blue.withOpacity(0.08),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            Expanded(child: Text('${_sel.length} marcados', style: const TextStyle(fontWeight: FontWeight.w600))),
            TextButton(onPressed: () => setState(() => _sel.addAll(_venta.map((b) => (b['id'] as num).toInt()))), child: const Text('Marcar todos')),
            FilledButton(onPressed: _sel.isEmpty ? null : () => _ubicarVarios(_sel.toList()), child: const Text('Poner ubicación')),
          ]),
        ),
      Expanded(
        child: ListView(children: [
          if (_venta.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Text('No hay nada con ese filtro.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))),
          for (final b in _venta) _compacto || _modoSel ? _fila(b, conAgregar: true, seleccionable: _modoSel) : _tarjeta(b, conAgregar: true),
          const SizedBox(height: 24),
        ]),
      ),
    ]);
  }

  /// Mapa de la tienda: cada zona con cuántos bienes tiene. Al tocar una zona se ven sus bienes.
  Widget _tabMapa() {
    Widget cuadro(String zona, int n, Color c, IconData icono, String filtro) => InkWell(
          onTap: () {
            _grupo = '';
            _zona = filtro;
            _buscar.clear();
            _buscarVenta().then((_) {
              if (mounted) _tab.animateTo(1);
            });
          },
          child: Container(
            decoration: BoxDecoration(color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.5))),
            padding: const EdgeInsets.all(10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icono, color: c, size: 28),
              const SizedBox(height: 4),
              Text(zona, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              Text('$n bien${n == 1 ? '' : 'es'}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ),
        );
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        const Text('Así está ordenada la tienda y el almacén. Toca una zona para ver qué hay en ella. Lo que se vende desaparece solo.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            for (final z in _zonasMapa) cuadro('${z['zona']}', (z['n'] as num).toInt(), Colors.teal, Icons.place_outlined, '${z['zona']}'),
            if (_sinUbicarMapa > 0) cuadro('Sin ubicar', _sinUbicarMapa, Colors.orange, Icons.help_outline, '__NONE__'),
          ],
        ),
        if (_zonasMapa.isEmpty)
          const Padding(padding: EdgeInsets.all(20), child: Text('Todavía no hay zonas. En "A la venta" toca "Ubicar varios", marca lo que está junto y ponle un nombre de zona (ej. Vitrina 1, Almacén estante B, Patio).', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda y almacén'),
        bottom: TabBar(controller: _tab, isScrollable: true, tabs: [
          const Tab(text: 'Mi lista'),
          const Tab(text: 'A la venta'),
          const Tab(text: 'Mapa'),
          Tab(text: _esGerente ? 'Fallas (${_fallas.length})' : 'Mis fallas'),
        ]),
        actions: [IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh))],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 8), OutlinedButton(onPressed: _cargar, child: const Text('Reintentar'))])))
              : TabBarView(controller: _tab, children: [
                  _listaMia(),
                  _tabVenta(),
                  _tabMapa(),
                  RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView(children: [
                      if (!_esGerente)
                        Padding(padding: const EdgeInsets.all(16), child: Text(_mia.where((b) => b['falla'] != null).isEmpty ? 'Ninguno de tus bienes tiene fallas.' : 'Estos bienes tuyos tienen una falla reportada. El gerente decide la reparación.', style: const TextStyle(color: Colors.black54))),
                      if (_esGerente && _fallas.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No hay fallas abiertas en la tienda. 👍', textAlign: TextAlign.center)),
                      for (final b in (_esGerente ? _fallas : _mia.where((b) => b['falla'] != null).toList())) _tarjetaFalla(b),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ]),
    );
  }

  Widget _tarjetaFalla(Map<String, dynamic> b) {
    final f = _mapa(b['falla']);
    return Column(children: [
      _tarjeta(b),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.07), borderRadius: BorderRadius.circular(8)),
          child: Text('⚠ ${f['texto'] ?? ''}\nReportó ${f['por'] ?? '—'} · ${f['fecha'] ?? ''}${f['dias'] != null ? ' · hace ${f['dias']} día(s)' : ''}', style: const TextStyle(fontSize: 12)),
        ),
      ),
    ]);
  }
}

/// Pregunta en qué zona está (o van a estar) uno o varios bienes y lo guarda. Devuelve true si guardó.
Future<bool?> _pedirUbicacion(BuildContext context, List<int> ids, Map<String, dynamic>? actual) async {
  final zona = TextEditingController(text: (actual?['zona'] ?? '').toString());
  final detalle = TextEditingController(text: (actual?['detalle'] ?? '').toString());
  String? error;
  bool ocupado = false;
  final uid = _uid(context);
  final r = await showDialog<bool>(
    context: context,
    builder: (dc) => StatefulBuilder(
      builder: (dc, set) => AlertDialog(
        title: Text(ids.length > 1 ? 'Ubicación de ${ids.length} bienes' : 'Ubicación'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: zona, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Zona (ej. Vitrina 1, Estante B, Patio)')),
            if (_zonasConocidas.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Ya usadas:', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Wrap(spacing: 6, children: [for (final z in _zonasConocidas.take(20)) ActionChip(label: Text(z, style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact, onPressed: () => set(() => zona.text = z))]),
            ],
            TextField(controller: detalle, decoration: const InputDecoration(labelText: 'Detalle (opcional: repisa 2, al fondo…)')),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
          ]),
        ),
        actions: [
          if (actual != null)
            TextButton(
              onPressed: ocupado
                  ? null
                  : () async {
                      try {
                        await _dio.put<dynamic>('/operacion/tienda/ubicacion', data: {'usuarioId': uid, 'bienIds': ids, 'zona': ''});
                        if (dc.mounted) Navigator.pop(dc, true);
                      } catch (e) {
                        set(() => error = _err(e));
                      }
                    },
              child: const Text('Quitar'),
            ),
          TextButton(onPressed: ocupado ? null : () => Navigator.pop(dc, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: ocupado
                ? null
                : () async {
                    if (zona.text.trim().isEmpty) {
                      set(() => error = 'Escribe la zona');
                      return;
                    }
                    set(() {
                      ocupado = true;
                      error = null;
                    });
                    try {
                      await _dio.put<dynamic>('/operacion/tienda/ubicacion', data: {'usuarioId': uid, 'bienIds': ids, 'zona': zona.text.trim(), 'detalle': detalle.text.trim()});
                      if (dc.mounted) Navigator.pop(dc, true);
                    } catch (e) {
                      set(() {
                        ocupado = false;
                        error = _err(e);
                      });
                    }
                  },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  return r;
}

class _BienPage extends StatefulWidget {
  const _BienPage({required this.bienId});
  final int bienId;
  @override
  State<_BienPage> createState() => _BienPageState();
}

class _BienPageState extends State<_BienPage> {
  Map<String, dynamic>? _b;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    try {
      final r = _mapa(_cuerpo(await _dio.get<dynamic>('/operacion/tienda/bien/${widget.bienId}', queryParameters: {'usuarioId': _uid(context)})));
      if (mounted) {
        setState(() {
          _b = r;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _err(e));
    }
  }

  Future<void> _cuidado(Map<String, dynamic> datos, String ok) async {
    await _dio.post<dynamic>('/operacion/tienda/cuidado', data: {'usuarioId': _uid(context), 'bienId': widget.bienId, ...datos});
    if (mounted) _aviso(context, ok);
    await _cargar();
  }

  Future<void> _prender() async {
    final b = _b!;
    final hecho = await showModalBottomSheet<String>(
      context: context,
      builder: (dc) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(b['esVehiculo'] == true ? '¿Prendió?' : '¿Funciona?', style: const TextStyle(fontWeight: FontWeight.w700))),
          ListTile(leading: const Icon(Icons.check_circle, color: Colors.green), title: Text(b['esVehiculo'] == true ? 'Sí, prendió y lo probé' : 'Sí, funciona'), onTap: () => Navigator.pop(dc, 'PRENDIO')),
          ListTile(leading: const Icon(Icons.cancel, color: Colors.red), title: Text(b['esVehiculo'] == true ? 'No arranca / tiene falla' : 'No funciona'), onTap: () => Navigator.pop(dc, 'NO_ARRANCA')),
        ]),
      ),
    );
    if (hecho == null || !mounted) return;
    final falla = hecho == 'NO_ARRANCA';
    final ok = await _fotoMasNota(
      context,
      titulo: falla ? 'Foto y qué falla tiene' : 'Foto del bien funcionando',
      enviar: (foto, nota) async {
        if (falla && nota.isEmpty) throw 'Escribe qué falla tiene (ej. no hace corriente, no prende el motor)';
        await _cuidado({'tipo': 'PRENDER', 'resultado': hecho, 'foto': foto, 'nota': nota}, falla ? 'Falla reportada al gerente' : 'Listo: anotado');
      },
    );
    if (ok && mounted) setState(() {});
  }

  Future<void> _limpiar() async {
    await _fotoMasNota(context, titulo: 'Limpieza hecha', exigeFoto: false, enviar: (foto, nota) => _cuidado({'tipo': 'LIMPIAR', 'foto': foto, 'nota': nota}, 'Limpieza anotada'));
  }

  Future<void> _falla() async {
    await _fotoMasNota(
      context,
      titulo: 'Reportar una falla',
      exigeFoto: false,
      enviar: (foto, nota) async {
        if (nota.isEmpty) throw 'Escribe qué falla tiene';
        await _cuidado({'tipo': 'FALLA', 'foto': foto, 'nota': nota}, 'Falla reportada al gerente');
      },
    );
  }

  Future<void> _reparado() async {
    await _fotoMasNota(context, titulo: 'Marcar como reparado', exigeFoto: false, enviar: (foto, nota) => _cuidado({'tipo': 'REPARADO', 'foto': foto, 'nota': nota}, 'Marcado como reparado'));
  }

  Future<void> _revision() async {
    final r = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _RevisionPage(bien: _b!)));
    if (r == true) await _cargar();
  }

  Future<void> _editarPrecio() async {
    final b = _b!;
    final venta = TextEditingController(text: b['precioVenta']?.toString() ?? '');
    final min = TextEditingController(text: b['precioMinimo']?.toString() ?? '');
    final max = TextEditingController(text: b['precioMaximo']?.toString() ?? '');
    final nota = TextEditingController(text: b['notaPrecio']?.toString() ?? '');
    String? error;
    bool ocupado = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, set) => AlertDialog(
          title: const Text('Precio de venta'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: venta, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Precio de venta (S/)')),
              TextField(controller: min, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Precio mínimo (hasta dónde se puede bajar)')),
              TextField(controller: max, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Precio máximo (opcional)')),
              TextField(controller: nota, decoration: const InputDecoration(labelText: 'Nota (opcional)'), maxLines: 2),
              if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red))),
            ]),
          ),
          actions: [
            TextButton(onPressed: ocupado ? null : () => Navigator.pop(dc, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: ocupado
                  ? null
                  : () async {
                      set(() {
                        ocupado = true;
                        error = null;
                      });
                      try {
                        await _dio.put<dynamic>('/operacion/tienda/precio/${widget.bienId}', data: {'usuarioId': _uid(context), 'precioVenta': venta.text.trim(), 'precioMinimo': min.text.trim(), 'precioMaximo': max.text.trim(), 'nota': nota.text.trim()});
                        if (dc.mounted) Navigator.pop(dc, true);
                      } catch (e) {
                        set(() {
                          ocupado = false;
                          error = _err(e);
                        });
                      }
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await _cargar();
  }

  Future<void> _quitar() async {
    try {
      await _dio.delete<dynamic>('/operacion/tienda/lista/${widget.bienId}', queryParameters: {'usuarioId': _uid(context)});
      await _cargar();
      if (mounted) _aviso(context, 'Quitado de tu lista');
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  Future<void> _agregar() async {
    try {
      await _dio.post<dynamic>('/operacion/tienda/lista', data: {'usuarioId': _uid(context), 'bienId': widget.bienId});
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, _err(e), error: true);
    }
  }

  Widget _dato(String k, dynamic v) => (v == null || v.toString().trim().isEmpty)
      ? const SizedBox.shrink()
      : Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 110, child: Text(k, style: const TextStyle(color: Colors.black54, fontSize: 13))), Expanded(child: Text(v.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))]));

  @override
  Widget build(BuildContext context) {
    final b = _b;
    return Scaffold(
      appBar: AppBar(title: Text(b == null ? 'Detalle' : '${b['codigo']}')),
      body: b == null
          ? Center(child: _error == null ? const CircularProgressIndicator() : Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
          : ListView(padding: const EdgeInsets.all(14), children: [
              SizedBox(
                height: 150,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final k in ['imagen', 'imagen2', 'imagen3'])
                    if ((b[k] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(right: 8), child: _foto(b[k].toString(), size: 150)),
                ]),
              ),
              const SizedBox(height: 8),
              Text('${b['descripcion'] ?? ''}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.4))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('PRECIO DE VENTA', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w700)),
                      Text(b['precioVenta'] != null ? _soles(b['precioVenta']) : 'Sin precio todavía', style: TextStyle(fontSize: b['precioVenta'] != null ? 26 : 15, fontWeight: FontWeight.w800, color: const Color(0xFF1B5E20))),
                      if (b['precioMinimo'] != null || b['precioMaximo'] != null) Text('Mínimo ${_soles(b['precioMinimo'])}   ·   Máximo ${_soles(b['precioMaximo'])}', style: const TextStyle(fontSize: 13)),
                      if ((b['notaPrecio'] ?? '').toString().isNotEmpty) Text('${b['notaPrecio']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ]),
                  ),
                  if (b['puedePonerPrecio'] == true) IconButton(onPressed: _editarPrecio, icon: const Icon(Icons.edit), tooltip: 'Poner o cambiar precio'),
                ]),
              ),
              if (b['falla'] != null)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple.withOpacity(0.4))),
                  child: Text('⚠ FALLA: ${_mapa(b['falla'])['texto'] ?? ''}\nReportó ${_mapa(b['falla'])['por'] ?? '—'} · ${_mapa(b['falla'])['fecha'] ?? ''}', style: const TextStyle(fontSize: 13)),
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.withOpacity(0.4))),
                child: Row(children: [
                  const Icon(Icons.place, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b['ubicacion'] is Map ? 'Está en: ${_mapa(b['ubicacion'])['zona']}${(_mapa(b['ubicacion'])['detalle'] ?? '').toString().isEmpty ? '' : ' · ${_mapa(b['ubicacion'])['detalle']}'}' : 'Sin ubicar todavía',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final ok = await _pedirUbicacion(context, [widget.bienId], b['ubicacion'] is Map ? _mapa(b['ubicacion']) : null);
                      if (ok == true) await _cargar();
                    },
                    child: Text(b['ubicacion'] is Map ? 'Cambiar' : 'Ubicar'),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                FilledButton.icon(onPressed: _prender, icon: const Icon(Icons.power_settings_new), label: Text(b['esVehiculo'] == true ? 'Prendí / probé' : 'Probé')),
                FilledButton.tonalIcon(onPressed: _limpiar, icon: const Icon(Icons.cleaning_services), label: const Text('Limpié')),
                FilledButton.tonalIcon(onPressed: _revision, icon: const Icon(Icons.fact_check), label: const Text('Revisión completa')),
                OutlinedButton.icon(onPressed: _falla, icon: const Icon(Icons.report_problem, color: Colors.purple), label: const Text('Reportar falla')),
                if (b['falla'] != null && b['puedeReparar'] == true) OutlinedButton.icon(onPressed: _reparado, icon: const Icon(Icons.build_circle, color: Colors.green), label: const Text('Ya se reparó')),
              ]),
              const SizedBox(height: 6),
              Text(
                [
                  if (b['esVehiculo'] == true) 'Prender: ${b['diasPrender'] == null ? 'nunca' : 'hace ${b['diasPrender']} día(s)'} (cada 3)',
                  'Limpieza: ${b['diasLimpiar'] == null ? 'nunca' : 'hace ${b['diasLimpiar']} día(s)'} (cada 3)',
                  'Revisión completa: ${b['diasRevisar'] == null ? 'nunca' : 'hace ${b['diasRevisar']} día(s)'} (cada 7)',
                ].join('\n'),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const Divider(height: 28),
              const Text('Datos', style: TextStyle(fontWeight: FontWeight.w700)),
              _dato('Código', b['codigo']),
              _dato('Código anterior', b['codigoAnterior']),
              _dato('Placa', b['placa']),
              _dato('Categoría', b['categoria']),
              _dato('Marca', b['marca']),
              _dato('Modelo', b['modelo']),
              _dato('Color', b['color']),
              _dato('Año', b['anio']),
              _dato('Serie', b['serie']),
              _dato('Motor', b['motor']),
              _dato('Carrocería', b['carroceria']),
              _dato('Estado', b['estado']),
              _dato('Cantidad', b['cantidad']),
              _dato('Observaciones', b['observaciones']),
              const SizedBox(height: 8),
              b['enMiLista'] == true ? TextButton.icon(onPressed: _quitar, icon: const Icon(Icons.remove_circle_outline), label: const Text('Quitar de mi lista')) : TextButton.icon(onPressed: _agregar, icon: const Icon(Icons.add_circle_outline), label: const Text('Agregar a mi lista')),
              const Divider(height: 24),
              const Text('Historial', style: TextStyle(fontWeight: FontWeight.w700)),
              if (_lista(b['historial']).isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Todavía sin registros.', style: TextStyle(color: Colors.black54))),
              for (final h in _lista(b['historial']))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(h['tipo'] == 'PRENDER' ? Icons.power_settings_new : h['tipo'] == 'LIMPIAR' ? Icons.cleaning_services : h['tipo'] == 'REVISAR' ? Icons.fact_check : h['tipo'] == 'REPARADO' ? Icons.build_circle : Icons.report_problem, color: h['resultado'] == 'FALLA' ? Colors.purple : Colors.green),
                  title: Text('${{'PRENDER': 'Prendido / probado', 'LIMPIAR': 'Limpieza', 'REVISAR': 'Revisión completa', 'FALLA': 'Falla reportada', 'REPARADO': 'Reparado'}[h['tipo']] ?? h['tipo']}${h['resultado'] == 'FALLA' && h['tipo'] != 'FALLA' ? ' (con falla)' : ''}', style: const TextStyle(fontSize: 13)),
                  subtitle: Text('${h['fecha']} ${h['hora']} · ${h['por'] ?? ''}${(h['nota'] ?? '').toString().isNotEmpty ? '\n${h['nota']}' : ''}', style: const TextStyle(fontSize: 12)),
                  trailing: (h['foto'] ?? '').toString().isNotEmpty ? _foto(h['foto'].toString(), size: 44) : null,
                ),
              const SizedBox(height: 30),
            ]),
    );
  }
}

class _RevisionPage extends StatefulWidget {
  const _RevisionPage({required this.bien});
  final Map<String, dynamic> bien;
  @override
  State<_RevisionPage> createState() => _RevisionPageState();
}

class _RevisionPageState extends State<_RevisionPage> {
  final Map<String, bool> _resp = {};
  final _nota = TextEditingController();
  String? _fotoRuta;
  String? _error;
  bool _ocupado = false;

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final lista = _lista(widget.bien['checklist']);
    final falta = lista.where((i) => !_resp.containsKey(i['clave'])).length;
    if (falta > 0) {
      setState(() => _error = 'Te falta marcar $falta punto(s): toca ✓ si está bien o ✗ si tiene problema');
      return;
    }
    final malos = _resp.values.where((v) => !v).length;
    if (malos > 0 && _nota.text.trim().isEmpty) {
      setState(() => _error = 'Escribe qué encontraste mal');
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await _dio.post<dynamic>('/operacion/tienda/cuidado', data: {
        'usuarioId': _uid(context),
        'bienId': widget.bien['id'],
        'tipo': 'REVISAR',
        'checklist': [for (final i in lista) {'clave': i['clave'], 'ok': _resp[i['clave']] == true}],
        'nota': _nota.text.trim(),
        'foto': _fotoRuta,
      });
      if (mounted) {
        _aviso(context, malos > 0 ? 'Revisión guardada. Se avisó la falla al gerente' : 'Revisión completa guardada');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ocupado = false;
          _error = _err(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _lista(widget.bien['checklist']);
    return Scaffold(
      appBar: AppBar(title: Text('Revisión · ${widget.bien['codigo']}')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Text('${widget.bien['descripcion']}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Revisa cada punto de verdad (prende, prueba, maneja). Toca ✓ si está bien o ✗ si tiene un problema.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        for (final i in lista)
          Card(
            child: ListTile(
              dense: true,
              title: Text('${i['texto']}', style: const TextStyle(fontSize: 13)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: Icon(Icons.check_circle, color: _resp[i['clave']] == true ? Colors.green : Colors.grey.shade400), onPressed: () => setState(() => _resp[i['clave'].toString()] = true)),
                IconButton(icon: Icon(Icons.cancel, color: _resp[i['clave']] == false ? Colors.red : Colors.grey.shade400), onPressed: () => setState(() => _resp[i['clave'].toString()] = false)),
              ]),
            ),
          ),
        TextField(controller: _nota, decoration: const InputDecoration(labelText: 'Qué encontraste (obligatorio si hay ✗)'), maxLines: 2),
        const SizedBox(height: 8),
        if (_fotoRuta != null) Align(alignment: Alignment.centerLeft, child: _foto(_fotoRuta!, size: 120)),
        OutlinedButton.icon(
          onPressed: _ocupado
              ? null
              : () async {
                  try {
                    final f = await _tomarYSubir(context);
                    if (f != null) setState(() => _fotoRuta = f);
                  } catch (e) {
                    setState(() => _error = _err(e));
                  }
                },
          icon: const Icon(Icons.photo_camera),
          label: Text(_fotoRuta == null ? 'Foto (opcional)' : 'Cambiar foto'),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _ocupado ? null : _enviar, icon: const Icon(Icons.save), label: Text(_ocupado ? 'Guardando…' : 'Guardar revisión')),
        const SizedBox(height: 30),
      ]),
    );
  }
}


/// Botón grande "Buscar y filtrar": abre el buscador del almacén y la tienda con todos los filtros.
class BuscadorAlmacenBoton extends StatelessWidget {
  const BuscadorAlmacenBoton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const TiendaPage(initialTab: 1))),
        icon: const Icon(Icons.manage_search),
        label: const Text('Buscar y filtrar: tipo, color, marca, zona'),
      ),
    );
  }
}
