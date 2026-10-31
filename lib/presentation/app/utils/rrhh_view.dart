import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/rrhh_pdf.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// MÓDULO "RECURSOS HUMANOS"
// Hoy (asistencia con foto) · Personal · Pagos · Planilla · Ajustes
// Pensado para el cajero: botones grandes, pasos cortos y avisos claros.
// ---------------------------------------------------------------------------

class _Err implements Exception {
  _Err(this.m);
  final String m;
  @override
  String toString() => m;
}

class _Api {
  _Api(BuildContext c) {
    final u = c.read<Preferences>().token;
    usuarioId = u?.id ?? 0;
    final s = u?.sucursal?.id;
    sucursalId = s == null ? 0 : (int.tryParse(s.toString()) ?? 0);
    usuarioNombre = '${u?.nombre ?? ''} ${u?.apellido ?? ''}'.trim();
    dio = Dio(BaseOptions(
      baseUrl: endPointPrincipal,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'x-usuario-id': usuarioId.toString(),
        'x-usuario-nombre': Uri.encodeComponent(usuarioNombre),
      },
    ));
  }

  late final Dio dio;
  late final int usuarioId;
  late final int sucursalId;
  late final String usuarioNombre;

  dynamic _cuerpo(Response r) {
    final d = r.data;
    return d is Map ? d['body'] : d;
  }

  _Err _error(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final m = data['message'];
        return _Err(m is List ? m.join('\n') : m.toString());
      }
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return _Err('No hay conexión con el servidor. Revisa tu internet.');
      }
      return _Err(e.message ?? 'Error de conexión');
    }
    return _Err(e.toString());
  }

  Future<dynamic> get(String path, [Map<String, dynamic>? q]) async {
    try {
      return _cuerpo(await dio.get(path, queryParameters: q));
    } catch (e) {
      throw _error(e);
    }
  }

  Future<dynamic> send(String metodo, String path, Map<String, dynamic> datos, {String? archivo}) async {
    try {
      final limpio = <String, dynamic>{...datos}..removeWhere((k, v) => v == null);
      Response r;
      if (archivo != null) {
        final form = FormData.fromMap({
          ...limpio.map((k, v) => MapEntry(k, v.toString())),
          'archivo': await MultipartFile.fromFile(archivo, filename: archivo.split('/').last),
        });
        r = await dio.request(path, data: form, options: Options(method: metodo));
      } else {
        r = await dio.request(path, data: limpio, options: Options(method: metodo));
      }
      return _cuerpo(r);
    } catch (e) {
      throw _error(e);
    }
  }

  Future<dynamic> post(String p, Map<String, dynamic> d, {String? archivo}) => send('POST', p, d, archivo: archivo);
  Future<dynamic> put(String p, Map<String, dynamic> d) => send('PUT', p, d);
  Future<dynamic> borrar(String p) => send('DELETE', p, {});
}

// ------------------------------- utilidades --------------------------------
String _money(num? v) => 'S/ ${NumberFormat('#,##0.00').format(v ?? 0)}';
Map<String, dynamic> _mapa(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _lista(dynamic v) =>
    v is List ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];
String _nombreDe(Map t) => '${t['nombres'] ?? ''} ${t['apellidos'] ?? ''}'.trim();
String _hoy() => DateFormat('yyyy-MM-dd').format(DateTime.now());
String _mesActual() => DateFormat('yyyy-MM').format(DateTime.now());
String _hora(dynamic iso) {
  if (iso == null) return '--:--';
  final d = DateTime.tryParse(iso.toString())?.toLocal();
  return d == null ? '--:--' : DateFormat('HH:mm').format(d);
}

String _fechaCorta(dynamic iso) {
  final d = DateTime.tryParse(iso?.toString() ?? '')?.toLocal();
  return d == null ? '' : DateFormat('dd/MM/yyyy').format(d);
}

String _mesTexto(String periodo) {
  final d = DateTime.tryParse('$periodo-01');
  if (d == null) return periodo;
  const m = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
  return '${m[d.month - 1]} ${d.year}';
}

String _mesMas(String periodo, int delta) {
  final d = DateTime.parse('$periodo-01');
  return DateFormat('yyyy-MM').format(DateTime(d.year, d.month + delta, 1));
}

void _aviso(BuildContext c, String m, {bool error = false}) {
  ScaffoldMessenger.of(c).hideCurrentSnackBar();
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(m),
    backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
    duration: Duration(seconds: error ? 6 : 3),
  ));
}

Future<bool> _confirmar(BuildContext c, String titulo, String texto, {String si = 'Sí, continuar', Color? color}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(
          style: color == null ? null : FilledButton.styleFrom(backgroundColor: color),
          onPressed: () => Navigator.pop(c, true),
          child: Text(si),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> _pedirTexto(BuildContext c, String titulo, {String? hint, String inicial = '', TextInputType? tipo}) async {
  final ctl = TextEditingController(text: inicial);
  final r = await showDialog<String>(
    context: c,
    builder: (_) => AlertDialog(
      title: Text(titulo),
      content: TextField(controller: ctl, autofocus: true, keyboardType: tipo, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, ctl.text.trim()), child: const Text('Aceptar')),
      ],
    ),
  );
  return r;
}

/// Toma una foto con la cámara (o elige de la galería). Devuelve la ruta del archivo.
Future<String?> _foto(BuildContext c, {bool selfie = false, bool soloCamara = false}) async {
  ImageSource? fuente = ImageSource.camera;
  if (!soloCamara) {
    fuente = await showModalBottomSheet<ImageSource>(
      context: c,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Tomar foto ahora'), onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Elegir de la galería'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ]),
      ),
    );
  }
  if (fuente == null) return null;
  final f = await ImagePicker().pickImage(
    source: fuente,
    imageQuality: 70,
    maxWidth: 1600,
    preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
  );
  return f?.path;
}

/// Archivo cualquiera (foto o PDF) para el legajo.
Future<String?> _archivo(BuildContext c) async {
  final op = await showModalBottomSheet<String>(
    context: c,
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Tomar foto del documento'), onTap: () => Navigator.pop(c, 'cam')),
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Elegir foto de la galería'), onTap: () => Navigator.pop(c, 'gal')),
        ListTile(leading: const Icon(Icons.picture_as_pdf), title: const Text('Elegir un PDF u otro archivo'), onTap: () => Navigator.pop(c, 'pdf')),
      ]),
    ),
  );
  if (op == null) return null;
  if (op == 'pdf') {
    final r = await FilePicker.platform.pickFiles();
    return (r == null || r.files.isEmpty) ? null : r.files.first.path;
  }
  final f = await ImagePicker().pickImage(source: op == 'cam' ? ImageSource.camera : ImageSource.gallery, imageQuality: 75, maxWidth: 2000);
  return f?.path;
}

String _urlArchivo(String url) => '$endPointPrincipal/$url';
bool _esImagen(String url) {
  final u = url.toLowerCase();
  return u.endsWith('.jpg') || u.endsWith('.jpeg') || u.endsWith('.png') || u.endsWith('.webp') || u.endsWith('.heic');
}

Future<void> _verArchivo(BuildContext c, String? url, {String titulo = ''}) async {
  if (url == null || url.isEmpty) return;
  if (_esImagen(url)) {
    await showDialog(
      context: c,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (titulo.isNotEmpty) Padding(padding: const EdgeInsets.all(10), child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold))),
          Flexible(
            child: InteractiveViewer(
              child: Image.network(_urlArchivo(url), fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(24), child: Text('No se pudo cargar la imagen'))),
            ),
          ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar')),
        ]),
      ),
    );
  } else {
    await launchUrl(Uri.parse(_urlArchivo(url)), mode: LaunchMode.externalApplication);
  }
}

Widget _avatar(Map t, {double r = 24}) {
  final url = t['fotoUrl']?.toString();
  final ini = (_nombreDe(t).isEmpty ? '?' : _nombreDe(t)[0]).toUpperCase();
  return CircleAvatar(
    radius: r,
    backgroundColor: Colors.blueGrey.shade100,
    backgroundImage: (url != null && url.isNotEmpty && _esImagen(url)) ? NetworkImage(_urlArchivo(url)) : null,
    child: (url != null && url.isNotEmpty && _esImagen(url)) ? null : Text(ini, style: TextStyle(fontSize: r * 0.8, color: Colors.blueGrey.shade800)),
  );
}

const _vinculoTxt = {'PLANILLA': 'En planilla', 'POR_DIAS': 'Por días', 'LOCACION': 'Recibo por honorarios'};
const _estadoAsisTxt = {
  'PRESENTE': 'Presente',
  'TARDANZA': 'Tardanza',
  'FALTA': 'Faltó',
  'FALTA_JUSTIFICADA': 'Falta justificada',
  'PERMISO': 'Permiso',
  'VACACIONES': 'Vacaciones',
  'DESCANSO_MEDICO': 'Descanso médico',
  'FERIADO': 'Feriado',
  'DESCANSO': 'Descanso',
};
Color _colorAsis(String e) {
  switch (e) {
    case 'PRESENTE':
      return Colors.green.shade700;
    case 'TARDANZA':
      return Colors.orange.shade800;
    case 'FALTA':
      return Colors.red.shade700;
    default:
      return Colors.blueGrey.shade600;
  }
}

Widget _esperaW() => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));

Widget _errorBox(String msg, VoidCallback reintentar) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.red),
          const SizedBox(height: 8),
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          FilledButton(onPressed: reintentar, child: const Text('Reintentar')),
        ]),
      ),
    );

Widget _seccion(String titulo, {List<Widget> children = const [], Widget? accion, IconData? icono}) => Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icono != null) Padding(padding: const EdgeInsets.only(right: 8), child: Icon(icono, size: 20, color: Colors.blueGrey)),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            if (accion != null) accion,
          ]),
          const SizedBox(height: 6),
          ...children,
        ]),
      ),
    );

Future<String?> _pickFecha(BuildContext c, {String? inicial, DateTime? min, DateTime? max}) async {
  final ini = DateTime.tryParse(inicial ?? '') ?? DateTime.now();
  final d = await showDatePicker(
    context: c,
    initialDate: ini,
    firstDate: min ?? DateTime(2000),
    lastDate: max ?? DateTime(2100),
    helpText: 'Elige la fecha',
  );
  return d == null ? null : DateFormat('yyyy-MM-dd').format(d);
}

// ===========================================================================
// Pantalla principal
// ===========================================================================
class RrhhView extends StatefulWidget {
  const RrhhView({Key? key}) : super(key: key);

  @override
  State<RrhhView> createState() => _RrhhViewState();
}

class _RrhhViewState extends State<RrhhView> {
  late final _Api _api = _Api(context);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(children: [
        Container(
          color: Colors.blueGrey.shade50,
          child: const TabBar(
            isScrollable: true,
            labelColor: Colors.black87,
            tabs: [
              Tab(icon: Icon(Icons.how_to_reg), text: 'Hoy'),
              Tab(icon: Icon(Icons.badge), text: 'Personal'),
              Tab(icon: Icon(Icons.payments), text: 'Pagos'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Planilla'),
              Tab(icon: Icon(Icons.settings), text: 'Ajustes'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _HoyTab(api: _api),
              _PersonalTab(api: _api),
              _PagosTab(api: _api),
              _PlanillaTab(api: _api),
              _AjustesTab(api: _api),
            ],
          ),
        ),
      ]),
    );
  }
}

// ===========================================================================
// PESTAÑA "HOY": asistencia del día con foto
// ===========================================================================
class _HoyTab extends StatefulWidget {
  const _HoyTab({required this.api});
  final _Api api;
  @override
  State<_HoyTab> createState() => _HoyTabState();
}

class _HoyTabState extends State<_HoyTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic> _dia = {};
  Map<String, dynamic> _resumen = {};
  String _fecha = _hoy();
  bool _cargando = true;
  String? _error;
  int? _ocupado;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final suc = widget.api.sucursalId;
      final r = await Future.wait([
        widget.api.get('/rrhh/asistencia/dia', {'fecha': _fecha, if (suc > 0) 'sucursalId': suc}),
        widget.api.get('/rrhh/resumen', {if (suc > 0) 'sucursalId': suc}),
      ]);
      _dia = _mapa(r[0]);
      _resumen = _mapa(r[1]);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _marcar(Map item, String tipo) async {
    final t = _mapa(item['trabajador']);
    final exigir = _mapa(_dia['config'])['exigirFoto'] != false;
    String? foto;
    if (exigir) {
      foto = await _foto(context, selfie: true, soloCamara: true);
      if (foto == null) {
        if (mounted) _aviso(context, 'Para marcar hay que tomar la foto del trabajador', error: true);
        return;
      }
    }
    setState(() => _ocupado = t['id'] as int?);
    try {
      final r = _mapa(await widget.api.post('/rrhh/asistencia/marcar',
          {'trabajadorId': t['id'], 'tipo': tipo, 'usuarioId': widget.api.usuarioId}, archivo: foto));
      if (mounted) {
        final tarde = (r['minutosTarde'] as num?) ?? 0;
        _aviso(context, tipo == 'ENTRADA'
            ? '${t['nombres']}: entrada ${_hora(r['horaEntrada'])}${tarde > 0 ? ' (llegó $tarde min tarde)' : ''}'
            : '${t['nombres']}: salida ${_hora(r['horaSalida'])} · ${r['horas'] ?? ''} horas');
      }
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _ocupado = null);
  }

  Future<void> _manual(Map item, String estado) async {
    final t = _mapa(item['trabajador']);
    int dias = 1;
    String? nota;
    if (['VACACIONES', 'DESCANSO_MEDICO', 'PERMISO'].contains(estado)) {
      final d = await _pedirTexto(context, '¿Cuántos días? (${_estadoAsisTxt[estado]})', inicial: '1', tipo: TextInputType.number);
      if (d == null) return;
      dias = int.tryParse(d) ?? 1;
    }
    if (estado == 'FALTA_JUSTIFICADA' || estado == 'PERMISO' || estado == 'FALTA') {
      nota = await _pedirTexto(context, 'Motivo (opcional)', hint: 'Ej: enfermedad, trámite…');
      if (nota == null) return;
    }
    try {
      await widget.api.post('/rrhh/asistencia/manual', {
        'trabajadorId': t['id'], 'estado': estado, 'fecha': _fecha, 'dias': dias, 'nota': nota, 'usuarioId': widget.api.usuarioId,
      });
      if (mounted) _aviso(context, '${t['nombres']}: ${_estadoAsisTxt[estado]}');
      await _cargar();
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
  }

  void _detalle(Map item) {
    final t = _mapa(item['trabajador']);
    final a = _mapa(item['asistencia']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_nombreDe(t), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_estadoAsisTxt[a['estado']] ?? 'Sin marcar'} · $_fecha'),
            const SizedBox(height: 10),
            if (a.isNotEmpty) ...[
              Text('Entrada: ${_hora(a['horaEntrada'])}    Salida: ${_hora(a['horaSalida'])}'),
              if (a['horas'] != null) Text('Horas trabajadas: ${a['horas']}'),
              if ((a['minutosTarde'] ?? 0) > 0) Text('Minutos de tardanza: ${a['minutosTarde']}'),
              if (a['nota'] != null) Text('Nota: ${a['nota']}'),
              const SizedBox(height: 10),
              Row(children: [
                if (a['fotoEntrada'] != null) Expanded(child: _miniFoto('Foto entrada', a['fotoEntrada'].toString())),
                if (a['fotoSalida'] != null) Expanded(child: _miniFoto('Foto salida', a['fotoSalida'].toString())),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _miniFoto(String t, String url) => InkWell(
        onTap: () => _verArchivo(context, url, titulo: t),
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(_urlArchivo(url), height: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 140, child: Icon(Icons.broken_image))),
          ),
          Text(t, style: const TextStyle(fontSize: 12)),
        ]),
      );

  Widget _alertas() {
    final al = _lista(_resumen['alertas']);
    if (al.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      for (final a in al)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: a['nivel'] == 'rojo' ? Colors.red.shade50 : a['nivel'] == 'amarillo' ? Colors.amber.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(a['nivel'] == 'azul' ? Icons.cake : Icons.warning_amber_rounded, size: 18, color: a['nivel'] == 'rojo' ? Colors.red : a['nivel'] == 'amarillo' ? Colors.orange.shade800 : Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(a['texto'].toString(), style: const TextStyle(fontSize: 13))),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_cargando && _dia.isEmpty) return _esperaW();
    if (_error != null && _dia.isEmpty) return _errorBox(_error!, _cargar);
    final items = _lista(_dia['items']);
    final res = _mapa(_dia['resumen']);
    final esHoy = _fecha == _hoy();
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _cambiarDia(-1)),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final f = await _pickFecha(context, inicial: _fecha, max: DateTime.now());
                    if (f != null) {
                      _fecha = f;
                      _cargar();
                    }
                  },
                  child: Text(
                    esHoy ? 'HOY · ${DateFormat('dd/MM/yyyy').format(DateTime.now())}' : _fecha,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: esHoy ? null : () => _cambiarDia(1)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(spacing: 8, runSpacing: 4, children: [
              _chip('Presentes', res['presentes'], Colors.green),
              _chip('Tardanzas', res['tardanzas'], Colors.orange),
              _chip('Faltas', res['faltas'], Colors.red),
              _chip('Sin marcar', res['sinMarcar'], Colors.blueGrey),
              if (esHoy) _chip('Sin salida', res['sinSalida'], Colors.purple),
            ]),
          ),
          if (esHoy) _alertas(),
          if (!esHoy)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(8),
              color: Colors.amber.shade50,
              child: const Text('Estás viendo otro día. Aquí solo se pueden corregir faltas, permisos, etc. La entrada y salida con foto se marcan el mismo día.', style: TextStyle(fontSize: 12)),
            ),
          if (items.isEmpty)
            const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Aún no hay personal activo.\nVe a la pestaña "Personal" para agregar al primero.', textAlign: TextAlign.center))),
          for (final it in items) _fila(it, esHoy),
        ],
      ),
    );
  }

  void _cambiarDia(int d) {
    final f = DateTime.parse(_fecha).add(Duration(days: d));
    if (f.isAfter(DateTime.now())) return;
    _fecha = DateFormat('yyyy-MM-dd').format(f);
    _cargar();
  }

  Widget _chip(String t, dynamic n, MaterialColor c) => Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: c.shade50,
        label: Text('$t: ${n ?? 0}', style: TextStyle(color: c.shade800, fontSize: 12)),
      );

  Widget _fila(Map<String, dynamic> it, bool esHoy) {
    final t = _mapa(it['trabajador']);
    final a = it['asistencia'] == null ? null : _mapa(it['asistencia']);
    final estado = a?['estado']?.toString();
    final tieneEntrada = a?['horaEntrada'] != null;
    final tieneSalida = a?['horaSalida'] != null;
    final ocupado = _ocupado == t['id'];
    Widget accion;
    if (ocupado) {
      accion = const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (esHoy && a == null) {
      accion = FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
        onPressed: () => _marcar(it, 'ENTRADA'),
        icon: const Icon(Icons.login, size: 18),
        label: const Text('ENTRADA'),
      );
    } else if (esHoy && tieneEntrada && !tieneSalida) {
      accion = FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
        onPressed: () => _marcar(it, 'SALIDA'),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('SALIDA'),
      );
    } else {
      accion = const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: InkWell(
        onTap: () => _detalle(it),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            _avatar(t),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_nombreDe(t), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${t['cargo'] ?? _vinculoTxt[t['vinculo']] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 2),
                if (estado == null)
                  Text('Sin marcar · entra ${t['horaEntrada']}', style: const TextStyle(fontSize: 12, color: Colors.black54))
                else
                  Text(
                    '${_estadoAsisTxt[estado] ?? estado}${tieneEntrada ? ' · ${_hora(a!['horaEntrada'])}' : ''}${tieneSalida ? ' → ${_hora(a!['horaSalida'])}' : ''}',
                    style: TextStyle(fontSize: 13, color: _colorAsis(estado), fontWeight: FontWeight.w600),
                  ),
              ]),
            ),
            accion,
            PopupMenuButton<String>(
              tooltip: 'Más',
              onSelected: (v) => _manual(it, v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'PRESENTE', child: Text('Presente (sin foto)')),
                PopupMenuItem(value: 'FALTA', child: Text('Faltó')),
                PopupMenuItem(value: 'FALTA_JUSTIFICADA', child: Text('Falta justificada')),
                PopupMenuItem(value: 'PERMISO', child: Text('Permiso')),
                PopupMenuItem(value: 'VACACIONES', child: Text('Vacaciones')),
                PopupMenuItem(value: 'DESCANSO_MEDICO', child: Text('Descanso médico')),
                PopupMenuItem(value: 'DESCANSO', child: Text('Día de descanso')),
                PopupMenuItem(value: 'FERIADO', child: Text('Feriado')),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ===========================================================================
// PESTAÑA "PERSONAL"
// ===========================================================================
class _PersonalTab extends StatefulWidget {
  const _PersonalTab({required this.api});
  final _Api api;
  @override
  State<_PersonalTab> createState() => _PersonalTabState();
}

class _PersonalTabState extends State<_PersonalTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _busca = TextEditingController();
  List<Map<String, dynamic>> _lista_ = [];
  String _filtro = 'ACTIVOS';
  bool _cargando = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final q = <String, dynamic>{
        if (_busca.text.trim().isNotEmpty) 'q': _busca.text.trim(),
        if (_filtro == 'POR_DIAS') 'vinculo': 'POR_DIAS',
        if (_filtro == 'CESADOS') 'estado': 'CESADO',
        if (_filtro == 'TODOS') 'estado': 'TODOS',
      };
      _lista_ = _lista(await widget.api.get('/rrhh/trabajadores', q));
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _nuevo() async {
    final id = await Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => _TrabajadorForm(api: widget.api)));
    if (id != null) {
      await _cargar();
      if (mounted) await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FichaPage(api: widget.api, id: id)));
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _busca,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _cargar(),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o DNI',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: _nuevo, icon: const Icon(Icons.person_add), label: const Text('Agregar')),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          for (final f in const [['ACTIVOS', 'Activos'], ['POR_DIAS', 'Por días'], ['CESADOS', 'Cesados'], ['TODOS', 'Todos']])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(f[1]),
                selected: _filtro == f[0],
                onSelected: (_) {
                  _filtro = f[0];
                  _cargar();
                },
              ),
            ),
        ]),
      ),
      Expanded(
        child: _cargando
            ? _esperaW()
            : _error != null
                ? _errorBox(_error!, _cargar)
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: _lista_.isEmpty
                        ? ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No hay personal en esta lista.\nToca "Agregar" para registrar al primero.', textAlign: TextAlign.center)))])
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 30),
                            itemCount: _lista_.length,
                            itemBuilder: (_, i) => _tarjeta(_lista_[i]),
                          ),
                  ),
      ),
    ]);
  }

  Widget _tarjeta(Map<String, dynamic> t) {
    final pend = (t['adelantosPendientes'] as num?) ?? 0;
    final porDia = t['vinculo'] == 'POR_DIAS';
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: ListTile(
        leading: _avatar(t),
        title: Text(_nombreDe(t), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${t['cargo'] ?? 'Sin cargo'} · ${_vinculoTxt[t['vinculo']] ?? ''}\n'
          '${porDia ? '${_money(t['pagoDia'])} por día' : _money(t['sueldoMensual'])}'
          '${t['estado'] != 'ACTIVO' ? ' · ${t['estado']}' : ''}',
        ),
        isThreeLine: true,
        trailing: pend > 0
            ? Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Debe', style: TextStyle(fontSize: 11, color: Colors.red)),
                Text(_money(pend), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ])
            : const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FichaPage(api: widget.api, id: t['id'] as int)));
          _cargar();
        },
      ),
    );
  }
}

// ===========================================================================
// FORMULARIO: agregar / editar trabajador
// ===========================================================================
class _TrabajadorForm extends StatefulWidget {
  const _TrabajadorForm({required this.api, this.t});
  final _Api api;
  final Map<String, dynamic>? t;
  @override
  State<_TrabajadorForm> createState() => _TrabajadorFormState();
}

class _TrabajadorFormState extends State<_TrabajadorForm> {
  final _f = GlobalKey<FormState>();
  late final Map<String, dynamic> _t = widget.t ?? {};
  late final Map<String, TextEditingController> _c = {
    for (final k in ['dni', 'nombres', 'apellidos', 'celular', 'cargo', 'sueldoMensual', 'pagoDia', 'hijos', 'banco', 'cuentaBancaria', 'emergenciaNombre', 'emergenciaTelefono', 'domicilio', 'observaciones', 'cuspp'])
      k: TextEditingController(text: (_t[k] == null || (_t[k] is num && _t[k] == 0)) ? '' : _t[k].toString()),
  };
  late String _vinculo = (_t['vinculo'] ?? 'PLANILLA').toString();
  late String _pension = (_t['pension'] ?? 'ONP').toString();
  late String? _afp = _t['afp']?.toString();
  late String _regimen = (_t['regimen'] ?? 'MYPE_PEQUENA').toString();
  late bool _asigFam = _t['asignacionFamiliar'] == true;
  late bool _essalud = _t['essalud'] != false;
  late String _ingreso = (_t['fechaIngreso'] ?? _hoy()).toString().substring(0, 10);
  String? _nacimiento;
  String? _finContrato;
  String? _horaEnt;
  String? _horaSal;
  bool _guardando = false;

  bool get _edita => widget.t != null;

  @override
  void initState() {
    super.initState();
    _nacimiento = _t['fechaNacimiento']?.toString().substring(0, 10);
    _horaEnt = _t['horaEntrada']?.toString();
    _horaSal = _t['horaSalida']?.toString();
    if (!_edita) {
      widget.api.get('/rrhh/config').then((v) {
        final r = _mapa(v)['regimenEmpresa']?.toString();
        if (r != null && mounted) setState(() => _regimen = r);
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _hora(bool entrada) async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (t == null) return;
    final s = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() => entrada ? _horaEnt = s : _horaSal = s);
  }

  Future<void> _guardar() async {
    if (!_f.currentState!.validate()) return;
    if (_pension == 'AFP' && _afp == null) {
      _aviso(context, 'Elige la AFP del trabajador', error: true);
      return;
    }
    setState(() => _guardando = true);
    try {
      final datos = <String, dynamic>{
        'vinculo': _vinculo,
        'dni': _c['dni']!.text.trim(),
        'nombres': _c['nombres']!.text.trim(),
        'apellidos': _c['apellidos']!.text.trim(),
        'celular': _c['celular']!.text.trim(),
        'cargo': _c['cargo']!.text.trim(),
        'domicilio': _c['domicilio']!.text.trim(),
        'banco': _c['banco']!.text.trim(),
        'cuentaBancaria': _c['cuentaBancaria']!.text.trim(),
        'emergenciaNombre': _c['emergenciaNombre']!.text.trim(),
        'emergenciaTelefono': _c['emergenciaTelefono']!.text.trim(),
        'observaciones': _c['observaciones']!.text.trim(),
        'fechaIngreso': _ingreso,
        'fechaNacimiento': _nacimiento,
        'horaEntrada': _horaEnt,
        'horaSalida': _horaSal,
        if (_vinculo == 'POR_DIAS') 'pagoDia': double.tryParse(_c['pagoDia']!.text.replaceAll(',', '.')) ?? 0,
        if (_vinculo != 'POR_DIAS') 'sueldoMensual': double.tryParse(_c['sueldoMensual']!.text.replaceAll(',', '.')) ?? 0,
        if (_vinculo == 'PLANILLA') ...{
          'pension': _pension,
          'afp': _pension == 'AFP' ? _afp : null,
          'cuspp': _c['cuspp']!.text.trim(),
          'hijos': int.tryParse(_c['hijos']!.text) ?? 0,
          'asignacionFamiliar': _asigFam,
          'essalud': _essalud,
          'regimen': _regimen,
        },
        if (!_edita) 'fechaFinContrato': _finContrato,
        if (!_edita) 'usuarioId': widget.api.usuarioId,
      };
      final r = _mapa(_edita ? await widget.api.put('/rrhh/trabajadores/${_t['id']}', datos) : await widget.api.post('/rrhh/trabajadores', datos));
      final id = _mapa(r['trabajador'])['id'] as int?;
      if (mounted) Navigator.pop(context, id ?? (_t['id'] as int?));
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _guardando = false);
  }

  Widget _campo(String k, String label, {TextInputType? tipo, bool obligatorio = false, String? ayuda, int? max}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: _c[k],
          keyboardType: tipo,
          maxLength: max,
          textCapitalization: (k == 'nombres' || k == 'apellidos' || k == 'cargo') ? TextCapitalization.words : TextCapitalization.none,
          decoration: InputDecoration(labelText: label, helperText: ayuda, border: const OutlineInputBorder(), isDense: true, counterText: ''),
          validator: obligatorio ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null : null,
        ),
      );

  Widget _fechaBtn(String label, String? valor, ValueChanged<String?> onSel, {bool max = true, bool limpiar = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.event),
          label: Align(alignment: Alignment.centerLeft, child: Text('$label: ${valor ?? 'sin fecha'}')),
          onPressed: () async {
            final f = await _pickFecha(context, inicial: valor, max: max ? DateTime.now().add(const Duration(days: 3650)) : null);
            if (f != null) setState(() => onSel(f));
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edita ? 'Editar datos' : 'Agregar personal')),
      body: Form(
        key: _f,
        child: ListView(padding: const EdgeInsets.all(14), children: [
          const Text('¿Cómo trabaja?', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            for (final v in const [['PLANILLA', 'En planilla (tiene sueldo y beneficios)'], ['POR_DIAS', 'Por días (viene, trabaja y se va)'], ['LOCACION', 'Recibo por honorarios']])
              ChoiceChip(label: Text(v[1]), selected: _vinculo == v[0], onSelected: _edita ? null : (_) => setState(() => _vinculo = v[0])),
          ]),
          const SizedBox(height: 14),
          _campo('dni', 'DNI', tipo: TextInputType.number, obligatorio: true, max: 12),
          _campo('nombres', 'Nombres', obligatorio: true),
          _campo('apellidos', 'Apellidos', obligatorio: true),
          _campo('celular', 'Celular', tipo: TextInputType.phone),
          _campo('cargo', 'Cargo o función', ayuda: 'Ej: Cajero, Tasador, Limpieza, Seguridad'),
          if (_vinculo == 'POR_DIAS')
            _campo('pagoDia', 'Pago por día (S/)', tipo: const TextInputType.numberWithOptions(decimal: true), obligatorio: true)
          else
            _campo('sueldoMensual', _vinculo == 'LOCACION' ? 'Pago mensual (S/)' : 'Sueldo mensual (S/)', tipo: const TextInputType.numberWithOptions(decimal: true), obligatorio: true),
          _fechaBtn('Fecha de ingreso', _ingreso, (v) => _ingreso = v ?? _ingreso),
          _fechaBtn('Fecha de nacimiento', _nacimiento, (v) => _nacimiento = v),
          if (!_edita && _vinculo != 'POR_DIAS')
            _fechaBtn('Contrato termina el (déjalo vacío si es indefinido)', _finContrato, (v) => _finContrato = v),
          if (_vinculo == 'PLANILLA') ...[
            const Divider(height: 26),
            const Text('Pensión y seguro', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              for (final v in const [['ONP', 'ONP (13%)'], ['AFP', 'AFP'], ['NINGUNA', 'Aún no tiene']])
                ChoiceChip(label: Text(v[1]), selected: _pension == v[0], onSelected: (_) => setState(() => _pension = v[0])),
            ]),
            if (_pension == 'AFP') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _afp,
                decoration: const InputDecoration(labelText: 'Cuál AFP', border: OutlineInputBorder(), isDense: true),
                items: const ['HABITAT', 'INTEGRA', 'PRIMA', 'PROFUTURO'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _afp = v),
              ),
              const SizedBox(height: 10),
              _campo('cuspp', 'Código CUSPP (opcional)'),
            ],
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Tiene EsSalud (seguro de salud)'), value: _essalud, onChanged: (v) => setState(() => _essalud = v)),
            _campo('hijos', 'Número de hijos menores de 18', tipo: TextInputType.number),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cobra asignación familiar'),
              subtitle: const Text('Corresponde si tiene hijos menores de 18 años (o estudiando)'),
              value: _asigFam,
              onChanged: (v) => setState(() => _asigFam = v),
            ),
            DropdownButtonFormField<String>(
              value: _regimen,
              decoration: const InputDecoration(labelText: 'Régimen laboral', border: OutlineInputBorder(), isDense: true, helperText: 'Define gratificación, CTS y vacaciones. Si dudas, deja el que viene.'),
              items: const [
                DropdownMenuItem(value: 'MYPE_PEQUENA', child: Text('Pequeña empresa (MYPE)')),
                DropdownMenuItem(value: 'MYPE_MICRO', child: Text('Microempresa (MYPE)')),
                DropdownMenuItem(value: 'GENERAL', child: Text('Régimen general')),
              ],
              onChanged: (v) => setState(() => _regimen = v ?? _regimen),
            ),
            const SizedBox(height: 10),
          ],
          const Divider(height: 26),
          const Text('Horario propio (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _hora(true), child: Text('Entrada: ${_horaEnt ?? 'general'}'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _hora(false), child: Text('Salida: ${_horaSal ?? 'general'}'))),
          ]),
          const Divider(height: 26),
          _campo('domicilio', 'Dirección'),
          _campo('banco', 'Banco (para depósitos)'),
          _campo('cuentaBancaria', 'N° de cuenta o CCI'),
          _campo('emergenciaNombre', 'Contacto de emergencia'),
          _campo('emergenciaTelefono', 'Teléfono de emergencia', tipo: TextInputType.phone),
          _campo('observaciones', 'Observaciones'),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _guardando ? null : _guardar,
            icon: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
            label: Text(_edita ? 'Guardar cambios' : 'Guardar trabajador'),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}

// ===========================================================================
// FICHA DEL TRABAJADOR
// ===========================================================================
class _FichaPage extends StatefulWidget {
  const _FichaPage({required this.api, required this.id});
  final _Api api;
  final int id;
  @override
  State<_FichaPage> createState() => _FichaPageState();
}

class _FichaPageState extends State<_FichaPage> {
  Map<String, dynamic> _d = {};
  bool _cargando = true;
  String? _error;
  String _mesAsis = _mesActual();
  Map<String, dynamic>? _asis;

  Map<String, dynamic> get _t => _mapa(_d['trabajador']);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _d = _mapa(await widget.api.get('/rrhh/trabajadores/${widget.id}'));
      _asis = _mapa(await widget.api.get('/rrhh/asistencia/trabajador/${widget.id}', {'periodo': _mesAsis}));
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cambiarFoto() async {
    final f = await _foto(context, selfie: true);
    if (f == null) return;
    try {
      await widget.api.post('/rrhh/trabajadores/${widget.id}/foto', {}, archivo: f);
      _cargar();
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
  }

  Future<void> _pago(String tipo) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => tipo == 'JORNAL'
          ? _JornalSheet(api: widget.api, trabajador: _t)
          : _PagoSheet(api: widget.api, trabajador: _t, tipoInicial: tipo),
    );
    if (ok == true) _cargar();
  }

  Future<void> _nuevoContrato() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContratoSheet(api: widget.api, trabajador: _t),
    );
    if (ok == true) _cargar();
  }

  Future<void> _agregarDoc() async {
    final tipos = {
      'DNI': 'DNI (copia)',
      'CONTRATO': 'Contrato firmado',
      'CV': 'Currículum',
      'ANTECEDENTES': 'Antecedentes',
      'RENUNCIA': 'Carta de renuncia',
      'MEMO': 'Memorándum / llamada de atención',
      'CERTIFICADO': 'Certificado / estudios',
      'MEDICO': 'Examen o descanso médico',
      'OTRO': 'Otro documento',
    };
    final tipo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(14), child: Text('¿Qué documento vas a guardar?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          for (final e in tipos.entries) ListTile(title: Text(e.value), onTap: () => Navigator.pop(context, e.key)),
        ]),
      ),
    );
    if (tipo == null || !mounted) return;
    final path = await _archivo(context);
    if (path == null) return;
    try {
      await widget.api.post('/rrhh/trabajadores/${widget.id}/documentos', {'tipo': tipo, 'nombre': tipos[tipo], 'usuarioId': widget.api.usuarioId}, archivo: path);
      if (mounted) _aviso(context, 'Documento guardado');
      _cargar();
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
  }

  Future<void> _reingresar() async {
    if (!await _confirmar(context, 'Volver a contratar', '¿${_nombreDe(_t)} vuelve a trabajar? Se crea un contrato nuevo con fecha de hoy y se conserva todo su historial.')) return;
    try {
      await widget.api.post('/rrhh/trabajadores/${widget.id}/reingresar', {'usuarioId': widget.api.usuarioId});
      _cargar();
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
  }

  Future<void> _llamar(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_cargando ? 'Trabajador' : _nombreDe(_t)),
        actions: [
          if (!_cargando && _error == null)
            IconButton(
              tooltip: 'Editar datos',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final r = await Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => _TrabajadorForm(api: widget.api, t: _t)));
                if (r != null) _cargar();
              },
            ),
        ],
      ),
      body: _cargando
          ? _esperaW()
          : _error != null
              ? _errorBox(_error!, _cargar)
              : RefreshIndicator(onRefresh: _cargar, child: _cuerpo()),
    );
  }

  Widget _cuerpo() {
    final t = _t;
    final cesado = t['estado'] == 'CESADO';
    final porDia = t['vinculo'] == 'POR_DIAS';
    final vac = _mapa(_d['vacaciones']);
    final contratos = _lista(_d['contratos']);
    final docs = _lista(_d['documentos']);
    final pend = _lista(_d['adelantosPendientes']);
    final boletas = _lista(_d['boletas']);
    final pagos = _lista(_d['ultimosPagos']);
    final ceses = _lista(_d['ceses']);
    final resumen = _mapa(_asis?['resumen']);
    return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          InkWell(onTap: _cambiarFoto, child: Stack(children: [
            _avatar(t, r: 36),
            Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 11, backgroundColor: Colors.blue, child: const Icon(Icons.camera_alt, size: 13, color: Colors.white))),
          ])),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_nombreDe(t), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              Text('${t['cargo'] ?? 'Sin cargo'} · ${_vinculoTxt[t['vinculo']] ?? ''}'),
              Text('DNI ${t['dni']}   ·   Ingresó ${_fechaCorta(t['fechaIngreso'])}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              if (cesado) Text('CESADO el ${_fechaCorta(t['fechaCese'])}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              if (t['celular'] != null && t['celular'].toString().isNotEmpty)
                Row(children: [
                  InkWell(onTap: () => _llamar('tel:${t['celular']}'), child: Padding(padding: const EdgeInsets.only(top: 4, right: 14), child: Row(children: [const Icon(Icons.phone, size: 16, color: Colors.green), const SizedBox(width: 4), Text('${t['celular']}')]))),
                  InkWell(onTap: () => _llamar('https://wa.me/51${t['celular']}'), child: const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.chat, size: 18, color: Colors.green))),
                ]),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(spacing: 8, runSpacing: 6, children: [
          if (!cesado) ...[
            FilledButton.icon(onPressed: () => _pago('ADELANTO'), icon: const Icon(Icons.price_change, size: 18), label: const Text('Dar adelanto')),
            OutlinedButton.icon(onPressed: () => _pago(porDia ? 'JORNAL' : 'SUELDO'), icon: const Icon(Icons.payments, size: 18), label: Text(porDia ? 'Pagar días' : 'Otro pago')),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
              onPressed: () async {
                final r = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _CesePage(api: widget.api, t: t)));
                if (r == true) _cargar();
              },
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: const Text('Renuncia / salida'),
            ),
          ] else
            FilledButton.icon(onPressed: _reingresar, icon: const Icon(Icons.replay), label: const Text('Volver a contratar')),
        ]),
      ),
      _seccion('Resumen', icono: Icons.summarize, children: [
        _dato(porDia ? 'Pago por día' : 'Sueldo mensual', _money(porDia ? t['pagoDia'] : t['sueldoMensual'])),
        if (t['vinculo'] == 'PLANILLA') ...[
          _dato('Pensión', t['pension'] == 'AFP' ? 'AFP ${t['afp'] ?? ''}' : t['pension'] == 'ONP' ? 'ONP' : 'Sin registrar'),
          _dato('Asignación familiar', t['asignacionFamiliar'] == true ? 'Sí (${t['hijos']} hijo/s)' : 'No'),
          _dato('Régimen', {'GENERAL': 'General', 'MYPE_PEQUENA': 'Pequeña empresa', 'MYPE_MICRO': 'Microempresa'}[t['regimen']] ?? ''),
          if (vac['aplica'] == true) _dato('Vacaciones (saldo)', '${vac['saldo']} días de ${vac['ganados']} ganados (${vac['tomados']} tomados)'),
        ],
        _dato('Adelantos pendientes', _money(_d['totalAdelantosPendientes'] as num?), rojo: ((_d['totalAdelantosPendientes'] as num?) ?? 0) > 0),
        if (t['banco'] != null) _dato('Banco', '${t['banco']} ${t['cuentaBancaria'] ?? ''}'),
        if (t['emergenciaNombre'] != null) _dato('Emergencia', '${t['emergenciaNombre']} ${t['emergenciaTelefono'] ?? ''}'),
      ]),
      if (pend.isNotEmpty)
        _seccion('Adelantos que debe', icono: Icons.warning_amber, children: [
          for (final p in pend)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${_money(p['monto'])} · ${p['tipo']}'),
              subtitle: Text('${_fechaCorta(p['fecha'])}${p['concepto'] != null ? ' · ${p['concepto']}' : ''}'),
              trailing: p['fotoUrl'] != null ? const Icon(Icons.photo, color: Colors.blue) : null,
              onTap: () => _verArchivo(context, p['fotoUrl']?.toString(), titulo: 'Recibo del adelanto'),
            ),
          const Text('Se descuentan solos al generar la boleta o al pagar los días.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      _seccion('Contratos', icono: Icons.description, accion: TextButton.icon(onPressed: cesado ? null : _nuevoContrato, icon: const Icon(Icons.add), label: const Text('Nuevo / renovar')), children: [
        if (contratos.isEmpty) const Text('Sin contratos'),
        for (final c in contratos)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(c['estado'] == 'VIGENTE' ? Icons.verified : Icons.history, color: c['estado'] == 'VIGENTE' ? Colors.green : Colors.grey),
            title: Text('${{'INDEFINIDO': 'Indefinido', 'PLAZO_FIJO': 'Plazo fijo', 'POR_DIAS': 'Por días', 'LOCACION': 'Honorarios'}[c['tipo']] ?? c['tipo']} · ${_money(c['remuneracion'])}'),
            subtitle: Text('Desde ${_fechaCorta(c['fechaInicio'])}${c['fechaFin'] != null ? ' hasta ${_fechaCorta(c['fechaFin'])}' : ''} · ${c['estado']}'),
            trailing: IconButton(
              tooltip: 'Imprimir contrato',
              icon: const Icon(Icons.print),
              onPressed: () async => mostrarPdf(await pdfContrato(t, c), 'Contrato ${_nombreDe(t)}'),
            ),
          ),
      ]),
      _seccion('Archivo del trabajador', icono: Icons.folder_shared, accion: TextButton.icon(onPressed: _agregarDoc, icon: const Icon(Icons.add_a_photo), label: const Text('Guardar')), children: [
        if (docs.isEmpty) const Text('Aquí guardas el DNI, contrato firmado, CV, renuncia, memos… Toca "Guardar" y toma la foto.'),
        for (final d in docs)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(_esImagen(d['url'].toString()) ? Icons.image : Icons.picture_as_pdf, color: Colors.blueGrey),
            title: Text(d['nombre'].toString()),
            subtitle: Text('${d['tipo']} · ${_fechaCorta(d['createdAt'])}'),
            onTap: () => _verArchivo(context, d['url']?.toString(), titulo: d['nombre'].toString()),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (!await _confirmar(context, 'Quitar de la lista', 'El archivo queda guardado en el servidor, solo deja de mostrarse aquí.')) return;
                await widget.api.borrar('/rrhh/documentos/${d['id']}');
                _cargar();
              },
            ),
          ),
      ]),
      _seccion('Asistencia de ${_mesTexto(_mesAsis)}', icono: Icons.event_available, accion: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.chevron_left), onPressed: () { _mesAsis = _mesMas(_mesAsis, -1); _cargar(); }),
        IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.chevron_right), onPressed: _mesAsis == _mesActual() ? null : () { _mesAsis = _mesMas(_mesAsis, 1); _cargar(); }),
      ]), children: [
        Wrap(spacing: 8, children: [
          Chip(label: Text('Asistió: ${resumen['presentes'] ?? 0}')),
          Chip(label: Text('Tardanzas: ${resumen['tardanzas'] ?? 0} (${resumen['minutosTarde'] ?? 0} min)')),
          Chip(label: Text('Faltas: ${resumen['faltas'] ?? 0}')),
          Chip(label: Text('Permisos/vacac.: ${((resumen['permisos'] as num?) ?? 0) + ((resumen['vacaciones'] as num?) ?? 0)}')),
        ]),
        for (final a in _lista(_asis?['dias']).reversed.take(31))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${a['fecha']} · ${_estadoAsisTxt[a['estado']] ?? a['estado']}', style: TextStyle(color: _colorAsis(a['estado'].toString()))),
            subtitle: Text('${_hora(a['horaEntrada'])} → ${_hora(a['horaSalida'])}${a['horas'] != null ? ' · ${a['horas']} h' : ''}${a['pagadoJornal'] == true ? ' · pagado' : ''}'),
            trailing: a['fotoEntrada'] != null ? const Icon(Icons.photo_camera, color: Colors.blue, size: 18) : null,
            onTap: a['fotoEntrada'] != null ? () => _verArchivo(context, a['fotoEntrada'].toString(), titulo: 'Entrada ${a['fecha']}') : null,
          ),
      ]),
      _seccion('Boletas y beneficios', icono: Icons.receipt_long, children: [
        if (boletas.isEmpty) const Text('Todavía no hay boletas'),
        for (final b in boletas)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${{'SUELDO': 'Sueldo', 'GRATIFICACION': 'Gratificación', 'CTS': 'CTS', 'LIQUIDACION': 'Liquidación'}[b['tipo']] ?? b['tipo']} ${b['periodo']} · ${_money(b['neto'])}'),
            subtitle: Text(b['estado'] == 'ANULADA' ? 'ANULADA' : b['pagoId'] != null ? 'Pagada' : 'Pendiente de pago'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BoletaPage(api: widget.api, id: b['id'] as int)));
              _cargar();
            },
          ),
      ]),
      _seccion('Últimos pagos', icono: Icons.payments, children: [
        if (pagos.isEmpty) const Text('Sin pagos registrados'),
        for (final p in pagos)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${p['tipo']} · ${_money(p['monto'])}', style: TextStyle(decoration: p['estado'] == 'ANULADO' ? TextDecoration.lineThrough : null)),
            subtitle: Text('${_fechaCorta(p['fecha'])} · ${p['usuarioNombre'] ?? ''}${p['concepto'] != null ? '\n${p['concepto']}' : ''}'),
            trailing: p['fotoUrl'] != null ? const Icon(Icons.photo, color: Colors.blue) : null,
            onTap: () => _verArchivo(context, p['fotoUrl']?.toString(), titulo: 'Recibo'),
          ),
      ]),
      if (ceses.isNotEmpty)
        _seccion('Salidas anteriores', icono: Icons.exit_to_app, children: [
          for (final c in ceses)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${_fechaCorta(c['fecha'])} · ${c['motivo']}'),
              subtitle: Text('Liquidación ${_money(c['liquidacionTotal'])} · ${c['estadoLiquidacion']}'),
              trailing: c['cartaUrl'] != null ? const Icon(Icons.attach_file) : null,
              onTap: () => _verArchivo(context, c['cartaUrl']?.toString(), titulo: 'Carta'),
            ),
        ]),
    ]);
  }

  Widget _dato(String k, String v, {bool rojo = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          Expanded(child: Text(v, style: TextStyle(fontWeight: FontWeight.w600, color: rojo ? Colors.red : null))),
        ]),
      );
}

// ===========================================================================
// HOJA: registrar un pago / adelanto (con foto del recibo)
// ===========================================================================
class _PagoSheet extends StatefulWidget {
  const _PagoSheet({required this.api, required this.trabajador, this.tipoInicial = 'ADELANTO'});
  final _Api api;
  final Map<String, dynamic> trabajador;
  final String tipoInicial;
  @override
  State<_PagoSheet> createState() => _PagoSheetState();
}

class _PagoSheetState extends State<_PagoSheet> {
  final _monto = TextEditingController();
  final _concepto = TextEditingController();
  late String _tipo = widget.tipoInicial == 'JORNAL' ? 'ADELANTO' : widget.tipoInicial;
  bool _caja = true;
  String? _fotoPath;
  bool _enviando = false;

  static const _ayuda = {
    'ADELANTO': 'Dinero que se le da antes de su pago. Se descuenta solo en su próxima boleta.',
    'PRESTAMO': 'Préstamo personal. También se descuenta de su boleta.',
    'QUINCENA': 'Pago de media quincena. Se descuenta de la boleta del mes.',
    'SUELDO': 'Pago libre de sueldo (para pagos fuera de la boleta).',
    'VACACIONES': 'Pago de sus vacaciones.',
    'BONO': 'Dinero extra que se suma a su boleta (no sale de caja ahora).',
    'DESCUENTO': 'Multa o descuento que se resta de su boleta (no sale de caja).',
  };

  @override
  void dispose() {
    _monto.dispose();
    _concepto.dispose();
    super.dispose();
  }

  Future<void> _enviar({bool confirmado = false}) async {
    final monto = double.tryParse(_monto.text.replaceAll(',', '.')) ?? 0;
    if (monto <= 0) {
      _aviso(context, 'Escribe el monto', error: true);
      return;
    }
    final concepto = _tipo == 'BONO' || _tipo == 'DESCUENTO';
    if (!concepto && _fotoPath == null) {
      _aviso(context, 'Toma una foto del recibo firmado o del trabajador recibiendo el dinero', error: true);
      return;
    }
    setState(() => _enviando = true);
    try {
      await widget.api.post('/rrhh/pagos', {
        'trabajadorId': widget.trabajador['id'],
        'tipo': _tipo,
        'monto': monto,
        'concepto': _concepto.text.trim(),
        'desdeCaja': concepto ? false : _caja,
        'usuarioId': widget.api.usuarioId,
        'usuarioNombre': widget.api.usuarioNombre,
        'sucursalId': widget.api.sucursalId > 0 ? widget.api.sucursalId : null,
        if (confirmado) 'confirmarExceso': true,
      }, archivo: _fotoPath);
      if (mounted) {
        Navigator.pop(context, true);
        _aviso(context, '$_tipo de ${_money(monto)} registrado');
      }
    } catch (e) {
      final m = e.toString();
      if (m.startsWith('CONFIRMAR') && mounted) {
        setState(() => _enviando = false);
        if (await _confirmar(context, 'Adelanto alto', m.replaceFirst('CONFIRMAR: ', ''), si: 'Sí, dar el adelanto')) {
          return _enviar(confirmado: true);
        }
        return;
      }
      if (mounted) _aviso(context, m, error: true);
    }
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trabajador;
    final porDia = t['vinculo'] == 'POR_DIAS';
    final tipos = porDia ? ['ADELANTO', 'BONO', 'DESCUENTO'] : ['ADELANTO', 'PRESTAMO', 'QUINCENA', 'SUELDO', 'VACACIONES', 'BONO', 'DESCUENTO'];
    final concepto = _tipo == 'BONO' || _tipo == 'DESCUENTO';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pago a ${_nombreDe(t)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: [
            for (final x in tipos) ChoiceChip(label: Text({'ADELANTO': 'Adelanto', 'PRESTAMO': 'Préstamo', 'QUINCENA': 'Quincena', 'SUELDO': 'Sueldo', 'VACACIONES': 'Vacaciones', 'BONO': 'Bono', 'DESCUENTO': 'Descuento'}[x]!), selected: _tipo == x, onSelected: (_) => setState(() => _tipo = x)),
          ]),
          const SizedBox(height: 6),
          Text(_ayuda[_tipo] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),
          TextField(
            controller: _monto,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(prefixText: 'S/ ', labelText: 'Monto', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(controller: _concepto, decoration: const InputDecoration(labelText: 'Motivo o nota (opcional)', border: OutlineInputBorder(), isDense: true)),
          if (!concepto) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('El dinero sale de la caja de hoy'),
              subtitle: Text(_caja ? 'Se registra la salida en caja (necesita caja abierta).' : 'No se toca la caja (se pagó de otro dinero).'),
              value: _caja,
              onChanged: (v) => setState(() => _caja = v),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final f = await _foto(context);
                if (f != null) setState(() => _fotoPath = f);
              },
              icon: Icon(_fotoPath == null ? Icons.photo_camera : Icons.check_circle, color: _fotoPath == null ? null : Colors.green),
              label: Text(_fotoPath == null ? 'Tomar foto del recibo / entrega (obligatorio)' : 'Foto lista · tocar para cambiar'),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _enviando ? null : _enviar,
            icon: _enviando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
            label: const Text('Registrar'),
          ),
        ]),
      ),
    );
  }
}

// ===========================================================================
// HOJA: pagar días trabajados (personal por días)
// ===========================================================================
class _JornalSheet extends StatefulWidget {
  const _JornalSheet({required this.api, required this.trabajador});
  final _Api api;
  final Map<String, dynamic> trabajador;
  @override
  State<_JornalSheet> createState() => _JornalSheetState();
}

class _JornalSheetState extends State<_JornalSheet> {
  Map<String, dynamic> _j = {};
  bool _cargando = true;
  bool _enviando = false;
  bool _caja = true;
  String? _foto_;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.api.get('/rrhh/jornal/${widget.trabajador['id']}').then((v) {
      if (mounted) setState(() { _j = _mapa(v); _cargando = false; });
    }).catchError((e) {
      if (mounted) setState(() { _error = e.toString(); _cargando = false; });
    });
  }

  Future<void> _pagar() async {
    if (_foto_ == null) {
      _aviso(context, 'Toma la foto del trabajador recibiendo su pago', error: true);
      return;
    }
    setState(() => _enviando = true);
    try {
      await widget.api.post('/rrhh/jornal/pagar', {
        'trabajadorId': widget.trabajador['id'], 'desdeCaja': _caja, 'usuarioId': widget.api.usuarioId,
        'usuarioNombre': widget.api.usuarioNombre, 'sucursalId': widget.api.sucursalId > 0 ? widget.api.sucursalId : null,
      }, archivo: _foto_);
      if (mounted) {
        Navigator.pop(context, true);
        _aviso(context, 'Pago registrado: ${_money(_j['neto'] as num?)}');
      }
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trabajador;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _cargando
            ? _esperaW()
            : _error != null
                ? Text(_error!)
                : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pagar a ${_nombreDe(t)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Días trabajados sin pagar: ${_j['cantidad']}  (${_money(_mapa(_j['trabajador'])['pagoDia'] as num?)} por día)'),
                    if ((_j['dias'] as List?)?.isNotEmpty ?? false) Text((_j['dias'] as List).map((e) => e.toString().substring(5)).join('  ·  '), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const Divider(height: 22),
                    _fila('Total ganado', _money(_j['bruto'] as num?)),
                    if (((_j['descuento'] as num?) ?? 0) > 0) _fila('Menos adelantos', '- ${_money(_j['descuento'] as num?)}', rojo: true),
                    _fila('A PAGAR', _money(_j['neto'] as num?), grande: true),
                    if (((_j['cantidad'] as num?) ?? 0) == 0)
                      const Padding(padding: EdgeInsets.only(top: 10), child: Text('No tiene días pendientes. Primero marca su asistencia en la pestaña "Hoy".', style: TextStyle(color: Colors.red)))
                    else ...[
                      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('El dinero sale de la caja de hoy'), value: _caja, onChanged: (v) => setState(() => _caja = v)),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final f = await _foto(context);
                          if (f != null) setState(() => _foto_ = f);
                        },
                        icon: Icon(_foto_ == null ? Icons.photo_camera : Icons.check_circle, color: _foto_ == null ? null : Colors.green),
                        label: Text(_foto_ == null ? 'Tomar foto de la entrega (obligatorio)' : 'Foto lista · tocar para cambiar'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        onPressed: (_enviando || ((_j['neto'] as num?) ?? 0) <= 0) ? null : _pagar,
                        icon: const Icon(Icons.check),
                        label: Text(_enviando ? 'Guardando…' : 'Pagar ${_money(_j['neto'] as num?)}'),
                      ),
                    ],
                  ]),
      ),
    );
  }

  Widget _fila(String a, String b, {bool rojo = false, bool grande = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: TextStyle(fontSize: grande ? 17 : 14, fontWeight: grande ? FontWeight.bold : null)),
          Text(b, style: TextStyle(fontSize: grande ? 20 : 14, fontWeight: FontWeight.bold, color: rojo ? Colors.red : null)),
        ]),
      );
}

// ===========================================================================
// HOJA: nuevo contrato / renovación
// ===========================================================================
class _ContratoSheet extends StatefulWidget {
  const _ContratoSheet({required this.api, required this.trabajador});
  final _Api api;
  final Map<String, dynamic> trabajador;
  @override
  State<_ContratoSheet> createState() => _ContratoSheetState();
}

class _ContratoSheetState extends State<_ContratoSheet> {
  late String _tipo = widget.trabajador['vinculo'] == 'POR_DIAS' ? 'POR_DIAS' : widget.trabajador['vinculo'] == 'LOCACION' ? 'LOCACION' : 'INDEFINIDO';
  String _inicio = _hoy();
  String? _fin;
  late final TextEditingController _rem = TextEditingController(
      text: '${(widget.trabajador['vinculo'] == 'POR_DIAS' ? widget.trabajador['pagoDia'] : widget.trabajador['sueldoMensual']) ?? ''}');
  late final TextEditingController _cargo = TextEditingController(text: widget.trabajador['cargo']?.toString() ?? '');
  bool _actualizar = true;
  bool _enviando = false;

  Future<void> _guardar() async {
    if (_tipo == 'PLAZO_FIJO' && _fin == null) {
      _aviso(context, 'El contrato a plazo fijo necesita la fecha en que termina', error: true);
      return;
    }
    setState(() => _enviando = true);
    try {
      await widget.api.post('/rrhh/trabajadores/${widget.trabajador['id']}/contratos', {
        'tipo': _tipo, 'fechaInicio': _inicio, 'fechaFin': _tipo == 'PLAZO_FIJO' || _tipo == 'LOCACION' ? _fin : null,
        'remuneracion': double.tryParse(_rem.text.replaceAll(',', '.')) ?? 0, 'cargo': _cargo.text.trim(),
        'actualizarSueldo': _actualizar, 'usuarioId': widget.api.usuarioId,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Nuevo contrato', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const Text('El contrato anterior pasa a "renovado" y se conserva.', style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: [
            for (final v in const [['INDEFINIDO', 'Indefinido'], ['PLAZO_FIJO', 'Plazo fijo'], ['POR_DIAS', 'Por días'], ['LOCACION', 'Honorarios']])
              ChoiceChip(label: Text(v[1]), selected: _tipo == v[0], onSelected: (_) => setState(() => _tipo = v[0])),
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text('Empieza: $_inicio'),
            onPressed: () async {
              final f = await _pickFecha(context, inicial: _inicio);
              if (f != null) setState(() => _inicio = f);
            },
          ),
          if (_tipo == 'PLAZO_FIJO' || _tipo == 'LOCACION')
            OutlinedButton.icon(
              icon: const Icon(Icons.event_busy),
              label: Text('Termina: ${_fin ?? 'elegir fecha'}'),
              onPressed: () async {
                final f = await _pickFecha(context, inicial: _fin ?? _inicio);
                if (f != null) setState(() => _fin = f);
              },
            ),
          const SizedBox(height: 10),
          TextField(controller: _rem, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(prefixText: 'S/ ', labelText: _tipo == 'POR_DIAS' ? 'Pago por día' : 'Remuneración mensual', border: const OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 10),
          TextField(controller: _cargo, decoration: const InputDecoration(labelText: 'Cargo', border: OutlineInputBorder(), isDense: true)),
          CheckboxListTile(contentPadding: EdgeInsets.zero, value: _actualizar, onChanged: (v) => setState(() => _actualizar = v ?? true), title: const Text('Actualizar también el sueldo/cargo en su ficha')),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)), onPressed: _enviando ? null : _guardar, child: const Text('Guardar contrato')),
        ]),
      ),
    );
  }
}

// ===========================================================================
// RENUNCIA / SALIDA / LIQUIDACIÓN
// ===========================================================================
class _CesePage extends StatefulWidget {
  const _CesePage({required this.api, required this.t});
  final _Api api;
  final Map<String, dynamic> t;
  @override
  State<_CesePage> createState() => _CesePageState();
}

class _CesePageState extends State<_CesePage> {
  String _motivo = 'RENUNCIA';
  String _fecha = _hoy();
  final _nota = TextEditingController();
  String? _carta;
  Map<String, dynamic>? _liq;
  bool _calc = false;
  bool _ok = false;
  bool _enviando = false;

  static const _motivos = {
    'RENUNCIA': 'Renunció',
    'TERMINO_CONTRATO': 'Terminó su contrato',
    'MUTUO_DISENSO': 'Acuerdo mutuo',
    'DESPIDO': 'Despido',
    'ABANDONO': 'Abandonó el trabajo',
    'OTRO': 'Otro motivo',
  };

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _calcular() async {
    setState(() => _calc = true);
    try {
      _liq = _mapa(await widget.api.get('/rrhh/ceses/liquidacion', {'trabajadorId': widget.t['id'], 'fecha': _fecha, 'motivo': _motivo}));
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _calc = false);
  }

  Future<void> _registrar() async {
    setState(() => _enviando = true);
    try {
      final r = _mapa(await widget.api.post('/rrhh/ceses', {
        'trabajadorId': widget.t['id'], 'motivo': _motivo, 'fecha': _fecha, 'nota': _nota.text.trim(), 'usuarioId': widget.api.usuarioId,
      }, archivo: _carta));
      if (!mounted) return;
      final boletaId = r['boletaId'] as int?;
      Navigator.pop(context, true);
      if (boletaId != null) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BoletaPage(api: widget.api, id: boletaId)));
      }
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final liq = _liq;
    return Scaffold(
      appBar: AppBar(title: const Text('Renuncia / salida')),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Text(_nombreDe(t), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Paso 1: ¿por qué se va?', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 6, children: [for (final e in _motivos.entries) ChoiceChip(label: Text(e.value), selected: _motivo == e.key, onSelected: (_) => setState(() { _motivo = e.key; _liq = null; _ok = false; }))]),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.event),
          label: Text('Último día de trabajo: $_fecha'),
          onPressed: () async {
            final f = await _pickFecha(context, inicial: _fecha);
            if (f != null) setState(() { _fecha = f; _liq = null; _ok = false; });
          },
        ),
        const SizedBox(height: 14),
        const Text('Paso 2: la carta', style: TextStyle(fontWeight: FontWeight.bold)),
        if (_motivo == 'RENUNCIA')
          OutlinedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Imprimir carta de renuncia para que la firme'),
            onPressed: () async => mostrarPdf(await pdfCartaRenuncia(t, _hoy(), ultimoDia: _fecha), 'Carta de renuncia ${_nombreDe(t)}'),
          ),
        OutlinedButton.icon(
          icon: Icon(_carta == null ? Icons.add_a_photo : Icons.check_circle, color: _carta == null ? null : Colors.green),
          label: Text(_carta == null ? 'Guardar foto de la carta firmada (recomendado)' : 'Carta lista · tocar para cambiar'),
          onPressed: () async {
            final f = await _archivo(context);
            if (f != null) setState(() => _carta = f);
          },
        ),
        const SizedBox(height: 10),
        TextField(controller: _nota, maxLines: 2, decoration: const InputDecoration(labelText: 'Nota (opcional)', border: OutlineInputBorder())),
        const SizedBox(height: 14),
        const Text('Paso 3: lo que se le debe pagar', style: TextStyle(fontWeight: FontWeight.bold)),
        FilledButton.tonalIcon(onPressed: _calc ? null : _calcular, icon: const Icon(Icons.calculate), label: Text(_calc ? 'Calculando…' : 'Calcular liquidación estimada')),
        if (liq != null) ...[
          const SizedBox(height: 8),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final i in _lista(liq['items'])) _lineaMonto(i['concepto'].toString(), i['monto'] as num?),
                if (_lista(liq['items']).isEmpty) const Text('No hay montos pendientes por pagar.'),
                const Divider(),
                _lineaMonto('Total a favor del trabajador', liq['bruto'] as num?, fuerte: true),
                if (((liq['descuento'] as num?) ?? 0) > 0) _lineaMonto('Menos adelantos que debe', -((liq['descuento'] as num?) ?? 0), rojo: true),
                _lineaMonto('NETO A PAGAR', liq['neto'] as num?, fuerte: true),
                for (final a in (liq['advertencias'] as List? ?? const [])) Padding(padding: const EdgeInsets.only(top: 6), child: Text('• $a', style: const TextStyle(fontSize: 12, color: Colors.deepOrange))),
                if (_mapa(liq['referencial'])['indemnizacionDespidoArbitrario'] != null)
                  Padding(padding: const EdgeInsets.only(top: 6), child: Text('Referencia (solo si el despido es arbitrario): indemnización aprox. ${_money(_mapa(liq['referencial'])['indemnizacionDespidoArbitrario'] as num?)}', style: const TextStyle(fontSize: 12))),
              ]),
            ),
          ),
          const Text('Es un cálculo estimado. Lo confirmas con tu contador si hay dudas.', style: TextStyle(fontSize: 11, color: Colors.black54)),
          CheckboxListTile(contentPadding: EdgeInsets.zero, value: _ok, onChanged: (v) => setState(() => _ok = v ?? false), title: const Text('Revisé todo y confirmo la salida')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, minimumSize: const Size.fromHeight(50)),
            onPressed: (_ok && !_enviando) ? _registrar : null,
            icon: const Icon(Icons.exit_to_app),
            label: Text(_enviando ? 'Guardando…' : 'Registrar salida del trabajador'),
          ),
        ],
        const SizedBox(height: 40),
      ]),
    );
  }
}

Widget _lineaMonto(String a, num? m, {bool fuerte = false, bool rojo = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(a, style: TextStyle(fontWeight: fuerte ? FontWeight.bold : null, fontSize: 13))),
        Text(_money(m), style: TextStyle(fontWeight: fuerte ? FontWeight.bold : null, color: rojo ? Colors.red : null)),
      ]),
    );

// ===========================================================================
// BOLETA (ver, pagar, anular, imprimir)
// ===========================================================================
class _DetalleBoleta extends StatelessWidget {
  const _DetalleBoleta({required this.b});
  final Map<String, dynamic> b;
  @override
  Widget build(BuildContext context) {
    final det = _mapa(b['detalle']);
    final ingresos = _lista(det['ingresos'] ?? det['items']);
    final desc = det['descuentosLista'] != null
        ? _lista(det['descuentosLista'])
        : (((det['descuento'] as num?) ?? 0) > 0 ? [<String, dynamic>{'concepto': 'Adelantos descontados', 'monto': det['descuento']}] : <Map<String, dynamic>>[]);
    final aportes = _lista(det['aportes']);
    final adv = (det['advertencias'] as List? ?? const []);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('INGRESOS', style: TextStyle(fontWeight: FontWeight.bold)),
      for (final i in ingresos) _lineaMonto(i['concepto'].toString(), i['monto'] as num?),
      _lineaMonto('Total ingresos', b['bruto'] as num?, fuerte: true),
      const SizedBox(height: 10),
      const Text('DESCUENTOS', style: TextStyle(fontWeight: FontWeight.bold)),
      if (desc.isEmpty) const Text('Sin descuentos', style: TextStyle(fontSize: 13)),
      for (final d in desc) _lineaMonto(d['concepto'].toString(), d['monto'] as num?, rojo: true),
      _lineaMonto('Total descuentos', b['descuentos'] as num?, fuerte: true),
      const Divider(height: 22),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('NETO A PAGAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(_money(b['neto'] as num?), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
      ]),
      if (aportes.isNotEmpty) ...[
        const SizedBox(height: 10),
        const Text('Aportes que paga la empresa (no se le descuentan)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        for (final a in aportes) _lineaMonto(a['concepto'].toString(), a['monto'] as num?),
      ],
      for (final a in adv) Padding(padding: const EdgeInsets.only(top: 6), child: Text('• $a', style: const TextStyle(fontSize: 12, color: Colors.deepOrange))),
    ]);
  }
}

class _BoletaPage extends StatefulWidget {
  const _BoletaPage({required this.api, required this.id});
  final _Api api;
  final int id;
  @override
  State<_BoletaPage> createState() => _BoletaPageState();
}

class _BoletaPageState extends State<_BoletaPage> {
  Map<String, dynamic> _b = {};
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _b = _mapa(await widget.api.get('/rrhh/boletas/${widget.id}'));
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _pagar() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PagarBoletaSheet(api: widget.api, boleta: _b),
    );
    if (ok == true) _cargar();
  }

  Future<void> _anular() async {
    if (!await _confirmar(context, 'Anular boleta', 'Los adelantos vuelven a quedar pendientes. ¿Anular esta boleta?', si: 'Sí, anular', color: Colors.red)) return;
    try {
      await widget.api.post('/rrhh/boletas/${widget.id}/anular', {});
      _cargar();
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagada = _b['pagoId'] != null;
    final anulada = _b['estado'] == 'ANULADA';
    final titulo = {'SUELDO': 'Boleta de pago', 'GRATIFICACION': 'Gratificación', 'CTS': 'CTS', 'LIQUIDACION': 'Liquidación'}[_b['tipo']] ?? 'Boleta';
    return Scaffold(
      appBar: AppBar(title: Text('$titulo ${_b['periodo'] ?? ''}')),
      body: _cargando
          ? _esperaW()
          : _error != null
              ? _errorBox(_error!, _cargar)
              : ListView(padding: const EdgeInsets.all(14), children: [
                  Text(_b['trabajadorNombre']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(8),
                    color: anulada ? Colors.red.shade50 : pagada ? Colors.green.shade50 : Colors.amber.shade50,
                    child: Text(anulada ? 'ANULADA' : pagada ? 'PAGADA' : 'Pendiente de pago', style: TextStyle(fontWeight: FontWeight.bold, color: anulada ? Colors.red : pagada ? Colors.green.shade800 : Colors.orange.shade900)),
                  ),
                  _DetalleBoleta(b: _b),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async => mostrarPdf(await pdfBoleta(_b, nombre: _b['trabajadorNombre']?.toString()), 'Boleta ${_b['trabajadorNombre']} ${_b['periodo']}'),
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimir / compartir PDF'),
                  ),
                  if (!anulada && !pagada) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)), onPressed: _pagar, icon: const Icon(Icons.payments), label: Text('Pagar ${_money(_b['neto'] as num?)}')),
                    TextButton(onPressed: _anular, child: const Text('Anular esta boleta', style: TextStyle(color: Colors.red))),
                  ],
                ]),
    );
  }
}

class _PagarBoletaSheet extends StatefulWidget {
  const _PagarBoletaSheet({required this.api, required this.boleta});
  final _Api api;
  final Map<String, dynamic> boleta;
  @override
  State<_PagarBoletaSheet> createState() => _PagarBoletaSheetState();
}

class _PagarBoletaSheetState extends State<_PagarBoletaSheet> {
  late bool _caja = widget.boleta['tipo'] != 'CTS';
  String? _foto_;
  bool _enviando = false;

  Future<void> _enviar() async {
    final neto = (widget.boleta['neto'] as num?) ?? 0;
    if (neto > 0 && _foto_ == null) {
      _aviso(context, 'Toma la foto del recibo o del voucher de depósito', error: true);
      return;
    }
    setState(() => _enviando = true);
    try {
      await widget.api.post('/rrhh/boletas/${widget.boleta['id']}/pagar', {
        'desdeCaja': _caja, 'usuarioId': widget.api.usuarioId, 'usuarioNombre': widget.api.usuarioNombre,
        'sucursalId': widget.api.sucursalId > 0 ? widget.api.sucursalId : null,
      }, archivo: _foto_);
      if (mounted) {
        Navigator.pop(context, true);
        _aviso(context, 'Pago registrado');
      }
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pagar ${_money(widget.boleta['neto'] as num?)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('El dinero sale de la caja de hoy'),
            subtitle: Text(_caja ? 'Se registra la salida en caja.' : 'No toca la caja (depósito o transferencia).'),
            value: _caja,
            onChanged: (v) => setState(() => _caja = v),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final f = await _foto(context);
              if (f != null) setState(() => _foto_ = f);
            },
            icon: Icon(_foto_ == null ? Icons.photo_camera : Icons.check_circle, color: _foto_ == null ? null : Colors.green),
            label: Text(_foto_ == null ? 'Foto del recibo firmado / voucher (obligatorio)' : 'Foto lista · tocar para cambiar'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)), onPressed: _enviando ? null : _enviar, icon: const Icon(Icons.check), label: Text(_enviando ? 'Guardando…' : 'Confirmar pago')),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Elegir trabajador (buscador en hoja)
// ===========================================================================
Future<Map<String, dynamic>?> _elegirTrabajador(BuildContext c, _Api api, {String? vinculo}) async {
  List<Map<String, dynamic>> todos;
  try {
    todos = _lista(await api.get('/rrhh/trabajadores', {if (vinculo != null) 'vinculo': vinculo}));
  } catch (e) {
    _aviso(c, e.toString(), error: true);
    return null;
  }
  if (todos.isEmpty) {
    _aviso(c, 'Primero agrega al personal en la pestaña "Personal"', error: true);
    return null;
  }
  // ignore: use_build_context_synchronously
  return showModalBottomSheet<Map<String, dynamic>>(
    context: c,
    isScrollControlled: true,
    builder: (_) => _ElegirSheet(todos: todos),
  );
}

class _ElegirSheet extends StatefulWidget {
  const _ElegirSheet({required this.todos});
  final List<Map<String, dynamic>> todos;
  @override
  State<_ElegirSheet> createState() => _ElegirSheetState();
}

class _ElegirSheetState extends State<_ElegirSheet> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final lista = widget.todos.where((t) => '${_nombreDe(t)} ${t['dni']}'.toLowerCase().contains(_q.toLowerCase())).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(14), child: Text('¿A quién?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(onChanged: (v) => setState(() => _q = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar', isDense: true, border: OutlineInputBorder())),
        ),
        Expanded(
          child: ListView(children: [
            for (final t in lista)
              ListTile(
                leading: _avatar(t, r: 20),
                title: Text(_nombreDe(t)),
                subtitle: Text('${t['cargo'] ?? ''} · ${_vinculoTxt[t['vinculo']] ?? ''}'),
                onTap: () => Navigator.pop(context, t),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ===========================================================================
// PESTAÑA "PAGOS"
// ===========================================================================
class _PagosTab extends StatefulWidget {
  const _PagosTab({required this.api});
  final _Api api;
  @override
  State<_PagosTab> createState() => _PagosTabState();
}

class _PagosTabState extends State<_PagosTab> with AutomaticKeepAliveClientMixin {
  String _mes = _mesActual();
  List<Map<String, dynamic>> _pagos = [];
  bool _cargando = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _pagos = _lista(await widget.api.get('/rrhh/pagos', {'periodo': _mes}));
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _nuevo(String tipo) async {
    final t = await _elegirTrabajador(context, widget.api, vinculo: tipo == 'JORNAL' ? 'POR_DIAS' : null);
    if (t == null || !mounted) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => tipo == 'JORNAL' ? _JornalSheet(api: widget.api, trabajador: t) : _PagoSheet(api: widget.api, trabajador: t, tipoInicial: tipo),
    );
    if (ok == true) _cargar();
  }

  Future<void> _anular(Map<String, dynamic> p) async {
    final motivo = await _pedirTexto(context, 'Motivo para anular este pago', hint: 'Ej: me equivoqué de monto');
    if (motivo == null || motivo.isEmpty) return;
    try {
      final r = _mapa(await widget.api.post('/rrhh/pagos/${p['id']}/anular', {'motivo': motivo}));
      if (mounted) _aviso(context, r['aviso']?.toString() ?? 'Pago anulado');
      _cargar();
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final validos = _pagos.where((p) => p['estado'] != 'ANULADO' && p['tipo'] != 'BONO' && p['tipo'] != 'DESCUENTO');
    final total = validos.fold<num>(0, (a, p) => a + ((p['monto'] as num?) ?? 0));
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(onPressed: () => _nuevo('ADELANTO'), icon: const Icon(Icons.price_change), label: const Text('Dar adelanto')),
            FilledButton.tonalIcon(onPressed: () => _nuevo('JORNAL'), icon: const Icon(Icons.today), label: const Text('Pagar días (por días)')),
            OutlinedButton.icon(onPressed: () => _nuevo('SUELDO'), icon: const Icon(Icons.payments), label: const Text('Otro pago / bono')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { _mes = _mesMas(_mes, -1); _cargar(); }),
            Expanded(child: Text(_mesTexto(_mes), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _mes == _mesActual() ? null : () { _mes = _mesMas(_mes, 1); _cargar(); }),
          ]),
        ),
        Center(child: Text('Pagado en el mes: ${_money(total)}', style: const TextStyle(fontSize: 15, color: Colors.black54))),
        if (_cargando) _esperaW() else if (_error != null) _errorBox(_error!, _cargar) else if (_pagos.isEmpty)
          const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No hay pagos en este mes')))
        else
          for (final p in _pagos)
            Card(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: ListTile(
                title: Text('${p['trabajador']}', style: TextStyle(fontWeight: FontWeight.bold, decoration: p['estado'] == 'ANULADO' ? TextDecoration.lineThrough : null)),
                subtitle: Text('${p['tipo']} · ${_fechaCorta(p['fecha'])} · ${p['usuarioNombre'] ?? ''}${p['concepto'] != null ? '\n${p['concepto']}' : ''}${p['descontado'] == true ? '\n(ya descontado en boleta)' : ''}${p['estado'] == 'ANULADO' ? '\nANULADO: ${p['motivoAnulacion']}' : ''}'),
                isThreeLine: true,
                leading: p['fotoUrl'] != null ? InkWell(onTap: () => _verArchivo(context, p['fotoUrl'].toString(), titulo: 'Recibo'), child: const Icon(Icons.photo, color: Colors.blue)) : const Icon(Icons.receipt, color: Colors.grey),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_money(p['monto'] as num?), style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (p['estado'] != 'ANULADO' && p['descontado'] != true) InkWell(onTap: () => _anular(p), child: const Text('Anular', style: TextStyle(fontSize: 12, color: Colors.red))),
                ]),
              ),
            ),
      ]),
    );
  }
}

// ===========================================================================
// PESTAÑA "PLANILLA": boletas del mes, gratificación y CTS
// ===========================================================================
class _PlanillaTab extends StatefulWidget {
  const _PlanillaTab({required this.api});
  final _Api api;
  @override
  State<_PlanillaTab> createState() => _PlanillaTabState();
}

class _PlanillaTabState extends State<_PlanillaTab> with AutomaticKeepAliveClientMixin {
  String _mes = _mesActual();
  List<Map<String, dynamic>> _trab = [];
  Map<int, Map<String, dynamic>> _bol = {};
  bool _cargando = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        widget.api.get('/rrhh/trabajadores'),
        widget.api.get('/rrhh/boletas', {'periodo': _mes}),
      ]);
      _trab = _lista(r[0]).where((t) => t['vinculo'] != 'POR_DIAS').toList();
      _bol = {};
      for (final b in _lista(r[1])) {
        if (b['tipo'] == 'SUELDO' && b['estado'] == 'GENERADA') _bol[b['trabajadorId'] as int] = b;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _calcular(Map<String, dynamic> t) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _CalculoBoletaPage(api: widget.api, t: t, periodo: _mes)));
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final totalNeto = _bol.values.fold<num>(0, (a, b) => a + ((b['neto'] as num?) ?? 0));
    final ahora = DateTime.now();
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        _seccion('Gratificación y CTS', icono: Icons.card_giftcard, children: [
          const Text('Se calculan para todo el personal de golpe. Gratificación: julio y diciembre. CTS: mayo y noviembre.', style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BeneficiosPage(api: widget.api, tipo: 'GRATIFICACION', periodoInicial: ahora.month <= 7 ? '${ahora.year}-07' : '${ahora.year}-12'))),
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Gratificación'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BeneficiosPage(api: widget.api, tipo: 'CTS', periodoInicial: ahora.month <= 5 ? '${ahora.year}-05' : ahora.month <= 11 ? '${ahora.year}-11' : '${ahora.year + 1}-05'))),
              icon: const Icon(Icons.savings),
              label: const Text('CTS'),
            ),
          ]),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { _mes = _mesMas(_mes, -1); _cargar(); }),
            Expanded(child: Text('Boletas de ${_mesTexto(_mes)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _mes == _mesActual() ? null : () { _mes = _mesMas(_mes, 1); _cargar(); }),
          ]),
        ),
        Center(child: Text('Total a pagar en boletas: ${_money(totalNeto)}', style: const TextStyle(color: Colors.black54))),
        if (_cargando) _esperaW() else if (_error != null) _errorBox(_error!, _cargar) else if (_trab.isEmpty)
          const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No hay personal en planilla.\nEl personal por días se paga desde la pestaña "Pagos".', textAlign: TextAlign.center)))
        else
          for (final t in _trab) _fila(t),
      ]),
    );
  }

  Widget _fila(Map<String, dynamic> t) {
    final b = _bol[t['id'] as int];
    final pagada = b != null && b['pagoId'] != null;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: ListTile(
        leading: _avatar(t, r: 20),
        title: Text(_nombreDe(t), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(b == null ? 'Sueldo ${_money(t['sueldoMensual'] as num?)} · sin boleta' : pagada ? 'Pagada ✓ ${_money(b['neto'] as num?)}' : 'Boleta lista · neto ${_money(b['neto'] as num?)}'),
        trailing: b == null
            ? FilledButton(onPressed: () => _calcular(t), child: const Text('Calcular'))
            : pagada
                ? const Icon(Icons.check_circle, color: Colors.green)
                : FilledButton.tonal(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BoletaPage(api: widget.api, id: b['id'] as int))).then((_) => _cargar()), child: const Text('Pagar')),
        onTap: b == null ? () => _calcular(t) : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BoletaPage(api: widget.api, id: b['id'] as int))).then((_) => _cargar()),
      ),
    );
  }
}

class _CalculoBoletaPage extends StatefulWidget {
  const _CalculoBoletaPage({required this.api, required this.t, required this.periodo});
  final _Api api;
  final Map<String, dynamic> t;
  final String periodo;
  @override
  State<_CalculoBoletaPage> createState() => _CalculoBoletaPageState();
}

class _CalculoBoletaPageState extends State<_CalculoBoletaPage> {
  Map<String, dynamic> _c = {};
  bool _cargando = true;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.api.get('/rrhh/boletas/calcular', {'trabajadorId': widget.t['id'], 'periodo': widget.periodo}).then((v) {
      if (mounted) setState(() { _c = _mapa(v); _cargando = false; });
    }).catchError((e) {
      if (mounted) setState(() { _error = e.toString(); _cargando = false; });
    });
  }

  Future<void> _generar() async {
    setState(() => _enviando = true);
    try {
      final b = _mapa(await widget.api.post('/rrhh/boletas/generar', {'trabajadorId': widget.t['id'], 'periodo': widget.periodo, 'usuarioId': widget.api.usuarioId}));
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => _BoletaPage(api: widget.api, id: b['id'] as int)));
    } catch (e) {
      if (mounted) {
        _aviso(context, e.toString(), error: true);
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fake = {'bruto': _c['bruto'], 'descuentos': _c['descuentos'], 'neto': _c['neto'], 'detalle': _c};
    final a = _mapa(_c['asistencia']);
    return Scaffold(
      appBar: AppBar(title: Text('Boleta ${_mesTexto(widget.periodo)}')),
      body: _cargando
          ? _esperaW()
          : _error != null
              ? Padding(padding: const EdgeInsets.all(20), child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView(padding: const EdgeInsets.all(14), children: [
                  Text(_nombreDe(widget.t), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Asistencia del mes: ${a['faltas'] ?? 0} falta(s), ${a['minutosTarde'] ?? 0} min de tardanza', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 10),
                  _DetalleBoleta(b: fake),
                  const SizedBox(height: 8),
                  const Text('Esto es una vista previa. Al generar, los adelantos quedan descontados.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 10),
                  FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)), onPressed: _enviando ? null : _generar, icon: const Icon(Icons.receipt_long), label: Text(_enviando ? 'Generando…' : 'Generar boleta')),
                ]),
    );
  }
}

class _BeneficiosPage extends StatefulWidget {
  const _BeneficiosPage({required this.api, required this.tipo, required this.periodoInicial});
  final _Api api;
  final String tipo;
  final String periodoInicial;
  @override
  State<_BeneficiosPage> createState() => _BeneficiosPageState();
}

class _BeneficiosPageState extends State<_BeneficiosPage> {
  late String _periodo = widget.periodoInicial;
  Map<String, dynamic> _d = {};
  bool _cargando = true;
  String? _error;

  bool get _grat => widget.tipo == 'GRATIFICACION';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _d = _mapa(await widget.api.get('/rrhh/beneficios/todos', {'tipo': widget.tipo, 'periodo': _periodo}));
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _generar(Map<String, dynamic> it) async {
    try {
      final b = _mapa(await widget.api.post('/rrhh/beneficios/generar', {'trabajadorId': it['trabajadorId'], 'tipo': widget.tipo, 'periodo': _periodo, 'usuarioId': widget.api.usuarioId}));
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BoletaPage(api: widget.api, id: b['id'] as int)));
      _cargar();
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opciones = _grat ? ['07', '12'] : ['05', '11'];
    final anio = int.parse(_periodo.substring(0, 4));
    final items = _lista(_d['items']);
    return Scaffold(
      appBar: AppBar(title: Text(_grat ? 'Gratificación' : 'CTS')),
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            _grat
                ? 'Se paga en julio (de enero a junio) y diciembre (de julio a diciembre), hasta el 15 de cada mes. Incluye la bonificación extraordinaria.'
                : 'Se deposita en mayo (de noviembre a abril) y noviembre (de mayo a octubre), hasta el 15 de cada mes, en la cuenta CTS del trabajador.',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { _periodo = '${anio - 1}-${_periodo.substring(5)}'; _cargar(); }),
          Text('$anio', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { _periodo = '${anio + 1}-${_periodo.substring(5)}'; _cargar(); }),
        ]),
        Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
          for (final m in opciones)
            ChoiceChip(
              label: Text(_grat ? (m == '07' ? 'Julio' : 'Diciembre') : (m == '05' ? 'Mayo' : 'Noviembre')),
              selected: _periodo.substring(5) == m,
              onSelected: (_) { _periodo = '$anio-$m'; _cargar(); },
            ),
        ]),
        if (_cargando) _esperaW() else if (_error != null) _errorBox(_error!, _cargar) else ...[
          Padding(padding: const EdgeInsets.all(12), child: Center(child: Text('Total estimado: ${_money(_d['total'] as num?)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
          if (items.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay personal en planilla'))),
          for (final it in items)
            Card(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: ListTile(
                title: Text('${it['trabajador']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(it['aplica'] == true ? _lista(it['items']).map((e) => '${e['concepto']}: ${_money(e['monto'] as num?)}').join('\n') : (it['advertencias'] as List).first.toString()),
                isThreeLine: it['aplica'] == true,
                trailing: it['aplica'] != true
                    ? const Text('No aplica', style: TextStyle(color: Colors.grey))
                    : it['generada'] == true
                        ? TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _BoletaPage(api: widget.api, id: it['boletaId'] as int))).then((_) => _cargar()), child: const Text('Ver'))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(_money(it['neto'] as num?), style: const TextStyle(fontWeight: FontWeight.bold)),
                            InkWell(onTap: () => _generar(it), child: const Text('Generar', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                          ]),
              ),
            ),
        ],
      ]),
    );
  }
}

// ===========================================================================
// PESTAÑA "AJUSTES": valores de ley y reglas de la empresa
// ===========================================================================
class _AjustesTab extends StatefulWidget {
  const _AjustesTab({required this.api});
  final _Api api;
  @override
  State<_AjustesTab> createState() => _AjustesTabState();
}

class _AjustesTabState extends State<_AjustesTab> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic> _cfg = {};
  final Map<String, TextEditingController> _c = {};
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  static const _campos = [
    ['rmv', 'Sueldo mínimo (RMV)', 'S/'],
    ['asignacionFamiliarPct', 'Asignación familiar (% de la RMV)', '%'],
    ['onpPct', 'ONP', '%'],
    ['afpAportePct', 'AFP aporte obligatorio', '%'],
    ['afpPrimaPct', 'AFP seguro (prima)', '%'],
    ['afpTope', 'AFP tope de remuneración', 'S/'],
    ['essaludPct', 'EsSalud (lo paga la empresa)', '%'],
    ['bonifExtraordinariaPct', 'Bonificación extraordinaria gratificación', '%'],
    ['uit', 'UIT', 'S/'],
    ['toleranciaMinutos', 'Minutos de tolerancia al llegar', 'min'],
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _cfg = _mapa(await widget.api.get('/rrhh/config'));
      for (final f in _campos) {
        (_c[f[0]] ??= TextEditingController()).text = '${_cfg[f[0]] ?? ''}';
      }
      for (final a in _mapa(_cfg['afpComisiones']).keys) {
        (_c['afp_$a'] ??= TextEditingController()).text = '${_mapa(_cfg['afpComisiones'])[a]}';
      }
      for (final k in ['horaEntrada', 'horaSalida']) {
        (_c[k] ??= TextEditingController()).text = '${_cfg[k] ?? ''}';
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      double v(String k) => double.tryParse(_c[k]!.text.replaceAll(',', '.')) ?? 0;
      final datos = <String, dynamic>{
        for (final f in _campos) f[0]: v(f[0]),
        'horaEntrada': _c['horaEntrada']!.text.trim(),
        'horaSalida': _c['horaSalida']!.text.trim(),
        'descontarTardanza': _cfg['descontarTardanza'],
        'exigirFotoAsistencia': _cfg['exigirFotoAsistencia'],
        'exigirFotoPagos': _cfg['exigirFotoPagos'],
        'regimenEmpresa': _cfg['regimenEmpresa'],
        'afpComisiones': {for (final a in _mapa(_cfg['afpComisiones']).keys) a: v('afp_$a')},
      };
      _cfg = _mapa(await widget.api.put('/rrhh/config', datos));
      if (mounted) _aviso(context, 'Ajustes guardados');
    } catch (e) {
      if (mounted) _aviso(context, e.toString(), error: true);
    }
    if (mounted) setState(() => _guardando = false);
  }

  Widget _num(String k, String label, String suf) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(controller: _c[k], keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label, suffixText: suf, border: const OutlineInputBorder(), isDense: true)),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_cargando) return _esperaW();
    if (_error != null) return _errorBox(_error!, _cargar);
    return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
      _seccion('¿Cómo se usa? (guía rápida)', icono: Icons.help_outline, children: const [
        Text('1. PERSONAL: agrega a cada trabajador (DNI, sueldo, ONP/AFP). Guarda su contrato y documentos.\n'
            '2. HOY: cada día toma la foto de entrada y de salida. Si no vino, márcalo "Faltó". Para personal por días, igual: entrada y salida con foto.\n'
            '3. PAGOS: para dar un adelanto toma la foto del recibo firmado. Para el personal por días usa "Pagar días": suma los días y descuenta sus adelantos.\n'
            '4. PLANILLA: a fin de mes toca "Calcular" → "Generar boleta" → "Pagar". Los adelantos y las faltas se descuentan solos.\n'
            '5. Julio y diciembre: gratificación. Mayo y noviembre: CTS.\n'
            '6. Si alguien se va: en su ficha "Renuncia / salida". Se calcula lo que se le debe.\n\n'
            'Nada se borra: todo queda guardado con fecha y quién lo hizo.', style: TextStyle(fontSize: 13)),
      ]),
      _seccion('Horario general', icono: Icons.schedule, children: [
        Row(children: [
          Expanded(child: TextField(controller: _c['horaEntrada'], decoration: const InputDecoration(labelText: 'Entrada (HH:MM)', border: OutlineInputBorder(), isDense: true))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _c['horaSalida'], decoration: const InputDecoration(labelText: 'Salida (HH:MM)', border: OutlineInputBorder(), isDense: true))),
        ]),
        _num('toleranciaMinutos', 'Minutos de tolerancia', 'min'),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Exigir foto al marcar asistencia'), value: _cfg['exigirFotoAsistencia'] != false, onChanged: (v) => setState(() => _cfg['exigirFotoAsistencia'] = v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Exigir foto en adelantos y pagos'), value: _cfg['exigirFotoPagos'] != false, onChanged: (v) => setState(() => _cfg['exigirFotoPagos'] = v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Descontar las tardanzas del sueldo'), subtitle: const Text('Apagado: solo se registran'), value: _cfg['descontarTardanza'] == true, onChanged: (v) => setState(() => _cfg['descontarTardanza'] = v)),
      ]),
      _seccion('Valores de ley (Perú)', icono: Icons.gavel, children: [
        const Text('Los valores vienen cargados, pero cámbialos aquí cuando la ley cambie. Confírmalos con tu contador.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _cfg['regimenEmpresa']?.toString(),
          decoration: const InputDecoration(labelText: 'Régimen de la empresa (por defecto al agregar personal)', border: OutlineInputBorder(), isDense: true),
          items: const [
            DropdownMenuItem(value: 'MYPE_PEQUENA', child: Text('Pequeña empresa (MYPE)')),
            DropdownMenuItem(value: 'MYPE_MICRO', child: Text('Microempresa (MYPE)')),
            DropdownMenuItem(value: 'GENERAL', child: Text('Régimen general')),
          ],
          onChanged: (v) => setState(() => _cfg['regimenEmpresa'] = v),
        ),
        const SizedBox(height: 8),
        for (final f in _campos.where((f) => f[0] != 'toleranciaMinutos')) _num(f[0], f[1], f[2]),
      ]),
      _seccion('Comisión por flujo de cada AFP', icono: Icons.account_balance, children: [
        for (final a in _mapa(_cfg['afpComisiones']).keys) _num('afp_$a', a, '%'),
      ]),
      Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)), onPressed: _guardando ? null : _guardar, icon: const Icon(Icons.save), label: Text(_guardando ? 'Guardando…' : 'Guardar ajustes')),
      ),
    ]);
  }
}
