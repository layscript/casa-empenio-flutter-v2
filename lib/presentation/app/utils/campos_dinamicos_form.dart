import 'dart:convert';

import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
            queryParameters: {'category_id': id, 'is_active': true});
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
