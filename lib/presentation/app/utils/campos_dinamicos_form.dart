import 'dart:convert';
import 'dart:io';

import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ---------------------------------------------------------------------------
// Campos extra por categoría para el formulario de bienes en garantía.
// Los campos se crean en Administración > Campos. Aquí se muestran según la
// categoría elegida y sus valores se guardan junto a las observaciones del bien.
// ---------------------------------------------------------------------------

/// Guarda lo que se va escribiendo en los campos extra del bien actual.
class CamposDinamicosEstado {
  static final Map<int, String> valores = <int, String>{};
  static final Map<int, String> etiquetas = <int, String>{};
  static final Set<int> obligatorios = <int>{};
  static final ValueNotifier<int> reinicio = ValueNotifier<int>(0);

  /// Borra lo escrito (se usa al guardar un bien o al empezar uno nuevo).
  static void limpiar() {
    valores.clear();
    etiquetas.clear();
    obligatorios.clear();
    reinicio.value++;
  }

  /// Nombres de los campos obligatorios que todavía están vacíos.
  static List<String> faltantes() {
    final out = <String>[];
    for (final id in obligatorios) {
      if ((valores[id] ?? '').trim().isEmpty) out.add(etiquetas[id] ?? 'Campo');
    }
    return out;
  }

  /// Texto para guardar junto a las observaciones: "Placa: ABC-123 | Color: Rojo".
  static String resumen() {
    final partes = <String>[];
    valores.forEach((id, v) {
      if (v.trim().isNotEmpty) partes.add('${etiquetas[id] ?? 'Campo'}: ${v.trim()}');
    });
    return partes.join(' | ');
  }
}

List<String> _opciones(dynamic o) {
  if (o == null) return <String>[];
  final s = o.toString().trim();
  if (s.isEmpty) return <String>[];
  try {
    final d = jsonDecode(s);
    if (d is List) return d.map((e) => e.toString()).toList();
  } catch (_) {}
  return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

InputDecoration _deco(String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    );

class CamposDinamicosForm extends StatefulWidget {
  const CamposDinamicosForm({Key? key, required this.categoriaId})
      : super(key: key);

  final int? categoriaId;

  @override
  State<CamposDinamicosForm> createState() => _CamposDinamicosFormState();
}

class _CamposDinamicosFormState extends State<CamposDinamicosForm> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: endPointPrincipal,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  List<Map<String, dynamic>> _campos = <Map<String, dynamic>>[];
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    CamposDinamicosEstado.limpiar();
    CamposDinamicosEstado.reinicio.addListener(_alReiniciar);
    _cargar();
  }

  @override
  void dispose() {
    CamposDinamicosEstado.reinicio.removeListener(_alReiniciar);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CamposDinamicosForm old) {
    super.didUpdateWidget(old);
    if (old.categoriaId != widget.categoriaId) _cargar();
  }

  void _alReiniciar() {
    if (mounted) setState(() => _gen++);
  }

  Future<void> _cargar() async {
    CamposDinamicosEstado.valores.clear();
    CamposDinamicosEstado.etiquetas.clear();
    CamposDinamicosEstado.obligatorios.clear();
    final id = widget.categoriaId;
    final lista = <Map<String, dynamic>>[];
    if (id != null) {
      try {
        final r = await _dio.get('/api/dynamic-fields/definitions',
            queryParameters: {
              'category_id': id,
              'is_active': true,
              'include_parent': true,
            });
        final data = r.data;
        if (data is List) {
          for (final x in data) {
            if (x is Map && x['is_active'] != false) {
              lista.add(Map<String, dynamic>.from(x));
            }
          }
        }
        lista.sort((a, b) => ((a['display_order'] as num?) ?? 0)
            .compareTo((b['display_order'] as num?) ?? 0));
        for (final c in lista) {
          final cid = (c['id'] as num).toInt();
          CamposDinamicosEstado.etiquetas[cid] = (c['label'] ?? '').toString();
          if (c['is_required'] == true) CamposDinamicosEstado.obligatorios.add(cid);
        }
      } catch (_) {
        // Sin conexión o sin campos: el formulario sigue funcionando normal
      }
    }
    if (mounted) {
      setState(() {
        _campos = lista;
        _gen++;
      });
    }
  }

  Widget _campo(Map<String, dynamic> c) {
    final id = (c['id'] as num).toInt();
    final label = '${c['label']}${c['is_required'] == true ? ' *' : ''}';
    final tipo = (c['field_type'] ?? 'text').toString();
    final key = ValueKey<String>('$_gen-$id');
    void guardar(String v) => CamposDinamicosEstado.valores[id] = v;
    switch (tipo) {
      case 'number':
        return TextFormField(
          key: key,
          keyboardType: TextInputType.number,
          decoration: _deco(label),
          onChanged: guardar,
        );
      case 'date':
        return _CampoFecha(key: key, label: label, onChanged: guardar);
      case 'select':
        return DropdownButtonFormField<String>(
          key: key,
          decoration: _deco(label),
          items: [
            for (final o in _opciones(c['options']))
              DropdownMenuItem<String>(value: o, child: Text(o)),
          ],
          onChanged: (v) => guardar(v ?? ''),
        );
      case 'textarea':
        return TextFormField(
          key: key,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: _deco(label),
          onChanged: guardar,
        );
      case 'checkbox':
        return _CampoSiNo(key: key, label: label, onChanged: guardar);
      case 'photo':
      case 'file':
        return _CampoFoto(
          key: key,
          label: label,
          dio: _dio,
          esDocumento: tipo == 'file',
          onChanged: guardar,
        );
      case 'multi-select':
        return _CampoMulti(
          key: key,
          label: label,
          opciones: _opciones(c['options']),
          onChanged: guardar,
        );
      default:
        return TextFormField(
          key: key,
          textCapitalization: TextCapitalization.sentences,
          decoration: _deco(label),
          onChanged: guardar,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_campos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Datos extra de esta categoría',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Llene solo lo que tenga a la mano; todo es opcional '
            'salvo lo marcado con *.',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        for (final c in _campos) ...[
          _campo(c),
          const SizedBox(height: 15),
        ],
      ],
    );
  }
}

class _CampoFecha extends StatefulWidget {
  const _CampoFecha({Key? key, required this.label, required this.onChanged})
      : super(key: key);

  final String label;
  final ValueChanged<String> onChanged;

  @override
  State<_CampoFecha> createState() => _CampoFechaState();
}

class _CampoFechaState extends State<_CampoFecha> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _elegir() async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: DateTime(1990),
      lastDate: DateTime(hoy.year + 20),
    );
    if (d == null) return;
    String dos(int n) => n.toString().padLeft(2, '0');
    final texto = '${dos(d.day)}/${dos(d.month)}/${d.year}';
    _c.text = texto;
    widget.onChanged(texto);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _c,
      readOnly: true,
      onTap: _elegir,
      decoration: _deco(widget.label).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
    );
  }
}

class _CampoMulti extends StatefulWidget {
  const _CampoMulti({
    Key? key,
    required this.label,
    required this.opciones,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final List<String> opciones;
  final ValueChanged<String> onChanged;

  @override
  State<_CampoMulti> createState() => _CampoMultiState();
}

class _CampoMultiState extends State<_CampoMulti> {
  final Set<String> _sel = <String>{};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 13)),
        Wrap(
          spacing: 8,
          children: [
            for (final o in widget.opciones)
              FilterChip(
                label: Text(o),
                selected: _sel.contains(o),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _sel.add(o);
                    } else {
                      _sel.remove(o);
                    }
                  });
                  widget.onChanged(_sel.join(', '));
                },
              ),
          ],
        ),
      ],
    );
  }
}


class _CampoSiNo extends StatefulWidget {
  const _CampoSiNo(
      {Key? key, required this.label, required this.onChanged})
      : super(key: key);

  final String label;
  final ValueChanged<String> onChanged;

  @override
  State<_CampoSiNo> createState() => _CampoSiNoState();
}

class _CampoSiNoState extends State<_CampoSiNo> {
  bool _v = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(_v ? 'Sí' : 'No'),
      value: _v,
      onChanged: (x) {
        setState(() => _v = x);
        widget.onChanged(x ? 'Sí' : 'No');
      },
    );
  }
}

/// Foto (o foto de un documento): se toma o se elige, se sube al servidor y
/// el campo guarda el enlace.
class _CampoFoto extends StatefulWidget {
  const _CampoFoto({
    Key? key,
    required this.label,
    required this.dio,
    required this.esDocumento,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final Dio dio;
  final bool esDocumento;
  final ValueChanged<String> onChanged;

  @override
  State<_CampoFoto> createState() => _CampoFotoState();
}

class _CampoFotoState extends State<_CampoFoto> {
  final List<String> _rutas = <String>[];
  final List<String> _urls = <String>[];
  final List<bool> _esPdf = <bool>[];
  bool _subiendo = false;
  String? _error;

  Future<void> _agregar() async {
    // 'pdf' = archivo PDF del teléfono
    final fuente = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (widget.esDocumento)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Subir un archivo PDF'),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
          ],
        ),
      ),
    );
    if (fuente == null) return;
    try {
      String? path;
      String? nombre;
      var pdf = false;
      if (fuente == 'pdf') {
        final r = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (r == null || r.files.isEmpty || r.files.first.path == null) return;
        path = r.files.first.path!;
        nombre = r.files.first.name;
        pdf = true;
      } else {
        final f = await ImagePicker().pickImage(
          source: fuente == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 70,
          maxWidth: 1800,
        );
        if (f == null) return;
        path = f.path;
        nombre = f.name;
      }
      setState(() {
        _subiendo = true;
        _error = null;
      });
      final form = FormData.fromMap({
        'archivo': await MultipartFile.fromFile(path, filename: nombre),
      });
      final r = await widget.dio.post('/api/dynamic-fields/archivo', data: form);
      final data = r.data;
      final ruta = data is Map ? (data['ruta'] ?? data['url'])?.toString() : null;
      if (ruta == null || ruta.isEmpty) throw Exception('Respuesta inválida');
      setState(() {
        _rutas.add(path!);
        _esPdf.add(pdf);
        _urls.add('$endPointPrincipal/$ruta');
      });
      widget.onChanged(_urls.join(' , '));
    } catch (_) {
      setState(() => _error = 'No se pudo subir el archivo. Revise su internet e intente otra vez.');
    }
    if (mounted) setState(() => _subiendo = false);
  }

  void _quitar(int i) {
    setState(() {
      _rutas.removeAt(i);
      _esPdf.removeAt(i);
      _urls.removeAt(i);
    });
    widget.onChanged(_urls.join(' , '));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _rutas.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _esPdf[i]
                        ? Container(
                            width: 80,
                            height: 80,
                            color: Colors.red.withOpacity(0.08),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                                Text('PDF', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          )
                        : Image.file(File(_rutas[i]),
                            width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () => _quitar(i),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (_subiendo)
              const SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(child: CircularProgressIndicator())),
            OutlinedButton.icon(
              onPressed: _subiendo ? null : _agregar,
              icon: Icon(widget.esDocumento
                  ? Icons.description_outlined
                  : Icons.add_a_photo_outlined),
              label: Text(_rutas.isEmpty
                  ? (widget.esDocumento ? 'Agregar documento' : 'Agregar foto')
                  : 'Agregar otro'),
            ),
          ],
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }
}
