import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Expediente digital de un préstamo (Etapa 1):
/// generar -> firma cliente / aval -> firma empresa -> finalizar -> ver PDF.
/// Usa los endpoints /expediente/* del servidor. `prestamoCodigo` es el código del préstamo.
class ExpedientePage extends StatefulWidget {
  const ExpedientePage({Key? key, required this.prestamoCodigo})
      : super(key: key);

  final int prestamoCodigo;

  @override
  State<ExpedientePage> createState() => _ExpedientePageState();
}

class _ExpedientePageState extends State<ExpedientePage> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: endPointPrincipal,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
    ),
  );

  Map<String, dynamic>? _exp;
  Set<String> _roles = <String>{};
  bool _loading = true;
  bool _busy = false;
  String? _error;

  int get _userId => context.read<Preferences>().token?.id ?? 0;
  bool get _esFinal => (_exp?['estado'] ?? '').toString() == 'FINAL';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  dynamic _body(Response<dynamic> r) {
    final data = r.data is String ? jsonDecode(r.data as String) : r.data;
    return data is Map ? data['body'] : null;
  }

  String _mensaje(Object e) {
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

  void _snack(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/expediente/prestamo/${widget.prestamoCodigo}');
      final b = _body(r);
      _exp = b is Map ? Map<String, dynamic>.from(b) : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _exp = null;
      } else {
        _error = _mensaje(e);
      }
    } catch (e) {
      _error = e.toString();
    }
    // Firmas ya registradas (para mostrar quién firmó)
    _roles = <String>{};
    if (_exp != null) {
      try {
        final r = await _dio.get(
            '/expediente/firmas/prestamo/${widget.prestamoCodigo}/activas');
        final b = _body(r);
        if (b is List) {
          for (final f in b) {
            if (f is Map && f['rol'] != null) {
              _roles.add(f['rol'].toString());
            }
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _accion(Future<void> Function() fn, String exito) async {
    setState(() => _busy = true);
    try {
      await fn();
      _snack(exito);
    } catch (e) {
      _snack(_mensaje(e));
    }
    if (mounted) setState(() => _busy = false);
    await _cargar();
  }

  Future<void> _generar() => _accion(() async {
        await _dio.post('/expediente/generate', data: {
          'prestamoId': widget.prestamoCodigo,
          'empresaUserId': _userId,
        });
      }, 'Expediente generado');

  Future<void> _firmar(String rol) async {
    final r = await showDialog<_FirmaResultado>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FirmaDialog(
        titulo: rol == 'AVAL' ? 'Firma del aval' : 'Firma del cliente',
        pedirDatos: true,
      ),
    );
    if (r == null) return;
    await _accion(() async {
      await _dio.post('/expediente/firmas', data: {
        'prestamoId': widget.prestamoCodigo,
        'expedienteId': _exp?['id'],
        'rol': rol,
        'firmante': r.nombre,
        if (r.dni.isNotEmpty) 'dni': r.dni,
        'firmaBase64': 'data:image/png;base64,${base64Encode(r.png)}',
      });
    }, 'Firma registrada');
  }

  Future<void> _firmaEmpresa() async {
    final r = await showDialog<_FirmaResultado>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FirmaDialog(
        titulo: 'Firma de la empresa (su firma)',
        pedirDatos: false,
      ),
    );
    if (r == null) return;
    await _accion(() async {
      final form = FormData.fromMap({
        'firma': MultipartFile.fromBytes(r.png, filename: 'firma_empresa.png'),
      });
      await _dio.put('/usuarios/$_userId/firma', data: form);
    }, 'Firma de la empresa guardada');
  }

  Future<void> _finalizar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar expediente'),
        content: const Text(
            'Al finalizar, el expediente se cierra y ya no se puede modificar. '
            'Cualquier cambio posterior generará un expediente nuevo. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Finalizar')),
        ],
      ),
    );
    if (ok != true) return;
    await _accion(() async {
      await _dio.post('/expediente/finalize', data: {
        'prestamoId': widget.prestamoCodigo,
        'empresaUserId': _userId,
        'requireFirmas': true,
      });
    }, 'Expediente finalizado');
  }

  Future<void> _verPdf() async {
    final ruta = _exp?['pdf']?.toString();
    if (ruta == null || ruta.isEmpty) {
      _snack('El expediente todavía no tiene PDF');
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await _dio.get<List<int>>(
        '$endPointPrincipal/$ruta',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(r.data ?? <int>[]);
      if (bytes.isEmpty) throw 'No se pudo descargar el PDF';
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _ExpedientePdfPage(bytes: bytes)),
      );
    } catch (e) {
      _snack(_mensaje(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _chipFirma(String etiqueta, String rol) {
    final firmado = _roles.contains(rol);
    return Chip(
      avatar: Icon(
        firmado ? Icons.check_circle : Icons.radio_button_unchecked,
        color: firmado ? Colors.green : Colors.grey,
        size: 18,
      ),
      label: Text(etiqueta),
    );
  }

  Widget _boton(String texto, IconData icono, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _busy ? null : onTap,
          icon: Icon(icono),
          label: Text(texto),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = (_exp?['estado'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(
        title: Text('Expediente - Préstamo ${widget.prestamoCodigo}'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _exp == null
                              ? 'Aún no se generó el expediente'
                              : _esFinal
                                  ? 'Expediente FINAL (cerrado, no se puede modificar)'
                                  : 'Expediente generado ($estado): faltan firmas / finalizar',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (_exp != null) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              _chipFirma('Cliente', 'CLIENTE'),
                              _chipFirma('Aval', 'AVAL'),
                              _chipFirma('Empresa', 'EMPRESA'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_busy) const LinearProgressIndicator(),
                if (_busy) const SizedBox(height: 12),
                if (_exp == null)
                  _boton('Generar expediente', Icons.note_add, _generar),
                if (_exp != null && !_esFinal) ...[
                  _boton('Firma del cliente', Icons.draw,
                      () => _firmar('CLIENTE')),
                  _boton('Firma del aval', Icons.draw_outlined,
                      () => _firmar('AVAL')),
                  _boton('Registrar firma de la empresa (mi firma)',
                      Icons.business, _firmaEmpresa),
                  _boton('Finalizar expediente', Icons.lock, _finalizar),
                ],
                if (_exp != null)
                  _boton('Ver PDF del expediente', Icons.picture_as_pdf,
                      _verPdf),
              ],
            ),
    );
  }
}

class _ExpedientePdfPage extends StatelessWidget {
  const _ExpedientePdfPage({Key? key, required this.bytes}) : super(key: key);

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
// Firma dibujada con el dedo
// ---------------------------------------------------------------------------

class _FirmaResultado {
  _FirmaResultado(this.png, this.nombre, this.dni);
  final Uint8List png;
  final String nombre;
  final String dni;
}

class _SignatureController extends ChangeNotifier {
  final List<List<Offset>> strokes = <List<Offset>>[];

  bool get isEmpty => strokes.isEmpty;

  void start(Offset p) {
    strokes.add(<Offset>[p]);
    notifyListeners();
  }

  void add(Offset p) {
    if (strokes.isEmpty) return;
    strokes.last.add(p);
    notifyListeners();
  }

  void clear() {
    strokes.clear();
    notifyListeners();
  }

  Future<Uint8List?> toPng(Size size) async {
    if (isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    _paintSignature(canvas, strokes);
    final image = await recorder
        .endRecording()
        .toImage(size.width.round(), size.height.round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }
}

void _paintSignature(Canvas canvas, List<List<Offset>> strokes) {
  final paint = Paint()
    ..color = Colors.black
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  for (final s in strokes) {
    if (s.isEmpty) continue;
    if (s.length == 1) {
      canvas.drawPoints(ui.PointMode.points, s, paint);
      continue;
    }
    final path = Path()..moveTo(s.first.dx, s.first.dy);
    for (var i = 1; i < s.length; i++) {
      path.lineTo(s[i].dx, s[i].dy);
    }
    canvas.drawPath(path, paint);
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) => _paintSignature(canvas, strokes);

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class _FirmaDialog extends StatefulWidget {
  const _FirmaDialog({Key? key, required this.titulo, required this.pedirDatos})
      : super(key: key);

  final String titulo;
  final bool pedirDatos;

  @override
  State<_FirmaDialog> createState() => _FirmaDialogState();
}

class _FirmaDialogState extends State<_FirmaDialog> {
  final _SignatureController _ctrl = _SignatureController();
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _dni = TextEditingController();
  Size _size = const Size(300, 180);

  @override
  void dispose() {
    _ctrl.dispose();
    _nombre.dispose();
    _dni.dispose();
    super.dispose();
  }

  void _aviso(String t) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _aceptar() async {
    if (widget.pedirDatos && _nombre.text.trim().isEmpty) {
      _aviso('Escriba el nombre de quien firma');
      return;
    }
    final png = await _ctrl.toPng(_size);
    if (png == null) {
      _aviso('Dibuje la firma con el dedo');
      return;
    }
    if (!mounted) return;
    Navigator.of(context)
        .pop(_FirmaResultado(png, _nombre.text.trim(), _dni.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.titulo,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (widget.pedirDatos) ...[
              TextField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Nombre de quien firma',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _dni,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'DNI (opcional)',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  _size = Size(c.maxWidth, c.maxHeight);
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _ctrl.start(e.localPosition),
                    onPointerMove: (e) => _ctrl.add(e.localPosition),
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) => CustomPaint(
                        painter: _SignaturePainter(_ctrl.strokes),
                        size: Size.infinite,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            const Text('Firme dentro del recuadro',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _ctrl.clear, child: const Text('Limpiar')),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar')),
                ElevatedButton(
                    onPressed: _aceptar, child: const Text('Aceptar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
