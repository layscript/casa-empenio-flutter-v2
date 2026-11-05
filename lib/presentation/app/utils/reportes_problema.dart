import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/actualizaciones.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp del dueño: aquí deben reenviarse todos los reportes.
const kWhatsappDueno = '51920391631';

final Dio _dio = Dio(BaseOptions(
  baseUrl: endPointPrincipal,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 60),
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

DateTime _lima(DateTime d) => d.toUtc().subtract(const Duration(hours: 5));

String _fechaLima(DateTime d) {
  final l = _lima(d);
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(l.day)}/${dos(l.month)}/${l.year} ${dos(l.hour)}:${dos(l.minute)}';
}

const _estadoTxt = {
  'NUEVO': 'Nuevo',
  'REVISADO': 'Revisado',
  'AUTORIZADO': 'Autorizado',
  'CORREGIDO': 'Corregido',
  'RECHAZADO': 'Rechazado',
};
const _estadoColor = {
  'NUEVO': Colors.orange,
  'REVISADO': Colors.blue,
  'AUTORIZADO': Colors.teal,
  'CORREGIDO': Colors.green,
  'RECHAZADO': Colors.red,
};

Future<void> _abrirWhatsapp(String texto) async {
  final uri = Uri.parse('https://wa.me/$kWhatsappDueno?text=${Uri.encodeComponent(texto)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _textoWhatsapp(Map r) =>
    '*REPORTE #${r['id']}* (${_estadoTxt[r['estado']] ?? r['estado']})\n'
    'Usuario: ${r['usuarioNombre'] ?? ''}\n'
    'Sucursal: ${r['sucursalNombre'] ?? ''}\n'
    'Pantalla: ${r['pantalla'] ?? ''}\n'
    'Versión: ${r['version'] ?? ''}\n'
    '${r['descripcion'] ?? ''}'
    '${(r['imagenes'] is List && (r['imagenes'] as List).isNotEmpty) ? '\n(Tiene ${(r['imagenes'] as List).length} foto(s) en el sistema)' : ''}'
    '${r['audio'] != null ? '\n(Tiene audio en el sistema)' : ''}';

// ============================================================ NUEVO REPORTE
class ReportarProblemaPage extends StatefulWidget {
  const ReportarProblemaPage({super.key, this.pantalla});
  final String? pantalla;

  @override
  State<ReportarProblemaPage> createState() => _ReportarProblemaPageState();
}

class _ReportarProblemaPageState extends State<ReportarProblemaPage> {
  final _texto = TextEditingController();
  final List<XFile> _fotos = [];
  final AudioRecorder _rec = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _audioPath;
  bool _grabando = false;
  bool _reproduciendo = false;
  int _segundos = 0;
  Timer? _reloj;
  bool _enviando = false;
  String? _error;

  UserEntity? get _user => context.read<Preferences>().token;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _reproduciendo = false);
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _texto.dispose();
    _rec.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _foto(ImageSource fuente) async {
    if (_fotos.length >= 4) {
      setState(() => _error = 'Máximo 4 fotos');
      return;
    }
    final x = await ImagePicker().pickImage(source: fuente, imageQuality: 70);
    if (x != null && mounted) setState(() {
          _fotos.add(x);
          _error = null;
        });
  }

  Future<void> _grabar() async {
    try {
      if (!await _rec.hasPermission()) {
        setState(() => _error = 'Permite el micrófono para grabar el audio');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/reporte_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _rec.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      _segundos = 0;
      _reloj?.cancel();
      _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _segundos++);
        if (_segundos >= 180) _detener();
      });
      setState(() {
        _grabando = true;
        _audioPath = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'No se pudo grabar: $e');
    }
  }

  Future<void> _detener() async {
    _reloj?.cancel();
    try {
      final p = await _rec.stop();
      if (mounted) setState(() {
            _grabando = false;
            _audioPath = p;
          });
    } catch (_) {
      if (mounted) setState(() => _grabando = false);
    }
  }

  Future<void> _escuchar() async {
    if (_audioPath == null) return;
    if (_reproduciendo) {
      await _player.stop();
      setState(() => _reproduciendo = false);
    } else {
      await _player.play(DeviceFileSource(_audioPath!));
      setState(() => _reproduciendo = true);
    }
  }

  Future<String> _subir(String ruta) async {
    final r = await _dio.post<dynamic>('/reportes/archivo',
        data: FormData.fromMap({'archivo': await MultipartFile.fromFile(ruta, filename: ruta.split('/').last)}));
    return (_cuerpo(r) as Map)['url'].toString();
  }

  Future<void> _enviar() async {
    if (_grabando) await _detener();
    if (_texto.text.trim().isEmpty && _fotos.isEmpty && _audioPath == null) {
      setState(() => _error = 'Escribe qué pasó, o agrega una foto o un audio');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final u = _user;
      final imagenes = <String>[];
      for (final f in _fotos) {
        imagenes.add(await _subir(f.path));
      }
      final audio = _audioPath != null ? await _subir(_audioPath!) : null;
      final r = await _dio.post<dynamic>('/reportes', data: {
        'usuarioId': u?.id,
        'usuarioNombre': u?.fullName,
        'sucursalId': u?.sucursal?.id,
        'sucursalNombre': u?.sucursal?.nombre,
        'pantalla': widget.pantalla ?? 'No indicada',
        'version': kBuildActual > 0 ? 'build $kBuildActual ($appVersion)' : appVersion,
        'descripcion': _texto.text.trim(),
        'imagenes': imagenes,
        'audio': audio,
      });
      final rep = Map<String, dynamic>.from(_cuerpo(r) as Map);
      if (!mounted) return;
      await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _ReporteEnviadoPage(reporte: rep)));
    } catch (e) {
      if (mounted) setState(() {
            _enviando = false;
            _error = _err(e);
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar un problema')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Cuéntanos qué pasó. Puedes escribir, tomar fotos o grabar un audio (o todo junto).', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: _texto,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: '¿Qué pasó?', alignLabelWithHint: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          const Text('Fotos o capturas (hasta 4)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < _fotos.length; i++)
              Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_fotos[i].path), width: 80, height: 80, fit: BoxFit.cover)),
                Positioned(
                  right: 0,
                  top: 0,
                  child: InkWell(
                    onTap: () => setState(() => _fotos.removeAt(i)),
                    child: const CircleAvatar(radius: 11, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                  ),
                ),
              ]),
            OutlinedButton.icon(onPressed: () => _foto(ImageSource.camera), icon: const Icon(Icons.photo_camera), label: const Text('Cámara')),
            OutlinedButton.icon(onPressed: () => _foto(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Galería')),
          ]),
          const SizedBox(height: 14),
          const Text('Audio (hasta 3 minutos)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (_grabando)
            Row(children: [
              const Icon(Icons.fiber_manual_record, color: Colors.red),
              const SizedBox(width: 6),
              Text('Grabando… ${_segundos ~/ 60}:${(_segundos % 60).toString().padLeft(2, '0')}'),
              const Spacer(),
              FilledButton.icon(onPressed: _detener, icon: const Icon(Icons.stop), label: const Text('Terminar')),
            ])
          else if (_audioPath != null)
            Row(children: [
              OutlinedButton.icon(onPressed: _escuchar, icon: Icon(_reproduciendo ? Icons.stop : Icons.play_arrow), label: Text(_reproduciendo ? 'Parar' : 'Escuchar')),
              const SizedBox(width: 8),
              TextButton.icon(onPressed: () => setState(() => _audioPath = null), icon: const Icon(Icons.delete_outline), label: const Text('Quitar')),
              TextButton(onPressed: _grabar, child: const Text('Grabar de nuevo')),
            ])
          else
            OutlinedButton.icon(onPressed: _grabar, icon: const Icon(Icons.mic), label: const Text('Grabar audio')),
          const SizedBox(height: 14),
          Card(
            color: Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Se enviará con estos datos (automático):\n'
                'Usuario: ${u?.fullName ?? ''}\n'
                'Sucursal: ${u?.sucursal?.nombre ?? ''}\n'
                'Pantalla: ${widget.pantalla ?? 'No indicada'}\n'
                'Versión: ${kBuildActual > 0 ? 'build $kBuildActual · ' : ''}$appVersion\n'
                'Hora (Lima): ${_fechaLima(DateTime.now())}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _enviando ? null : _enviar,
            icon: _enviando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
            label: Text(_enviando ? 'Enviando…' : 'Enviar reporte'),
          ),
        ],
      ),
    );
  }
}

// ============================================================ REPORTE ENVIADO
class _ReporteEnviadoPage extends StatefulWidget {
  const _ReporteEnviadoPage({required this.reporte});
  final Map<String, dynamic> reporte;

  @override
  State<_ReporteEnviadoPage> createState() => _ReporteEnviadoPageState();
}

class _ReporteEnviadoPageState extends State<_ReporteEnviadoPage> {
  bool _reenviado = false;

  Future<void> _reenviar() async {
    await _abrirWhatsapp(_textoWhatsapp(widget.reporte));
    try {
      final uid = context.read<Preferences>().token?.id;
      await _dio.put<dynamic>('/reportes/${widget.reporte['id']}/reenviado', data: {'usuarioId': uid});
    } catch (_) {}
    if (mounted) setState(() => _reenviado = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reporte enviado')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 10),
          Text('Reporte #${widget.reporte['id']} enviado', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Ya quedó guardado en el sistema. El administrador lo va a revisar.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Text('IMPORTANTE: tienes la obligación de reenviar este reporte al dueño por WhatsApp. Toca el botón verde y envía el mensaje.', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _reenviar,
            icon: const Icon(Icons.chat),
            label: Text(_reenviado ? 'Reenviado ✓ (tocar para repetir)' : 'Reenviar al dueño por WhatsApp'),
          ),
          const SizedBox(height: 8),
          if ((widget.reporte['imagenes'] as List?)?.isNotEmpty == true || widget.reporte['audio'] != null)
            const Text('Las fotos y el audio ya están guardados en el sistema; en WhatsApp puedes agregarlos tú también si quieres.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54)),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
        ]),
      ),
    );
  }
}

// ============================================================ LISTA / BANDEJA
class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key, this.pantalla});
  final String? pantalla;

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  bool _cargando = true;
  String? _error;
  bool _admin = false;
  int _nuevos = 0;
  List<Map<String, dynamic>> _items = [];
  String _filtro = '';

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
      final uid = context.read<Preferences>().token?.id;
      final r = await _dio.get<dynamic>('/reportes', queryParameters: {'usuarioId': uid, if (_filtro.isNotEmpty) 'estado': _filtro});
      final b = Map<String, dynamic>.from(_cuerpo(r) as Map);
      _admin = b['admin'] == true;
      _nuevos = (b['nuevos'] as num?)?.toInt() ?? 0;
      _items = [for (final e in (b['items'] as List)) Map<String, dynamic>.from(e as Map)];
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_admin ? 'Reportes de problemas' : 'Mis reportes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ReportarProblemaPage(pantalla: widget.pantalla)));
          _cargar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Reportar'),
      ),
      body: Column(children: [
        if (_admin)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              for (final e in {'': 'Todos', ..._estadoTxt}.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(e.key == 'NUEVO' && _nuevos > 0 ? '${e.value} ($_nuevos)' : e.value),
                    selected: _filtro == e.key,
                    onSelected: (_) {
                      _filtro = e.key;
                      _cargar();
                    },
                  ),
                ),
            ]),
          ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!, style: const TextStyle(color: Colors.red))))
                  : _items.isEmpty
                      ? const Center(child: Text('No hay reportes'))
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final r = _items[i];
                              final est = r['estado']?.toString() ?? 'NUEVO';
                              final fecha = DateTime.tryParse(r['createdAt']?.toString() ?? '');
                              return Card(
                                child: ListTile(
                                  onTap: () async {
                                    await Navigator.push(context, MaterialPageRoute(builder: (_) => _DetalleReportePage(id: r['id'] as int, admin: _admin)));
                                    _cargar();
                                  },
                                  title: Text('#${r['id']}  ${r['descripcion']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: Text('${r['usuarioNombre'] ?? ''} · ${r['sucursalNombre'] ?? ''}\n${fecha != null ? _fechaLima(fecha) : ''}'
                                      '${r['reenviadoAt'] == null ? '  · sin reenviar al dueño' : ''}'),
                                  isThreeLine: true,
                                  trailing: Chip(label: Text(_estadoTxt[est] ?? est, style: const TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: _estadoColor[est] ?? Colors.grey, visualDensity: VisualDensity.compact),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ]),
    );
  }
}

// ============================================================ DETALLE
class _DetalleReportePage extends StatefulWidget {
  const _DetalleReportePage({required this.id, required this.admin});
  final int id;
  final bool admin;

  @override
  State<_DetalleReportePage> createState() => _DetalleReportePageState();
}

class _DetalleReportePageState extends State<_DetalleReportePage> {
  Map<String, dynamic>? _r;
  String? _error;
  final _nota = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  bool _sonando = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _sonando = false);
    });
    _cargar();
  }

  @override
  void dispose() {
    _nota.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final uid = context.read<Preferences>().token?.id;
      final r = await _dio.get<dynamic>('/reportes/${widget.id}', queryParameters: {'usuarioId': uid});
      _r = Map<String, dynamic>.from(_cuerpo(r) as Map);
      _nota.text = _r?['nota']?.toString() ?? '';
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() {});
  }

  Future<void> _estado(String estado) async {
    setState(() => _guardando = true);
    try {
      final u = context.read<Preferences>().token;
      await _dio.put<dynamic>('/reportes/${widget.id}/estado', data: {'usuarioId': u?.id, 'usuarioNombre': u?.fullName, 'estado': estado, 'nota': _nota.text.trim()});
      await _cargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_err(e))));
    }
    if (mounted) setState(() => _guardando = false);
  }

  Future<void> _audio(String ruta) async {
    if (_sonando) {
      await _player.stop();
      setState(() => _sonando = false);
    } else {
      await _player.play(UrlSource('$endPointPrincipal/$ruta'));
      setState(() => _sonando = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return Scaffold(
      appBar: AppBar(title: Text('Reporte #${widget.id}')),
      body: r == null
          ? Center(child: _error != null ? Text(_error!, style: const TextStyle(color: Colors.red)) : const CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Chip(label: Text(_estadoTxt[r['estado']] ?? '${r['estado']}', style: const TextStyle(color: Colors.white)), backgroundColor: _estadoColor[r['estado']] ?? Colors.grey),
                const SizedBox(width: 8),
                Text(r['reenviadoAt'] == null ? 'Sin reenviar al dueño' : 'Reenviado al dueño ✓', style: TextStyle(fontSize: 12, color: r['reenviadoAt'] == null ? Colors.deepOrange : Colors.green)),
              ]),
              const SizedBox(height: 10),
              Text(r['descripcion']?.toString() ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Usuario: ${r['usuarioNombre'] ?? ''}\nSucursal: ${r['sucursalNombre'] ?? ''}\nPantalla: ${r['pantalla'] ?? ''}\nVersión: ${r['version'] ?? ''}\n'
                    'Hora (Lima): ${DateTime.tryParse(r['createdAt']?.toString() ?? '') != null ? _fechaLima(DateTime.parse(r['createdAt'].toString())) : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
              if ((r['imagenes'] as List?)?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final u in (r['imagenes'] as List))
                    GestureDetector(
                      onTap: () => showDialog<void>(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: Image.network('$endPointPrincipal/$u')))),
                      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network('$endPointPrincipal/$u', width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60))),
                    ),
                ]),
              ],
              if (r['audio'] != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: () => _audio(r['audio'].toString()), icon: Icon(_sonando ? Icons.stop : Icons.play_arrow), label: Text(_sonando ? 'Parar audio' : 'Escuchar audio')),
              ],
              const SizedBox(height: 14),
              if (r['nota'] != null && !widget.admin) ...[
                const Text('Respuesta del administrador:', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(r['nota'].toString()),
              ],
              if (widget.admin) ...[
                const Divider(),
                TextField(controller: _nota, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Respuesta / nota (la ve el trabajador)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in _estadoTxt.entries)
                    if (e.key != 'NUEVO')
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: _estadoColor[e.key]),
                        onPressed: _guardando ? null : () => _estado(e.key),
                        child: Text(e.value),
                      ),
                ]),
                if (r['revisadoPor'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Último cambio: ${r['revisadoPor']}', style: const TextStyle(fontSize: 12, color: Colors.black54))),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: () => _abrirWhatsapp(_textoWhatsapp(r)), icon: const Icon(Icons.chat), label: const Text('Reenviar por WhatsApp')),
            ]),
    );
  }
}
