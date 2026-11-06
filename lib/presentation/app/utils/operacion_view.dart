import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

// ============================================================ AYUDAS
final Dio _dio = Dio(BaseOptions(
  baseUrl: endPointPrincipal,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(minutes: 2),
));

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
    final usuario = TextEditingController();
    final clave = TextEditingController();
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
      const Text('Toca un puesto para ver, en simple, qué ve y qué no puede hacer:', style: TextStyle(fontSize: 13)),
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
