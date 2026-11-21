import 'dart:io';

import 'package:camera/camera.dart';
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

  InputImage? _aEntrada(CameraImage img) {
    final desc = _desc;
    final cam = _cam;
    if (desc == null || cam == null) return null;
    final sensor = desc.sensorOrientation;
    int? giro;
    if (Platform.isIOS) {
      giro = sensor;
    } else {
      var comp = _giros[cam.value.deviceOrientation] ?? 0;
      comp = desc.lensDirection == CameraLensDirection.front ? (sensor + comp) % 360 : (sensor - comp + 360) % 360;
      giro = comp;
    }
    final rotacion = InputImageRotationValue.fromRawValue(giro);
    final formato = InputImageFormatValue.fromRawValue(img.format.raw);
    if (rotacion == null || formato == null) return null;
    if (Platform.isAndroid && formato != InputImageFormat.nv21) return null;
    if (Platform.isIOS && formato != InputImageFormat.bgra8888) return null;
    if (img.planes.length != 1) return null;
    final p = img.planes.first;
    return InputImage.fromBytes(
      bytes: p.bytes,
      metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rotacion,
        format: formato,
        bytesPerRow: p.bytesPerRow,
      ),
    );
  }

  /// Se llama con cada cuadro de la cámara; se lee uno cada ~0.6 s para no recalentar el teléfono.
  Future<void> _cuadro(CameraImage img) async {
    final ahora = DateTime.now().millisecondsSinceEpoch;
    if (_ocupado || _cerrando || ahora - _ultimo < 600) return;
    _ocupado = true;
    _ultimo = ahora;
    try {
      final entrada = _aEntrada(img);
      if (entrada == null) return;
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
    } catch (_) {
      // un cuadro que falla no importa: llega otro enseguida
    } finally {
      _ocupado = false;
    }
  }

  List<String> get _fichas {
    final l = _vistos.entries
        .where((e) => e.value >= 2 && (_soloTextos ? e.key.length >= 4 : puntosDeCandidato(widget.campo, e.key) > 0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
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
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              _soloTextos
                                  ? 'Apunta al texto del bien (etiqueta, serie, tarjeta). Se lee solo; toca «Usar esta foto» cuando salga lo que buscas.'
                                  : 'Apunta $_nombre dentro del marco. Se lee solo: compara con el bien y, si está bien, toca «Usar».',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
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
