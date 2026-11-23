import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:casa_empenio_pe/presentation/app/utils/dni_logica.dart' show LineaGeo;
import 'package:casa_empenio_pe/presentation/app/utils/escaner_vivo_logica.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Lo que devuelve el escáner en vivo.
class ResultadoVivo {
  ResultadoVivo({
    this.valor = '',
    this.foto,
    this.textos = const [],
    this.codigos = const [],
    this.sinCamara = false,
  });
  final String valor;
  final XFile? foto;
  final List<String> textos;
  final List<String> codigos;

  /// true si la cámara en vivo no se pudo abrir (se usa la foto normal).
  final bool sinCamara;
}

/// Abre la cámara en vivo: lee el texto mientras se apunta, propone el dato y la persona lo confirma ahí mismo.
/// [campo]: 'serie', 'placa', 'modelo', 'descripcion' o 'todo' (solo juntar textos de una foto).
Future<ResultadoVivo?> abrirEscanerVivo(BuildContext context, {required String campo}) {
  return Navigator.of(context).push<ResultadoVivo>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => EscanerVivoPage(campo: campo)),
  );
}

const _giros = <DeviceOrientation, int>{
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

class EscanerVivoPage extends StatefulWidget {
  const EscanerVivoPage({super.key, required this.campo});
  final String campo;

  @override
  State<EscanerVivoPage> createState() => _EscanerVivoPageState();
}

class _EscanerVivoPageState extends State<EscanerVivoPage> {
  CameraController? _cam;
  CameraDescription? _desc;
  final _lector = TextRecognizer(script: TextRecognitionScript.latin);
  final _barras = BarcodeScanner();
  final _valor = TextEditingController();
  final Map<String, int> _vistos = {};
  final Set<String> _codigos = {};
  final List<String> _textos = [];
  bool _ocupado = false;
  bool _cerrando = false;
  bool _editado = false;
  bool _linterna = false;
  bool _fallo = false;
  int _ultimo = 0;
  int _cuadros = 0;
  String _estado = '';
  List<LineaGeo> _lineasVivas = const [];
  Offset? _selA;
  Offset? _selB;

  bool get _soloTextos => widget.campo == 'todo';
  String get _nombre {
    switch (widget.campo) {
      case 'serie':
        return 'la serie';
      case 'placa':
        return 'la placa';
      case 'modelo':
        return 'el modelo';
      case 'descripcion':
        return 'la descripción';
      default:
        return 'el texto';
    }
  }

  @override
  void initState() {
    super.initState();
    _abrir();
  }

  Future<void> _abrir() async {
    try {
      final camaras = await availableCameras();
      final trasera = camaras.where((c) => c.lensDirection == CameraLensDirection.back);
      if (camaras.isEmpty) throw 'sin cámaras';
      _desc = trasera.isNotEmpty ? trasera.first : camaras.first;
      final c = CameraController(
        _desc!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await c.initialize();
      try {
        await c.setFocusMode(FocusMode.auto);
      } catch (_) {}
      if (!mounted) {
        await c.dispose();
        return;
      }
      _cam = c;
      await c.startImageStream(_cuadro);
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      _fallo = true;
      Navigator.of(context).pop(ResultadoVivo(sinCamara: true));
    }
  }

  /// Convierte el cuadro de la cámara a NV21 (lo que entiende ML Kit en Android), sea cual sea el formato que entregue el teléfono.
  Uint8List? _aNv21(CameraImage img) {
    final w = img.width, h = img.height;
    if (img.planes.length == 1) return img.planes.first.bytes; // ya viene en NV21
    if (img.planes.length < 3) return null;
    final y = img.planes[0], u = img.planes[1], v = img.planes[2];
    final out = Uint8List(w * h + (w ~/ 2) * (h ~/ 2) * 2);
    var k = 0;
    for (var r = 0; r < h; r++) {
      final ini = r * y.bytesPerRow;
      out.setRange(k, k + w, y.bytes, ini);
      k += w;
    }
    final uvw = w ~/ 2, uvh = h ~/ 2;
    final ups = u.bytesPerPixel ?? 1, vps = v.bytesPerPixel ?? 1;
    for (var r = 0; r < uvh; r++) {
      for (var c = 0; c < uvw; c++) {
        final vi = r * v.bytesPerRow + c * vps;
        final ui = r * u.bytesPerRow + c * ups;
        if (vi >= v.bytes.length || ui >= u.bytes.length) return out;
        out[k++] = v.bytes[vi];
        out[k++] = u.bytes[ui];
      }
    }
    return out;
  }

  int _giroExtra = 0; // 0, 90, 180, 270: se prueba hasta que el texto se lee
  bool _giroFijo = false;
  int _vacios = 0;

  InputImage? _aEntrada(CameraImage img) {
    final desc = _desc;
    final cam = _cam;
    if (desc == null || cam == null) return null;
    final sensor = desc.sensorOrientation;
    int giro;
    if (Platform.isIOS) {
      giro = sensor;
    } else {
      var comp = _giros[cam.value.deviceOrientation] ?? 0;
      giro = desc.lensDirection == CameraLensDirection.front ? (sensor + comp) % 360 : (sensor - comp + 360) % 360;
    }
    giro = (giro + _giroExtra) % 360;
    final rotacion = InputImageRotationValue.fromRawValue(giro);
    if (rotacion == null) {
      _estado = 'Rotación no válida ($giro)';
      return null;
    }
    if (Platform.isIOS) {
      if (img.planes.isEmpty) return null;
      final p = img.planes.first;
      return InputImage.fromBytes(
        bytes: p.bytes,
        metadata: InputImageMetadata(
          size: Size(img.width.toDouble(), img.height.toDouble()),
          rotation: rotacion,
          format: InputImageFormat.bgra8888,
          bytesPerRow: p.bytesPerRow,
        ),
      );
    }
    final bytes = _aNv21(img);
    if (bytes == null) {
      _estado = 'Formato de cámara no soportado (${img.planes.length} planos)';
      return null;
    }
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rotacion,
        format: InputImageFormat.nv21,
        bytesPerRow: img.planes.length == 1 ? img.planes.first.bytesPerRow : img.width,
      ),
    );
  }

  /// Se llama con cada cuadro de la cámara; se lee uno cada ~0.6 s para no recalentar el teléfono.
  Future<void> _cuadro(CameraImage img) async {
    final ahora = DateTime.now().millisecondsSinceEpoch;
    if (_ocupado || _cerrando || ahora - _ultimo < 400) return;
    _ocupado = true;
    _ultimo = ahora;
    try {
      final entrada = _aEntrada(img);
      if (entrada == null) {
        if (mounted) setState(() {});
        return;
      }
      final t = await _lector.processImage(entrada);
      if (_cerrando || !mounted) return;
      if (widget.campo == 'serie' || _soloTextos) {
        try {
          final b = await _barras.processImage(entrada);
          for (final x in b) {
            final v = (x.rawValue ?? '').trim();
            if (v.isNotEmpty) _codigos.add(v);
          }
        } catch (_) {}
      }
      _cuadros++;
      if (t.text.trim().isEmpty) {
        // si no lee nada durante un rato, se prueba otra rotación hasta que salga texto
        _vacios++;
        if (!_giroFijo && _vacios >= 4) {
          _giroExtra = (_giroExtra + 90) % 360;
          _vacios = 0;
        }
      } else {
        _vacios = 0;
        _giroFijo = true;
      }
      _estado = '';
      _lineasVivas = [
        for (final b in t.blocks)
          for (final ln in b.lines)
            LineaGeo(ln.text, ln.boundingBox.left, ln.boundingBox.top, ln.boundingBox.width, ln.boundingBox.height),
      ];
      if (t.text.trim().isNotEmpty) {
        anotarCuadro(_soloTextos ? 'descripcion' : widget.campo, t.text, _vistos);
        for (final l in t.text.split(RegExp(r'[\r\n]+'))) {
          final s = l.trim();
          if (s.length >= 3 && !_textos.contains(s) && _textos.length < 60) _textos.add(s);
        }
      }
      if (!_soloTextos && !_editado) {
        final p = proponerCampo(widget.campo, _vistos) ?? (widget.campo == 'serie' && _codigos.isNotEmpty ? _codigos.first : null);
        if (p != null && p != _valor.text) _valor.text = p;
      }
      if (mounted) setState(() {});
    } catch (e) {
      _estado = 'Error al leer: $e';
      if (mounted) setState(() {});
    } finally {
      _ocupado = false;
    }
  }

  List<String> get _fichas {
    final l = _vistos.entries
        .where((e) => e.value >= 2 && (_soloTextos ? e.key.length >= 4 : puntosDeCandidato(widget.campo, e.key) > 0))
        .toList()
      ..sort((a, b) {
        // para el modelo, primero lo que más parece un modelo (nombre de serie / código) y luego lo más visto
        final pa = widget.campo == 'modelo' ? puntosDeCandidato('modelo', a.key) * (a.value > 5 ? 5 : a.value) : a.value;
        final pb = widget.campo == 'modelo' ? puntosDeCandidato('modelo', b.key) * (b.value > 5 ? 5 : b.value) : b.value;
        return pb.compareTo(pa);
      });
    return [
      ..._codigos,
      for (final e in l)
        if (!_codigos.contains(e.key)) e.key,
    ].take(10).toList();
  }

  Future<void> _usar() async {
    final c = _cam;
    if (c == null || _cerrando) return;
    if (!_soloTextos && _valor.text.trim().isEmpty) return;
    _cerrando = true;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
      if (_linterna) await c.setFlashMode(FlashMode.off);
      final foto = await c.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(ResultadoVivo(
        valor: _valor.text.trim().toUpperCase(),
        foto: foto,
        textos: [_textos.join('\n')],
        codigos: _codigos.toList(),
      ));
    } catch (_) {
      _cerrando = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar la foto. Inténtalo otra vez.')));
      try {
        if (!c.value.isStreamingImages) await c.startImageStream(_cuadro);
      } catch (_) {}
    }
  }

  /// Capa táctil sobre la cámara: se ven las líneas de texto leídas; tocar una la elige,
  /// y arrastrando el dedo se dibuja un recuadro: se toma solo el texto de esa zona.
  Widget _capaDeSeleccion(CameraController c) {
    final ps = c.value.previewSize!;
    final iw = ps.height; // la imagen vertical: ancho = lado corto
    final ih = ps.width;
    return LayoutBuilder(builder: (context, caja) {
      final w = caja.maxWidth, h = caja.maxHeight;
      final esc = (w / iw > h / ih) ? w / iw : h / ih; // cover
      final ox = (w - iw * esc) / 2, oy = (h - ih * esc) / 2;
      Offset aImg(Offset p) => Offset((p.dx - ox) / esc, (p.dy - oy) / esc);
      void elegir(String v) {
        if (v.isEmpty) return;
        HapticFeedback.selectionClick();
        setState(() {
          _valor.text = v.length > 60 ? v.substring(0, 60) : v;
          _editado = true;
        });
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final p = aImg(d.localPosition);
          elegir(textoDeToque(_lineasVivas, p.dx, p.dy));
        },
        onPanStart: (d) => setState(() {
          _selA = d.localPosition;
          _selB = d.localPosition;
        }),
        onPanUpdate: (d) => setState(() => _selB = d.localPosition),
        onPanEnd: (_) {
          final a = _selA, b = _selB;
          if (a != null && b != null) {
            final p1 = aImg(a), p2 = aImg(b);
            final izq = p1.dx < p2.dx ? p1.dx : p2.dx, der = p1.dx < p2.dx ? p2.dx : p1.dx;
            final arr = p1.dy < p2.dy ? p1.dy : p2.dy, aba = p1.dy < p2.dy ? p2.dy : p1.dy;
            elegir(textoDeArea(_lineasVivas, izq, arr, der, aba));
          }
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => _selA = _selB = null);
          });
        },
        child: CustomPaint(
          size: Size(w, h),
          painter: _PintorTextos(
            [
              for (final l in _lineasVivas)
                Rect.fromLTWH(l.izq * esc + ox, l.arriba * esc + oy, l.ancho * esc, l.alto * esc),
            ],
            _selA == null || _selB == null ? null : Rect.fromPoints(_selA!, _selB!),
          ),
        ),
      );
    });
  }

  Future<void> _alternarLinterna() async {
    final c = _cam;
    if (c == null) return;
    try {
      await c.setFlashMode(_linterna ? FlashMode.off : FlashMode.torch);
      setState(() => _linterna = !_linterna);
    } catch (_) {}
  }

  @override
  void dispose() {
    _cerrando = true;
    final c = _cam;
    _cam = null;
    () async {
      try {
        if (c != null && c.value.isStreamingImages) await c.stopImageStream();
      } catch (_) {}
      try {
        await c?.dispose();
      } catch (_) {}
      await _lector.close();
      await _barras.close();
    }();
    _valor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _cam;
    final listo = c != null && c.value.isInitialized;
    final propuesto = _valor.text.trim();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_soloTextos ? 'Escaneando…' : 'Escaneando $_nombre'),
        actions: [
          if (listo)
            IconButton(
              tooltip: 'Linterna',
              icon: Icon(_linterna ? Icons.flash_on : Icons.flash_off),
              onPressed: _alternarLinterna,
            ),
        ],
      ),
      body: _fallo
          ? const SizedBox.shrink()
          : Column(children: [
              Expanded(
                child: !listo
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(fit: StackFit.expand, children: [
                        ClipRect(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: c.value.previewSize!.height,
                              height: c.value.previewSize!.width,
                              child: CameraPreview(c),
                            ),
                          ),
                        ),
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.88,
                            heightFactor: 0.28,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: propuesto.isEmpty ? Colors.white70 : Colors.greenAccent, width: 3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (!_soloTextos) _capaDeSeleccion(c),
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 12,
                          child: IgnorePointer(child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              _soloTextos
                                  ? 'Apunta al texto del bien (etiqueta, serie, tarjeta). Se lee solo; toca «Usar esta foto» cuando salga lo que buscas.'
                                  : 'Apunta $_nombre. Se lee solo, o elige tú: toca un texto o dibuja un recuadro con el dedo sobre lo que quieres. Luego «Usar».',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          )),
                        ),
                      ]),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + MediaQuery.of(context).viewInsets.bottom),
                child: SafeArea(
                  top: false,
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (!_soloTextos) ...[
                      TextField(
                        controller: _valor,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) => setState(() => _editado = true),
                        decoration: InputDecoration(
                          labelText: propuesto.isEmpty
                              ? (_cuadros == 0 ? 'Iniciando cámara…' : 'Buscando $_nombre…')
                              : 'Leído (corrígelo si hace falta)',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: _editado
                              ? IconButton(
                                  tooltip: 'Volver a leer solo',
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () => setState(() {
                                    _editado = false;
                                    _valor.clear();
                                    _vistos.clear();
                                  }),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_fichas.isNotEmpty) ...[
                      Text(_soloTextos ? 'Textos leídos:' : 'Otros textos vistos (toca uno para usarlo):',
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, runSpacing: 0, children: [
                        for (final f in _fichas)
                          ActionChip(
                            label: Text(f, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            onPressed: _soloTextos
                                ? null
                                : () => setState(() {
                                      _valor.text = f;
                                      _editado = true;
                                    }),
                          ),
                      ]),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      _estado.isNotEmpty
                          ? _estado
                          : (_cuadros == 0 ? 'Iniciando lectura…' : 'Leyendo… (${_vistos.length} textos vistos)'),
                      style: TextStyle(fontSize: 11, color: _estado.isNotEmpty ? Colors.red : Colors.black45),
                    ),
                    Row(children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: listo && (_soloTextos || propuesto.isNotEmpty) ? _usar : null,
                        icon: const Icon(Icons.check),
                        label: Text(_soloTextos ? 'Usar esta foto' : 'Usar'),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
    );
  }
}

class _PintorTextos extends CustomPainter {
  _PintorTextos(this.cajas, this.seleccion);
  final List<Rect> cajas;
  final Rect? seleccion;

  @override
  void paint(Canvas canvas, Size size) {
    final borde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white54;
    for (final r in cajas) {
      canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(3)), borde);
    }
    final sel = seleccion;
    if (sel != null) {
      canvas.drawRect(sel, Paint()..color = Colors.greenAccent.withOpacity(0.25));
      canvas.drawRect(
          sel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = Colors.greenAccent);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorTextos old) => true;
}
