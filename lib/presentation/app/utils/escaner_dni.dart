import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:casa_empenio_pe/presentation/app/utils/dni_logica.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Lo que devuelve el escáner de DNI.
class ResultadoDni {
  ResultadoDni({this.datos = const DatosDni(), this.frente, this.reverso, this.sinCamara = false});
  final DatosDni datos;
  final XFile? frente;
  final XFile? reverso;
  final bool sinCamara;
}

/// Abre la cámara para escanear el DNI: primero el frente (se toma solo al leer el número), luego el reverso.
Future<ResultadoDni?> abrirEscanerDni(BuildContext context) {
  return Navigator.of(context).push<ResultadoDni>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const EscanerDniPage()),
  );
}

const _giros = <DeviceOrientation, int>{
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

class EscanerDniPage extends StatefulWidget {
  const EscanerDniPage({super.key});

  @override
  State<EscanerDniPage> createState() => _EscanerDniPageState();
}

class _EscanerDniPageState extends State<EscanerDniPage> {
  CameraController? _cam;
  CameraDescription? _desc;
  final _lector = TextRecognizer(script: TextRecognitionScript.latin);
  final _acum = AcumuladorDni();
  bool _ocupado = false;
  bool _cerrando = false;
  bool _fallo = false;
  bool _linterna = false;
  int _ultimo = 0;
  int _cuadros = 0;
  int _estables = 0;
  String _estado = '';
  String _ladoVisto = '';
  String _aviso = '';
  int get _paso => _frente == null ? 0 : 1;
  XFile? _frente;
  XFile? _reverso;
  DatosDni _datos = const DatosDni();

  @override
  void initState() {
    super.initState();
    _abrir();
  }

  Future<void> _abrir() async {
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) throw 'sin cámaras';
      final trasera = camaras.where((c) => c.lensDirection == CameraLensDirection.back);
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
      Navigator.of(context).pop(ResultadoDni(sinCamara: true));
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

  /// Cada ~0.6 s se lee un cuadro. El frente se toma solo cuando el número de DNI se ve igual en 2 cuadros;
  /// el reverso, cuando el texto se ve estable en 2 cuadros seguidos.
  Future<void> _cuadro(CameraImage img) async {
    final ahora = DateTime.now().millisecondsSinceEpoch;
    if (_ocupado || _cerrando || ahora - _ultimo < 600) return;
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
      _cuadros++;
      final texto = t.text;
      if (texto.trim().isEmpty) {
        _vacios++;
        if (!_giroFijo && _vacios >= 4) {
          _giroExtra = (_giroExtra + 90) % 360;
          _vacios = 0;
        }
      } else {
        _vacios = 0;
        _giroFijo = true;
        _acum.anotar(texto);
      }
      _estado = '';
      _datos = _datos.unir(_acum.datos);
      // Se reconoce solo qué lado es: nunca se repite el frente ni se confunde con el reverso.
      final lado = ladoDelDni(texto);
      if (lado == 'frente' || lado == 'reverso') {
        if (lado == _ladoVisto) {
          _estables++;
        } else {
          _ladoVisto = lado;
          _estables = 1;
        }
      } else {
        _estables = 0;
      }
      _aviso = '';
      if (lado == 'frente' && _frente != null && _reverso == null) {
        _aviso = 'Ese es el frente, que ya está listo. Voltea el DNI para el reverso.';
      } else if (lado == 'reverso' && _reverso != null && _frente == null) {
        _aviso = 'Ese es el reverso, que ya está listo. Voltea el DNI para el frente.';
      }
      if (_estables >= 2) {
        if (lado == 'frente' && _frente == null && _acum.dni != null) {
          await _capturar('frente');
        } else if (lado == 'reverso' && _reverso == null) {
          await _capturar('reverso');
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      _estado = 'Error al leer: $e';
      if (mounted) setState(() {});
    } finally {
      _ocupado = false;
    }
  }

  /// Toma la foto de [lado] ('frente' o 'reverso'); sin [lado] toma el que falta. Al tener los dos, termina.
  Future<void> _capturar([String? lado]) async {
    final c = _cam;
    if (c == null || _cerrando) return;
    final que = lado ?? (_frente == null ? 'frente' : 'reverso');
    _cerrando = true;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
      final foto = await c.takePicture();
      HapticFeedback.mediumImpact();
      if (que == 'frente') {
        _frente = foto;
      } else {
        _reverso = foto;
      }
      _estables = 0;
      _ladoVisto = '';
      if (_frente != null && _reverso != null) {
        _terminar();
        return;
      }
      _cerrando = false;
      if (!mounted) return;
      await c.startImageStream(_cuadro);
      setState(() {});
    } catch (_) {
      _cerrando = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo tomar la foto. Inténtalo otra vez.')));
      try {
        if (!c.value.isStreamingImages) await c.startImageStream(_cuadro);
      } catch (_) {}
    }
  }

  void _terminar() {
    if (!mounted) return;
    _cerrando = true;
    Navigator.of(context).pop(ResultadoDni(datos: _datos.unir(_acum.datos), frente: _frente, reverso: _reverso));
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
    }();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _cam;
    final listo = c != null && c.value.isInitialized;
    final d = _datos;
    final nombre = [d.nombres, d.apellidos].where((e) => e.isNotEmpty).join(' ');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_frente != null && _reverso == null ? 'DNI: ahora el reverso' : (_reverso != null && _frente == null ? 'DNI: ahora el frente' : 'Escanear DNI')),
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
                            widthFactor: 0.92,
                            heightFactor: 0.42,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: _frente != null || _reverso != null ? Colors.greenAccent : Colors.white70, width: 3),
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
                              _aviso.isNotEmpty
                                  ? _aviso
                                  : _frente == null && _reverso == null
                                      ? 'Pon un lado del DNI en el marco. Se reconoce solo si es el frente o el reverso y la foto se toma sola.'
                                      : _frente != null
                                          ? '✓ Frente listo. Voltea el DNI y ponlo en el marco: el reverso se toma solo.'
                                          : '✓ Reverso listo. Voltea el DNI y ponlo en el marco: el frente se toma solo.',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ),
                      ]),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: SafeArea(
                  top: false,
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Frente: ${_frente != null ? '✓' : '—'}   Reverso: ${_reverso != null ? '✓' : '—'}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(d.tieneDni ? 'DNI leído: ${d.dni}' : 'Buscando el número de DNI…',
                        style: TextStyle(fontWeight: FontWeight.bold, color: d.tieneDni ? Colors.green.shade800 : Colors.black87)),
                    if (nombre.isNotEmpty) Text(nombre, style: const TextStyle(fontSize: 13)),
                    if (d.domicilio.isNotEmpty) Text('Domicilio: ${d.domicilio}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _estado.isNotEmpty ? _estado : (_cuadros == 0 ? 'Iniciando lectura…' : 'Leyendo…'),
                      style: TextStyle(fontSize: 11, color: _estado.isNotEmpty ? Colors.red : Colors.black45),
                    ),
                    Row(children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                      const Spacer(),
                      if (_frente != null || _reverso != null)
                        TextButton(onPressed: _terminar, child: const Text('Terminar')),
                      FilledButton.icon(
                        onPressed: listo ? _capturar : null,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_frente == null ? 'Tomar frente' : 'Tomar reverso'),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
    );
  }
}
