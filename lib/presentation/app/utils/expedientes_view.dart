import 'dart:typed_data';

import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/expediente_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

// ---------------------------------------------------------------------------
// Módulo "Expedientes": lista de expedientes + historial de cada uno.
// Usa las rutas /expediente-modulo del servidor (solo lectura).
// ---------------------------------------------------------------------------

Dio _crearDio() => Dio(
      BaseOptions(
        baseUrl: endPointPrincipal,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );

dynamic _cuerpo(Response<dynamic> r) {
  final data = r.data;
  return data is Map ? data['body'] : null;
}

String _mensajeError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      return m is List ? m.join(', ') : m.toString();
    }
    return e.message ?? 'Error de conexión';
  }
  return e.toString();
}

String _fechaHora(dynamic v) {
  if (v == null) return '-';
  final d = DateTime.tryParse(v.toString());
  if (d == null) return v.toString();
  final l = d.toLocal();
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(l.day)}/${dos(l.month)}/${l.year} ${dos(l.hour)}:${dos(l.minute)}';
}

String _nombreCliente(dynamic c) {
  if (c is! Map) return 'Sin cliente';
  final n = '${c['nombres'] ?? ''} ${c['apellidos'] ?? ''}'.trim();
  return n.isEmpty ? 'Sin cliente' : n;
}

Future<void> _abrirPdf(BuildContext context, Dio dio, String ruta) async {
  try {
    final r = await dio.get<List<int>>(
      '$endPointPrincipal/$ruta',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(r.data ?? <int>[]);
    if (bytes.isEmpty) throw 'No se pudo descargar el PDF';
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _VisorPdf(bytes: bytes)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_mensajeError(e))));
  }
}

class _VisorPdf extends StatelessWidget {
  const _VisorPdf({Key? key, required this.bytes}) : super(key: key);

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expediente digital')),
      body: PdfPreview(
        pdfFileName: 'expediente.pdf',
        initialPageFormat: PdfPageFormat.a4,
        pageFormats: const <String, PdfPageFormat>{'A4': PdfPageFormat.a4},
        canChangeOrientation: false,
        canDebug: false,
        build: (_) => bytes,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de expedientes
// ---------------------------------------------------------------------------

class ExpedientesView extends StatefulWidget {
  const ExpedientesView({Key? key}) : super(key: key);

  @override
  State<ExpedientesView> createState() => _ExpedientesViewState();
}

class _ExpedientesViewState extends State<ExpedientesView> {
  static const int _pagina = 20;

  final Dio _dio = _crearDio();
  final TextEditingController _buscar = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  String _estado = ''; // '' = todos, GENERADO = en proceso, FINAL = finalizados
  int _total = 0;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
          !_cargando &&
          _items.length < _total) {
        _cargar();
      }
    });
    _cargar(reiniciar: true);
  }

  @override
  void dispose() {
    _buscar.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool reiniciar = false}) async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
      if (reiniciar) {
        _items.clear();
        _total = 0;
      }
    });
    try {
      final r = await _dio.get('/expediente-modulo', queryParameters: {
        'limit': _pagina,
        'offset': _items.length,
        if (_buscar.text.trim().isNotEmpty) 'q': _buscar.text.trim(),
        if (_estado.isNotEmpty) 'estado': _estado,
      });
      final b = _cuerpo(r);
      if (b is Map) {
        final lista = b['items'];
        if (lista is List) {
          for (final x in lista) {
            if (x is Map) _items.add(Map<String, dynamic>.from(x));
          }
        }
        _total = (b['total'] as num?)?.toInt() ?? _items.length;
      }
    } catch (e) {
      _error = _mensajeError(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Widget _chipFiltro(String texto, String valor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: _estado == valor,
        onSelected: (_) {
          _estado = valor;
          _cargar(reiniciar: true);
        },
      ),
    );
  }

  Widget _marca(String texto, bool activo) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            activo ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: activo ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 3),
          Text(texto, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> it) {
    final esFinal = (it['estado'] ?? '').toString() == 'FINAL';
    final firmas = (it['firmas'] is List)
        ? (it['firmas'] as List).map((e) => e.toString()).toSet()
        : <String>{};
    final cliente = it['cliente'];
    final dni = cliente is Map ? (cliente['dni'] ?? '').toString() : '';
    final codigo = (it['prestamoId'] as num?)?.toInt() ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpedienteHistorialPage(prestamoCodigo: codigo),
            ),
          );
          if (mounted) _cargar(reiniciar: true);
        },
        leading: CircleAvatar(
          backgroundColor: esFinal ? Colors.green.shade100 : Colors.orange.shade100,
          child: Icon(
            esFinal ? Icons.lock : Icons.edit_note,
            color: esFinal ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        ),
        title: Text(
          'Préstamo N° $codigo - ${_nombreCliente(cliente)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dni.isNotEmpty) Text('DNI: $dni'),
            Text('Creado: ${_fechaHora(it['createdAt'])}'),
            if (esFinal) Text('Finalizado: ${_fechaHora(it['finalizedAt'])}'),
            const SizedBox(height: 4),
            Wrap(
              children: [
                _marca('Cliente', firmas.contains('CLIENTE')),
                _marca('Aval', firmas.contains('AVAL')),
                _marca('Empresa', firmas.contains('EMPRESA')),
                _marca('Huella', it['huella'] == true),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Chip(
          label: Text(
            esFinal ? 'FINAL' : 'EN PROCESO',
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: esFinal ? Colors.green.shade50 : Colors.orange.shade50,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: _buscar,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _cargar(reiniciar: true),
            decoration: InputDecoration(
              hintText: 'Buscar por DNI, nombre o N° de préstamo',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _buscar.clear();
                  _cargar(reiniciar: true);
                },
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chipFiltro('Todos', ''),
              _chipFiltro('En proceso', 'GENERADO'),
              _chipFiltro('Finalizados', 'FINAL'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('$_total expedientes',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _cargar(reiniciar: true),
            child: ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _items.length + 1,
              itemBuilder: (context, i) {
                if (i < _items.length) return _tarjeta(_items[i]);
                if (_cargando) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (_error != null) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  );
                }
                if (_items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('No hay expedientes para mostrar.',
                        textAlign: TextAlign.center),
                  );
                }
                return const SizedBox(height: 20);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Historial de un expediente
// ---------------------------------------------------------------------------

class ExpedienteHistorialPage extends StatefulWidget {
  const ExpedienteHistorialPage({Key? key, required this.prestamoCodigo})
      : super(key: key);

  final int prestamoCodigo;

  @override
  State<ExpedienteHistorialPage> createState() =>
      _ExpedienteHistorialPageState();
}

class _ExpedienteHistorialPageState extends State<ExpedienteHistorialPage> {
  final Dio _dio = _crearDio();
  Map<String, dynamic>? _datos;
  List<Map<String, dynamic>> _eventos = <Map<String, dynamic>>[];
  bool _cargando = true;
  String? _error;

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
      final r = await _dio
          .get('/expediente-modulo/historial/${widget.prestamoCodigo}');
      final b = _cuerpo(r);
      if (b is Map) {
        _datos = Map<String, dynamic>.from(b);
        _eventos = <Map<String, dynamic>>[];
        final ev = b['eventos'];
        if (ev is List) {
          for (final x in ev) {
            if (x is Map) _eventos.add(Map<String, dynamic>.from(x));
          }
        }
      }
    } catch (e) {
      _error = _mensajeError(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  IconData _icono(String tipo) {
    switch (tipo) {
      case 'FIRMA':
        return Icons.draw;
      case 'HUELLA':
        return Icons.fingerprint;
      case 'EXPEDIENTE_FINALIZADO':
        return Icons.lock;
      case 'VERSION_FINAL':
        return Icons.verified;
      case 'COMPROBANTE':
        return Icons.attach_file;
      default:
        return Icons.note_add;
    }
  }

  Widget _evento(Map<String, dynamic> e) {
    final tipo = (e['tipo'] ?? '').toString();
    final url = e['url']?.toString();
    final pdf = e['pdf']?.toString();
    final detalle = (e['detalle'] ?? '').toString();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(_icono(tipo), color: Colors.blue.shade800),
        ),
        title: Text((e['titulo'] ?? '').toString(),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_fechaHora(e['fecha']),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (detalle.isNotEmpty) Text(detalle),
            if (pdf != null && pdf.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _abrirPdf(context, _dio, pdf),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Ver PDF'),
                ),
              ),
          ],
        ),
        trailing: (url != null && url.isNotEmpty)
            ? Image.network(
                '$endPointPrincipal/$url',
                width: 64,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ultimo = _datos?['ultimoExpediente'];
    final pdfActual = ultimo is Map ? ultimo['pdf']?.toString() : null;
    final estado = ultimo is Map ? (ultimo['estado'] ?? '').toString() : '';
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial - Préstamo N° ${widget.prestamoCodigo}'),
        actions: [
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_nombreCliente(_datos?['cliente']),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              if (_datos?['cliente'] is Map)
                                Text(
                                    'DNI: ${(_datos?['cliente'] as Map)['dni'] ?? ''}'),
                              if (_datos?['monto'] != null)
                                Text('Monto del préstamo: S/ ${_datos?['monto']}'),
                              Text(
                                estado.isEmpty
                                    ? 'Todavía no tiene expediente'
                                    : estado == 'FINAL'
                                        ? 'Expediente FINAL (cerrado)'
                                        : 'Expediente en proceso',
                                style: TextStyle(
                                    color: estado == 'FINAL'
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (pdfActual != null && pdfActual.isNotEmpty)
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _abrirPdf(context, _dio, pdfActual),
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Ver PDF actual'),
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ExpedientePage(
                                              prestamoCodigo:
                                                  widget.prestamoCodigo),
                                        ),
                                      );
                                      if (mounted) _cargar();
                                    },
                                    icon: const Icon(Icons.draw),
                                    label: Text(estado == 'FINAL'
                                        ? 'Abrir expediente'
                                        : 'Firmar / finalizar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
                        child: Text('Historial (lo más reciente primero)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (_eventos.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Este préstamo todavía no tiene historial.',
                              textAlign: TextAlign.center),
                        ),
                      ..._eventos.map(_evento),
                    ],
                  ),
                ),
    );
  }
}
