import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/custom_image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Expediente digital de un préstamo.
/// - Generar expediente
/// - Firma cliente (auto-llenado desde el préstamo) y aval (si existe)
/// - Firma de la empresa (se guarda y reutiliza)
/// - Evidencia fotográfica (mínimo 1, máximo 3)
/// - Finalizar y ver PDF
class ExpedientePage extends StatefulWidget {
  const ExpedientePage({
    Key? key,
    required this.prestamoCodigo,
    this.autoFlujo = false,
  }) : super(key: key);

  final int prestamoCodigo;

  /// Si es true (al terminar de crear un préstamo): genera el expediente,
  /// pide la firma del cliente (y aval), la huella, la firma de la empresa
  /// y ofrece finalizar, todo seguido.
  final bool autoFlujo;

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
  List<Map<String, dynamic>> _huellas = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  LoansEntity? _loan;
  Uint8List? _empresaFirmaPng;

  final TextEditingController _obsCtrl = TextEditingController();
  List<XFile> _evidencias = [];

  int get _userId => context.read<Preferences>().token?.id ?? 0;
  String get _userFullName => context.read<Preferences>().token?.fullName ?? '';
  bool get _esFinal => (_exp?['estado'] ?? '').toString() == 'FINAL';
  String get _prefKey => 'empresa_firma_base64_${_userId}';

  @override
  void initState() {
    super.initState();
    _cargar().then((_) {
      if (widget.autoFlujo && mounted) _flujoAutomatico();
    });
    _cargarFirmaEmpresa();
  }

  bool _autoEnCurso = false;

  /// Flujo seguido para firmar directo con el cliente y cerrar el expediente.
  /// Si en algún paso se cancela, se detiene y queda todo en la pantalla normal.
  Future<void> _flujoAutomatico() async {
    if (_autoEnCurso) return;
    _autoEnCurso = true;
    try {
      if (_esFinal) return;
      // 1) Generar el expediente si todavía no existe
      if (_exp == null) {
        await _generar();
        if (!mounted || _exp == null) return;
      }
      // 2) Firma del cliente
      if (!_roles.contains('CLIENTE')) {
        await _firmar('CLIENTE');
        if (!mounted || !_roles.contains('CLIENTE')) return;
      }
      // 3) Firma del aval (solo si el préstamo tiene aval)
      final tieneAval = _avalNombre().isNotEmpty || _avalDni().isNotEmpty;
      if (tieneAval && !_roles.contains('AVAL')) {
        await _firmar('AVAL');
        if (!mounted) return;
      }
      // 4) Huella del cliente (opcional)
      if (_huellas.isEmpty) {
        final capturar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Huella del cliente'),
            content: const Text(
                '¿Desea capturar la huella del cliente ahora con el lector?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Omitir')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Capturar huella')),
            ],
          ),
        );
        if (!mounted) return;
        if (capturar == true) {
          await _capturarHuella();
          if (!mounted) return;
        }
      }
      // 5) Firma de la empresa (se reutiliza la guardada)
      if (!_roles.contains('EMPRESA')) {
        await _firmaEmpresa();
        if (!mounted) return;
      }
      // 6) Finalizar (pregunta antes de cerrar el expediente)
      if (!_esFinal && _roles.contains('CLIENTE')) {
        await _finalizar();
      }
    } finally {
      _autoEnCurso = false;
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
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

    // Huella del cliente ya guardada
    _huellas = <Map<String, dynamic>>[];
    if (_exp != null) {
      try {
        final r = await _dio.get(
            '/expediente/huellas/prestamo/${widget.prestamoCodigo}/activas');
        final b = _body(r);
        if (b is List) {
          for (final h in b) {
            if (h is Map) _huellas.add(Map<String, dynamic>.from(h));
          }
        }
      } catch (_) {}
    }

    try {
      final loansRepo = context.read<LoansRepository>();
      final res = await loansRepo.getLoan(
        id: widget.prestamoCodigo,
        userId: _userId,
      );
      res.fold((_) {}, (loan) => _loan = loan);
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cargarFirmaEmpresa() async {
    try {
      if (_userId == 0) return;
      final prefs = await SharedPreferences.getInstance();
      final b64 = prefs.getString(_prefKey);
      if (b64 != null && b64.isNotEmpty) {
        _empresaFirmaPng = base64Decode(b64);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  String _clienteNombre() => _loan?.cliente?.customerFullName ?? '';
  String _clienteDni() => _loan?.cliente?.dni ?? '';
  String _avalNombre() => _loan?.aval?.customerFullName ?? '';
  String _avalDni() => _loan?.aval?.dni ?? '';

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
    final esAval = rol == 'AVAL';
    final r = await showDialog<_FirmaResultado>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FirmaDialog(
        titulo: esAval ? 'Firma del aval' : 'Firma del cliente',
        pedirDatos: true,
        nombreInicial: esAval ? _avalNombre() : _clienteNombre(),
        dniInicial: esAval ? _avalDni() : _clienteDni(),
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

  Future<void> _postFirmaEmpresa(Uint8List png) async {
    await _dio.put(
      '/usuarios/$_userId/firma',
      data: FormData.fromMap({
        'firma': MultipartFile.fromBytes(png, filename: 'firma_empresa.png'),
      }),
    );
    await _dio.post('/expediente/firmas', data: {
      'prestamoId': widget.prestamoCodigo,
      'expedienteId': _exp?['id'],
      'rol': 'EMPRESA',
      'firmante': _userFullName,
      'firmaBase64': 'data:image/png;base64,${base64Encode(png)}',
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, base64Encode(png));
    _empresaFirmaPng = png;
  }

  Future<void> _firmaEmpresa() async {
    if (_roles.contains('EMPRESA')) {
      _snack('La empresa ya firmó este expediente');
      return;
    }
    if (_empresaFirmaPng != null) {
      await _accion(() => _postFirmaEmpresa(_empresaFirmaPng!), 'Firma de la empresa registrada');
      await _cargarFirmaEmpresa();
      return;
    }
    final r = await showDialog<_FirmaResultado>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FirmaDialog(
        titulo: 'Firma de la empresa (su firma)',
        pedirDatos: false,
        firmanteNombre: _userFullName,
      ),
    );
    if (r == null) return;
    await _accion(() => _postFirmaEmpresa(r.png), 'Firma de la empresa guardada');
    await _cargarFirmaEmpresa();
  }

  Future<void> _guardarEvidencia() async {
    if (_evidencias.isEmpty) {
      _snack('Agrega al menos 1 foto');
      return;
    }
    if (_obsCtrl.text.trim().isEmpty) {
      _snack('Escribe una observación');
      return;
    }
    await _accion(() async {
      final repo = context.read<AnexoRepository>();
      for (final foto in _evidencias) {
        final urlRes = await repo.createImage(path: foto.path);
        final url = urlRes.fold((e) => throw Exception(e), (u) => u);
        final ok = await repo.createAnexo(
          description: _obsCtrl.text.trim(),
          url: [
            {'url': url}
          ],
          prestamoId: widget.prestamoCodigo.toString(),
        );
        final exito = ok.fold((l) => false, (r) => r);
        if (!exito) throw Exception('No se pudo guardar la evidencia');
      }
      if (mounted) {
        _evidencias = [];
        _obsCtrl.clear();
      }
    }, 'Evidencia guardada');
  }

  Future<void> _capturarHuella() async {
    final res = await showDialog<_HuellaResultado>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _HuellaDialog(),
    );
    if (res == null) return;
    await _accion(() async {
      await _dio.post('/expediente/huellas', data: {
        'prestamoId': widget.prestamoCodigo,
        'expedienteId': _exp?['id'],
        'rol': 'CLIENTE',
        'templateBase64': res.template,
        'templateType': res.templateType,
        'imageDataUrl': 'data:image/png;base64,${res.image}',
        'quality': res.quality,
      });
    }, 'Huella del cliente guardada.');
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

  Widget _chipHuella() {
    final guardada = _huellas.isNotEmpty;
    return Chip(
      avatar: Icon(
        guardada ? Icons.check_circle : Icons.radio_button_unchecked,
        color: guardada ? Colors.green : Colors.grey,
        size: 18,
      ),
      label: const Text('Huella'),
    );
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
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _busy ? null : onTap,
          icon: Icon(icono),
          label: Text(texto),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo, IconData icono, List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = (_exp?['estado'] ?? '').toString();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expediente digital'),
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
                  _seccion(
                    'Error',
                    Icons.error_outline,
                    [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                _seccion(
                  'Estado del expediente',
                  Icons.info_outline,
                  [
                    Text(
                      _exp == null
                          ? 'Aún no se generó el expediente'
                          : _esFinal
                              ? 'Expediente FINAL (cerrado, no se puede modificar)'
                              : 'Expediente generado ($estado): faltan firmas / finalizar',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (_exp != null) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _chipFirma('Cliente', 'CLIENTE'),
                          _chipFirma('Aval', 'AVAL'),
                          _chipFirma('Empresa', 'EMPRESA'),
                          _chipHuella(),
                        ],
                      ),
                    ],
                  ],
                ),
                if (_busy) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                if (_exp == null)
                  _seccion(
                    'Generar',
                    Icons.note_add,
                    [
                      _boton('Generar expediente', Icons.note_add, _generar),
                    ],
                  ),
                if (_exp != null && !_esFinal) ...[
                  _seccion(
                    'Firmas',
                    Icons.draw,
                    [
                      _boton('Firma del cliente', Icons.draw,
                          () => _firmar('CLIENTE')),
                      _boton('Firma del aval', Icons.draw_outlined,
                          () => _firmar('AVAL')),
                      _boton(
                          _huellas.isNotEmpty
                              ? 'Volver a capturar huella (cliente)'
                              : 'Capturar huella del cliente',
                          Icons.fingerprint,
                          _capturarHuella),
                      if (_empresaFirmaPng == null)
                        _boton(
                          'Registrar firma de la empresa (mi firma)',
                          Icons.business,
                          _roles.contains('EMPRESA') ? null : _firmaEmpresa,
                        )
                      else
                        _boton(
                          'Registrar firma de empresa guardada',
                          Icons.business,
                          _roles.contains('EMPRESA') ? null : _firmaEmpresa,
                        ),
                      _boton('Finalizar expediente', Icons.lock, _finalizar),
                    ],
                  ),
                  _seccion(
                    'Evidencia fotográfica',
                    Icons.photo_camera,
                    [
                      const Text(
                        'Mínimo 1 foto, máximo 3. Agrega observación y guarda.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _obsCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Observación / constancia',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomImagePicker(
                        onImagesSelected: (photos) {
                          setState(() {
                            _evidencias = photos ?? [];
                          });
                        },
                        initialSelectedPhotos: _evidencias,
                        limit: 3,
                      ),
                      const SizedBox(height: 10),
                      _boton(
                        'Guardar evidencia',
                        Icons.save_alt,
                        _evidencias.isEmpty ? null : _guardarEvidencia,
                      ),
                    ],
                  ),
                ],
                if (_exp != null)
                  _seccion(
                    'Documento',
                    Icons.picture_as_pdf,
                    [
                      _boton('Ver PDF del expediente', Icons.picture_as_pdf,
                          _verPdf),
                    ],
                  ),
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
  const _FirmaDialog({
    Key? key,
    required this.titulo,
    required this.pedirDatos,
    this.nombreInicial,
    this.dniInicial,
    this.firmanteNombre,
  }) : super(key: key);

  final String titulo;
  final bool pedirDatos;
  final String? nombreInicial;
  final String? dniInicial;
  final String? firmanteNombre;

  @override
  State<_FirmaDialog> createState() => _FirmaDialogState();
}

class _FirmaDialogState extends State<_FirmaDialog> {
  final _SignatureController _ctrl = _SignatureController();
  late final TextEditingController _nombre;
  late final TextEditingController _dni;
  Size _size = const Size(300, 180);

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.nombreInicial ?? '');
    _dni = TextEditingController(text: widget.dniInicial ?? '');
  }

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
      insetPadding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.titulo,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (widget.firmanteNombre != null &&
                  widget.firmanteNombre!.isNotEmpty &&
                  !widget.pedirDatos) ...[
                Text('Firmante: ${widget.firmanteNombre}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
              ],
              if (widget.pedirDatos) ...[
                TextField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de quien firma',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dni,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'DNI (opcional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _aceptar,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar firma'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _ctrl.clear,
                    child: const Text('Limpiar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Captura de huella con el lector BioMini (código Android: HuelleroChannel.java)
// ---------------------------------------------------------------------------

class _HuellaResultado {
  _HuellaResultado(this.template, this.templateType, this.quality, this.image);
  final String template;
  final int templateType;
  final int quality;
  final String image; // PNG en base64
}

class _HuellaDialog extends StatefulWidget {
  const _HuellaDialog({Key? key, this.titulo = 'Huella del cliente'})
      : super(key: key);

  final String titulo;

  @override
  State<_HuellaDialog> createState() => _HuellaDialogState();
}

class _HuellaDialogState extends State<_HuellaDialog> {
  static const MethodChannel _canal = MethodChannel('casa_empenio/huellero');

  bool _capturando = true;
  String? _error;
  Map<String, dynamic>? _datos;

  @override
  void initState() {
    super.initState();
    _capturar();
  }

  Future<void> _capturar() async {
    setState(() {
      _capturando = true;
      _error = null;
      _datos = null;
    });
    try {
      final r = await _canal.invokeMapMethod<String, dynamic>('capturar');
      if (!mounted) return;
      setState(() {
        _datos = r;
        _capturando = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'No se pudo capturar la huella';
        _capturando = false;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _error = 'Esta versión de la app no tiene el lector de huellas.';
        _capturando = false;
      });
    }
  }

  Future<void> _cancelar() async {
    try {
      await _canal.invokeMethod('cancelar');
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  void _guardar() {
    final d = _datos;
    if (d == null) return;
    Navigator.of(context).pop(_HuellaResultado(
      (d['template'] ?? '').toString(),
      (d['templateType'] as num?)?.toInt() ?? 0,
      (d['quality'] as num?)?.toInt() ?? 0,
      (d['image'] ?? '').toString(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget contenido;
    List<Widget> acciones;
    if (_capturando) {
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 8),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Pida a la persona que coloque el dedo en el lector.',
              textAlign: TextAlign.center),
        ],
      );
      acciones = [
        TextButton(onPressed: _cancelar, child: const Text('Cancelar')),
      ];
    } else if (_error != null) {
      contenido = Text(_error!, style: const TextStyle(color: Colors.red));
      acciones = [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar')),
        ElevatedButton(onPressed: _capturar, child: const Text('Reintentar')),
      ];
    } else {
      Uint8List? bytes;
      try {
        bytes = base64Decode((_datos?['image'] ?? '').toString());
      } catch (_) {}
      contenido = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bytes != null) Image.memory(bytes, height: 180),
          const SizedBox(height: 8),
          Text('Calidad de la huella: ${_datos?['quality'] ?? '-'}'),
        ],
      );
      acciones = [
        TextButton(onPressed: _capturar, child: const Text('Repetir')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar huella')),
      ];
    }
    return AlertDialog(
      title: Text(widget.titulo),
      content: contenido,
      actions: acciones,
    );
  }
}


// ---------------------------------------------------------------------------
// API pública para otros módulos (por ejemplo, el contrato de venta):
// reutilizan la MISMA firma con el dedo y el MISMO lector de huellas.
// ---------------------------------------------------------------------------

class FirmaCapturada {
  FirmaCapturada(this.png, this.nombre, this.dni);
  final Uint8List png;
  final String nombre;
  final String dni;
}

class HuellaCapturada {
  HuellaCapturada(this.template, this.templateType, this.quality, this.imagenPng);
  final String template; // base64
  final int templateType;
  final int quality;
  final Uint8List imagenPng;
}

Future<FirmaCapturada?> capturarFirmaDigital(
  BuildContext context, {
  required String titulo,
  String? nombreInicial,
  String? dniInicial,
}) async {
  final r = await showDialog<_FirmaResultado>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FirmaDialog(
      titulo: titulo,
      pedirDatos: true,
      nombreInicial: nombreInicial,
      dniInicial: dniInicial,
    ),
  );
  if (r == null) return null;
  return FirmaCapturada(r.png, r.nombre, r.dni);
}

Future<HuellaCapturada?> capturarHuellaDigital(
  BuildContext context, {
  String titulo = 'Huella del comprador',
}) async {
  final r = await showDialog<_HuellaResultado>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _HuellaDialog(titulo: titulo),
  );
  if (r == null) return null;
  Uint8List png;
  try {
    png = base64Decode(r.image);
  } catch (_) {
    return null;
  }
  return HuellaCapturada(r.template, r.templateType, r.quality, png);
}

/// Firma de la empresa (de quien atiende). Si ya la guardó antes, se reutiliza.
Future<Uint8List?> obtenerFirmaEmpresa(BuildContext context) async {
  final prefsApp = context.read<Preferences>();
  final userId = prefsApp.token?.id ?? 0;
  final nombre = prefsApp.token?.fullName ?? '';
  final key = 'empresa_firma_base64_$userId';
  try {
    final sp = await SharedPreferences.getInstance();
    final b64 = sp.getString(key);
    if (b64 != null && b64.isNotEmpty) return base64Decode(b64);
  } catch (_) {}
  if (!context.mounted) return null;
  final r = await showDialog<_FirmaResultado>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FirmaDialog(
      titulo: 'Firma de la empresa (su firma)',
      pedirDatos: false,
      firmanteNombre: nombre,
    ),
  );
  if (r == null) return null;
  try {
    final dio = Dio(BaseOptions(baseUrl: endPointPrincipal));
    await dio.put<dynamic>(
      '/usuarios/$userId/firma',
      data: FormData.fromMap({
        'firma': MultipartFile.fromBytes(r.png, filename: 'firma_empresa.png'),
      }),
    );
  } catch (_) {}
  try {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, base64Encode(r.png));
  } catch (_) {}
  return r.png;
}
