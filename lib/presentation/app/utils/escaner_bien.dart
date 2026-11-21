import 'package:casa_empenio_pe/presentation/app/utils/sesion_segura.dart';
import 'package:casa_empenio_pe/presentation/app/utils/escaner_vivo.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Resultado del escáner: lo que se pasa al formulario de garantía.
class EscanerResultado {
  EscanerResultado({
    required this.tipo,
    required this.campos,
    required this.extras,
    required this.fotos,
    this.observaciones = '',
  });
  final String observaciones;
  final String tipo;
  final Map<String, String> campos;
  final String extras;
  final List<XFile> fotos;
}

const _tipos = <String, String>{
  'DETECTAR': 'Detectar solo',
  'CELULAR': 'Celular',
  'LAPTOP': 'Laptop',
  'MOTO_LINEAL': 'Moto lineal',
  'MOTOCAR': 'Motocar',
  'AUTO': 'Auto / camioneta',
  'MOTOR': 'Motor / máquina',
  'ELECTRO': 'Electrodoméstico',
  'OTRO': 'Otro',
};

String _sinTildes(String s) => s
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');

/// Adivina el tipo de escaneo a partir del nombre de la categoría elegida.
String tipoEscaneoDeCategoria(String? nombre, [String? padre]) {
  final t = _sinTildes('${padre ?? ''} ${nombre ?? ''}');
  bool tiene(List<String> c) => c.any(t.contains);
  if (tiene(['motocar', 'motokar', 'mototaxi'])) return 'MOTOCAR';
  if (tiene(['moto lineal', 'motocicleta', 'moto'])) return 'MOTO_LINEAL';
  if (tiene(['celular', 'telefono', 'smartphone'])) return 'CELULAR';
  if (tiene(['laptop', 'computadora', 'notebook', 'portatil'])) return 'LAPTOP';
  if (tiene(['auto', 'camioneta', 'vehiculo', 'carro'])) return 'AUTO';
  if (tiene(['motor', 'maquinaria', 'generador', 'motosierra'])) return 'MOTOR';
  if (tiene(['electro', 'televisor', 'tv', 'refriger', 'cocina', 'lavadora'])) {
    return 'ELECTRO';
  }
  return 'OTRO';
}

/// Palabras para buscar la categoría del sistema que corresponde al tipo.
List<String> palabrasCategoria(String tipo) {
  switch (tipo) {
    case 'CELULAR':
      return ['celular', 'telefono', 'movil', 'smartphone'];
    case 'LAPTOP':
      return ['laptop', 'computadora', 'computo', 'notebook'];
    case 'MOTO_LINEAL':
      return ['moto lineal', 'lineal', 'motocicleta', 'moto'];
    case 'MOTOCAR':
      return ['motocar', 'motokar'];
    case 'AUTO':
      return ['auto', 'camioneta', 'vehiculo'];
    case 'MOTOR':
      return ['motor', 'maquinaria', 'herramienta', 'motosierra', 'generador'];
    case 'ELECTRO':
      return ['electro', 'artefacto', 'hogar', 'television'];
    default:
      return [];
  }
}

final Dio _dioEscaner = crearDio(BaseOptions(
  baseUrl: endPointPrincipal,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 60),
));

dynamic _body(Response<dynamic> r) {
  final d = r.data is String ? jsonDecode(r.data as String) : r.data;
  if (d is Map) return d['body'];
  return null;
}

/// Pregunta de dónde viene la foto: cámara o galería (el cliente a veces la manda por WhatsApp).
Future<ImageSource?> _elegirOrigenFoto(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(children: [
        ListTile(
          leading: const Icon(Icons.photo_camera),
          title: const Text('Tomar foto ahora'),
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('Elegir de la galería'),
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
        ),
      ]),
    ),
  );
}

/// Pregunta cómo capturar: escáner en vivo (lee mientras se apunta), foto o galería (el cliente a veces la manda por WhatsApp).
/// Devuelve null si cancela; [vivo] es true si eligió el escáner en vivo.
Future<({ImageSource? origen, bool vivo})?> _elegirCaptura(BuildContext context, {bool ofrecerVivo = true}) async {
  final r = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(children: [
        if (ofrecerVivo)
          ListTile(
            leading: const Icon(Icons.document_scanner),
            title: const Text('Escanear en vivo (recomendado)'),
            subtitle: const Text('Apuntas y lee solo; verificas ahí mismo'),
            onTap: () => Navigator.pop(ctx, 'vivo'),
          ),
        ListTile(
          leading: const Icon(Icons.photo_camera),
          title: const Text('Tomar foto ahora'),
          onTap: () => Navigator.pop(ctx, 'camara'),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('Elegir de la galería'),
          onTap: () => Navigator.pop(ctx, 'galeria'),
        ),
      ]),
    ),
  );
  if (r == null) return null;
  if (r == 'vivo') return (origen: null, vivo: true);
  return (origen: r == 'camara' ? ImageSource.camera : ImageSource.gallery, vivo: false);
}

/// Lo que el teléfono reconoce mirando la imagen (ej. "Mobile phone", "Motorcycle").
Future<List<String>> _etiquetasDeImagen(String ruta) async {
  final et = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.35));
  try {
    final r = await et.processImage(InputImage.fromFilePath(ruta));
    r.sort((a, b) => b.confidence.compareTo(a.confidence));
    return r.map((e) => e.label).take(15).toList();
  } catch (_) {
    return [];
  } finally {
    await et.close();
  }
}

class _Paso {
  _Paso(this.clave, this.rol, this.titulo, this.ayuda, this.leerTexto,
      this.obligatorio);
  final String clave;
  final String rol;
  final String titulo;
  final String ayuda;
  final bool leerTexto;
  final bool obligatorio;
  XFile? foto;
  List<String> textos = [];
  List<String> codigos = [];
  List<String> etiquetas = [];
  bool leyendo = false;
}

/// Abre el escáner. Devuelve null si el cajero cancela.
Future<EscanerResultado?> abrirEscanerBien(BuildContext context,
    {String tipoInicial = 'OTRO'}) {
  return Navigator.of(context).push<EscanerResultado>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _EscanerPage(tipoInicial: tipoInicial),
    ),
  );
}

class _EscanerPage extends StatefulWidget {
  const _EscanerPage({required this.tipoInicial});
  final String tipoInicial;

  @override
  State<_EscanerPage> createState() => _EscanerPageState();
}

class _EscanerPageState extends State<_EscanerPage> {
  late String _tipo = (_tipos.containsKey(widget.tipoInicial) && widget.tipoInicial != 'OTRO')
      ? widget.tipoInicial
      : 'DETECTAR';
  final Set<String> _elegidas = {};
  bool _guardando = false;

  int get _totalFotos => _pasos.where((p) => p.foto != null).length;

  /// Con más de 3 fotos, las demás se juntan en una hoja de evidencia (que ocupa la tercera foto del bien).
  bool get _conHoja => _totalFotos > 3;
  int get _maxElegidas => _conHoja ? 2 : 3;
  final _obsAdicional = TextEditingController();

  /// Tipo real del bien: el que se eligió o el que el sistema reconoció.
  String get _tipoFinal => (_res?['tipo'] ?? (_tipo == 'DETECTAR' ? 'OTRO' : _tipo)).toString();
  List<_Paso> _pasos = [];
  bool _cargandoGuia = true;
  bool _consultando = false;
  String? _error;
  Map<String, dynamic>? _res;
  final Map<String, TextEditingController> _ctl = {};

  @override
  void initState() {
    super.initState();
    _cargarGuia();
  }

  @override
  void dispose() {
    _obsAdicional.dispose();
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<_Paso> _guiaLocal() => [
        _Paso('general', 'GENERAL', 'Foto general', 'Todo el bien.', true, true),
        _Paso('etiqueta', 'SERIE', 'Etiqueta o serie (de cerca)',
            'Acerca la cámara al texto con marca, modelo o serie.', true, false),
      ];

  Future<void> _cargarGuia() async {
    setState(() {
      _cargandoGuia = true;
      _error = null;
    });
    List<_Paso> nuevos;
    try {
      final r = await _dioEscaner
          .get('/operacion/escaner/guia', queryParameters: {'tipo': _tipo});
      final b = _body(r);
      if (b is List && b.isNotEmpty) {
        nuevos = b
            .map((e) => _Paso(
                  '${e['clave']}',
                  '${e['rol']}',
                  '${e['titulo']}',
                  '${e['ayuda']}',
                  e['leerTexto'] == true,
                  e['obligatorio'] == true,
                ))
            .toList();
      } else {
        nuevos = _guiaLocal();
      }
    } catch (_) {
      nuevos = _guiaLocal();
    }
    if (!mounted) return;
    setState(() {
      _pasos = nuevos;
      _cargandoGuia = false;
    });
  }

  Future<void> _tomar(_Paso p) async {
    final cap = await _elegirCaptura(context, ofrecerVivo: p.leerTexto);
    if (cap == null || !mounted) return;
    if (cap.vivo) {
      final v = await abrirEscanerVivo(context, campo: 'todo');
      if (!mounted || v == null) return;
      if (v.sinCamara || v.foto == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la cámara en vivo. Usa «Tomar foto ahora».')));
        return;
      }
      setState(() {
        p.foto = v.foto;
        p.textos = v.textos;
        p.codigos = v.codigos;
        p.etiquetas = [];
        p.leyendo = true;
      });
      p.etiquetas = await _etiquetasDeImagen(v.foto!.path);
      if (!mounted) return;
      setState(() => p.leyendo = false);
      return;
    }
    final foto = await ImagePicker().pickImage(source: cap.origen!, imageQuality: 92);
    if (foto == null) return;
    setState(() {
      p.foto = foto;
      p.textos = [];
      p.codigos = [];
      p.etiquetas = [];
      p.leyendo = true;
    });
    p.etiquetas = await _etiquetasDeImagen(foto.path);
    if (!p.leerTexto) {
      if (mounted) setState(() => p.leyendo = false);
      return;
    }
    final reconocedor = TextRecognizer(script: TextRecognitionScript.latin);
    final lector = BarcodeScanner();
    try {
      final entrada = InputImage.fromFilePath(foto.path);
      final texto = await reconocedor.processImage(entrada);
      final barras = await lector.processImage(entrada);
      p.textos = [texto.text];
      p.codigos = barras
          .map((b) => b.rawValue ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      p.textos = [];
    } finally {
      await reconocedor.close();
      await lector.close();
    }
    if (!mounted) return;
    setState(() => p.leyendo = false);
  }

  bool get _listo => _pasos.where((p) => p.obligatorio).every((p) => p.foto != null);

  Future<void> _leerDatos() async {
    setState(() {
      _consultando = true;
      _error = null;
    });
    try {
      final r = await _dioEscaner.post('/operacion/escaner/consultar', data: {
        'tipo': _tipo,
        'fuentes': _pasos
            .where((p) => p.foto != null)
            .map((p) => {
                  'etiqueta': p.titulo,
                  'rol': p.rol,
                  'textos': p.textos,
                  'codigos': p.codigos,
                  'etiquetas': p.etiquetas,
                })
            .toList(),
      });
      final b = _body(r);
      if (b is! Map) throw 'Respuesta vacía';
      final res = Map<String, dynamic>.from(b);
      final campos = Map<String, dynamic>.from(res['campos'] ?? {});
      for (final c in _ctl.values) {
        c.dispose();
      }
      _ctl.clear();
      for (final k in [
        'descripcion',
        'marca',
        'modelo',
        'serie',
        'placa',
        'color',
      ]) {
        _ctl[k] = TextEditingController(text: '${campos[k] ?? ''}');
      }
      _ctl['extras'] = TextEditingController(text: '${res['extras'] ?? ''}');
      _elegidas
        ..clear()
        ..addAll(_sugeridas().map((f) => f.path));
      if (!mounted) return;
      setState(() {
        _res = res;
        _consultando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _consultando = false;
        _error = e is DioException && e.response?.statusCode == 404
            ? 'El servidor todavía se está actualizando. Espera unos minutos e inténtalo otra vez.'
            : 'No se pudo leer. Revisa tu conexión e inténtalo otra vez.';
      });
    }
  }

  /// Las fotos con más información: la primera general (para ver el bien) y las que más texto útil dieron.
  List<XFile> _sugeridas() {
    final con = _pasos.where((p) => p.foto != null).toList();
    if (con.isEmpty) return [];
    double puntos(_Paso p) {
      final letras = p.textos.fold<int>(0, (a, t) => a + t.trim().length) + p.codigos.length * 30;
      final bono = p.rol == 'TARJETA' ? 150 : (p.rol == 'SERIE' || p.rol == 'CHASIS' ? 80 : 0);
      return letras + bono.toDouble();
    }
    final out = <_Paso>[];
    final general = con.where((p) => p.rol == 'GENERAL').toList();
    if (general.isNotEmpty) out.add(general.first);
    final resto = con.where((p) => !out.contains(p)).toList()
      ..sort((a, b) => puntos(b).compareTo(puntos(a)));
    for (final p in resto) {
      if (out.length >= _maxElegidas) break;
      out.add(p);
    }
    return out.map((p) => p.foto!).toList();
  }

  List<XFile> _fotosParaGuardar() =>
      _pasos.where((p) => p.foto != null && _elegidas.contains(p.foto!.path)).map((p) => p.foto!).take(_maxElegidas).toList();

  Future<void> _usar() async {
    if (_guardando) return;
    final campos = <String, String>{
      for (final e in _ctl.entries)
        if (e.key != 'extras') e.key: e.value.text.trim(),
    };
    final fotos = _fotosParaGuardar();
    if (_conHoja) {
      setState(() => _guardando = true);
      try {
        final hoja = await _armarHoja(_pasos.where((p) => p.foto != null).toList());
        if (hoja != null) fotos.add(hoja);
      } catch (_) {
        // si la hoja falla, igual se guardan las fotos elegidas
      }
      if (!mounted) return;
    }
    Navigator.of(context).pop(EscanerResultado(
      tipo: _tipoFinal,
      campos: campos,
      extras: _ctl['extras']?.text.trim() ?? '',
      observaciones: _obsAdicional.text.trim(),
      fotos: fotos,
    ));
  }

  /// Junta todas las fotos en una sola imagen con miniaturas y su nombre (evidencia pequeña pero completa).
  Future<XFile?> _armarHoja(List<_Paso> con) async {
    const columnas = 3;
    const celda = 300.0;
    const margen = 12.0;
    const pie = 34.0;
    const cabecera = 50.0;
    final filas = (con.length / columnas).ceil();
    final ancho = columnas * celda + (columnas + 1) * margen;
    final alto = cabecera + filas * (celda + pie + margen) + margen;
    final grabador = ui.PictureRecorder();
    final lienzo = Canvas(grabador, Rect.fromLTWH(0, 0, ancho, alto));
    lienzo.drawRect(Rect.fromLTWH(0, 0, ancho, alto), Paint()..color = const Color(0xFFFFFFFF));
    void texto(String t, Offset o, double tam, {bool negrita = false, double maxAncho = 300}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: const Color(0xFF222222), fontSize: tam, fontWeight: negrita ? FontWeight.bold : FontWeight.normal)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxAncho);
      tp.paint(lienzo, o);
    }
    final lima = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    String dos(int n) => n.toString().padLeft(2, '0');
    texto('Evidencia de escaneo · ${dos(lima.day)}/${dos(lima.month)}/${lima.year} ${dos(lima.hour)}:${dos(lima.minute)} (Lima)', const Offset(margen, 14), 18, negrita: true, maxAncho: ancho - 2 * margen);
    for (var i = 0; i < con.length; i++) {
      final f = i ~/ columnas;
      final c = i % columnas;
      final x = margen + c * (celda + margen);
      final y = cabecera + f * (celda + pie + margen);
      final bytes = await File(con[i].foto!.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: celda.toInt());
      final img = (await codec.getNextFrame()).image;
      final alta = img.height.toDouble() > celda ? celda : img.height.toDouble();
      lienzo.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), alta),
        Rect.fromLTWH(x, y, celda, alta),
        Paint()..filterQuality = FilterQuality.medium,
      );
      texto('${i + 1}. ${con[i].titulo}', Offset(x, y + celda + 6), 14, maxAncho: celda);
    }
    final imagen = await grabador.endRecording().toImage(ancho.toInt(), alto.toInt());
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    if (datos == null) return null;
    final archivo = File('${Directory.systemTemp.path}/hoja_evidencia_${DateTime.now().millisecondsSinceEpoch}.png');
    await archivo.writeAsBytes(datos.buffer.asUint8List());
    return XFile(archivo.path);
  }

  void _agregarFoto(String rol, String titulo, String ayuda) {
    setState(() {
      _res = null;
      _pasos.add(_Paso('extra${_pasos.length}', rol, titulo, ayuda, true, false));
    });
  }

  String? _rolDeFalta(String f) {
    final t = _sinTildes(f);
    if (t.contains('modelo')) return 'MODELO';
    if (t.contains('motor')) return 'MOTOR';
    if (t.contains('serie') || t.contains('imei')) {
      return (_tipoFinal == 'MOTO_LINEAL' || _tipoFinal == 'MOTOCAR' || _tipoFinal == 'AUTO')
          ? 'CHASIS'
          : 'SERIE';
    }
    return null;
  }

  void _menuOtraFoto() {
    final esVeh = _tipoFinal == 'MOTO_LINEAL' || _tipoFinal == 'MOTOCAR' || _tipoFinal == 'AUTO';
    final opciones = <List<String>>[
      ['SERIE', 'Foto extra: serie', 'Acerca solo el número de serie.'],
      ['MODELO', 'Foto extra: modelo', 'Acerca la etiqueta donde dice Model / Modelo.'],
      if (esVeh) ['MOTOR', 'Foto extra: motor', 'Número grabado en el motor.'],
      if (esVeh) ['TARJETA', 'Foto extra: tarjeta (reverso u otra hoja)', 'Que se lea todo el texto.'],
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          for (final o in opciones)
            ListTile(
              leading: const Icon(Icons.add_a_photo_outlined),
              title: Text(o[1]),
              onTap: () {
                Navigator.pop(ctx);
                _agregarFoto(o[0], o[1], o[2]);
              },
            ),
        ]),
      ),
    );
  }

  Color _colorConf(String? c) {
    switch (c) {
      case 'ALTA':
        return Colors.green;
      case 'MEDIA':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Widget _campo(String k, String etiqueta) {
    final conf = (_res?['confianza'] as Map?)?[k]?.toString();
    final vacio = (_ctl[k]?.text ?? '').isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _ctl[k],
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
          helperText: vacio
              ? 'No se pudo leer: escríbelo a mano'
              : conf == 'ALTA'
                  ? 'Leído con buena seguridad'
                  : 'Revísalo con el bien en la mano',
          helperStyle: TextStyle(
              color: vacio ? Colors.red : _colorConf(conf),
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _panelTipo() {
    final d = _res?['tipoDetectado'];
    if (d is! Map) return const SizedBox.shrink();
    final t = '${d['tipo']}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.auto_awesome, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('Reconocido como: ${_tipos[t] ?? t}. ${d['motivo']}', style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _panelMemoria() {
    final m = _res?['memoria'];
    if (m is! Map) return const SizedBox.shrink();
    final val = m['valorizacionTipica'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ya registraste este modelo ${m['veces']} vez/veces antes.',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Text('Descripción usada: ${m['descripcion']}${val != null ? '\nValorización típica: S/ $val' : ''}',
            style: const TextStyle(fontSize: 13)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _ctl['descripcion']?.text = '${m['descripcion']}'),
            child: const Text('Usar esa descripción'),
          ),
        ),
      ]),
    );
  }

  Widget _panelFotos() {
    final con = _pasos.where((p) => p.foto != null).toList();
    if (con.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Fotos que se guardan: ${_elegidas.length} de $_maxElegidas${_conHoja ? ' + la hoja con todas' : ''}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(
          _conHoja
              ? 'Tomaste $_totalFotos fotos. Se guardan las ${_maxElegidas} que elijas y una hoja con miniaturas de todas, como evidencia en el expediente. El sistema eligió las que tienen más información; toca para cambiar.'
              : 'El sistema eligió las que tienen más información. Toca para cambiar.',
          style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in con)
          GestureDetector(
            onTap: () => setState(() {
              final k = p.foto!.path;
              if (_elegidas.contains(k)) {
                _elegidas.remove(k);
              } else if (_elegidas.length < _maxElegidas) {
                _elegidas.add(k);
              }
            }),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: _elegidas.contains(p.foto!.path) ? Colors.green : Colors.grey.shade300,
                    width: _elegidas.contains(p.foto!.path) ? 3 : 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(File(p.foto!.path), width: 70, height: 70, fit: BoxFit.cover),
              ),
            ),
          ),
      ]),
    ]);
  }

  Widget _revision() {
    final avisos = List<String>.from((_res?['avisos'] ?? []).map((e) => '$e'));
    final verif = List<Map>.from(_res?['verificaciones'] ?? []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Revisa lo que leyó el sistema',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
            'Compara con el bien. Corrige lo que esté mal; lo que no se pudo leer lo escribes tú.',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        _panelTipo(),
        _panelMemoria(),
        for (final a in avisos)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: a.startsWith('ATENCIÓN') || a.contains('no coincide')
                    ? Colors.red.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8)),
            child: Text(a, style: const TextStyle(fontSize: 13)),
          ),
        for (final v in verif)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: v['estado'] == 'COINCIDE'
                    ? Colors.green.shade50
                    : v['estado'] == 'DIFERENTE'
                        ? Colors.red.shade50
                        : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(
                  v['estado'] == 'COINCIDE'
                      ? Icons.verified
                      : v['estado'] == 'DIFERENTE'
                          ? Icons.error
                          : Icons.info_outline,
                  size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('${v['detalle']}',
                      style: const TextStyle(fontSize: 13))),
            ]),
          ),
        const SizedBox(height: 6),
        _campo('descripcion', 'Descripción'),
        _campo('marca', 'Marca'),
        _campo('modelo', 'Modelo'),
        _campo('serie', _tipoFinal == 'CELULAR' ? 'Serie / IMEI' : 'Serie'),
        if (_tipoFinal == 'MOTO_LINEAL' || _tipoFinal == 'MOTOCAR' || _tipoFinal == 'AUTO')
          _campo('placa', 'Placa'),
        _campo('color', 'Color (el sistema no lo lee: míralo y escríbelo)'),
        TextField(
          controller: _ctl['extras'],
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Otros datos (van a Observaciones)',
              border: OutlineInputBorder(),
              isDense: true),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _obsAdicional,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Observaciones propias (contraseña, estado, accesorios...)',
              border: OutlineInputBorder(),
              isDense: true),
        ),
        const SizedBox(height: 12),
        _panelFotos(),
        for (final f in List<String>.from((_res?['faltan'] ?? []).map((e) => '$e')))
          if (_rolDeFalta(f) != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton.icon(
                onPressed: () => _agregarFoto(_rolDeFalta(f)!, 'Foto extra: $f', 'Acerca la cámara donde está $f.'),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text('Falta $f: tomar otra foto'),
              ),
            ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _guardando ? null : _usar,
          icon: _guardando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check),
          label: Text(_guardando ? 'Preparando fotos...' : 'Usar estos datos'),
        ),
        TextButton(
          onPressed: () => setState(() => _res = null),
          child: const Text('Volver a las fotos'),
        ),
      ],
    );
  }

  Widget _tarjetaPaso(int i, _Paso p) {
    final ok = p.foto != null;
    final sinTexto = ok && p.leerTexto && !p.leyendo && p.textos.every((t) => t.trim().isEmpty) && p.codigos.isEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ok
                ? Image.file(
                    File(p.foto!.path),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover)
                : Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.photo_camera_outlined)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}. ${p.titulo}${p.obligatorio ? '' : ' (opcional)'}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(p.ayuda,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              if (p.leyendo)
                const Row(children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Leyendo texto...'),
                ])
              else if (sinTexto)
                const Text('No se leyó texto. Acércate más y evita reflejos.',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: p.leyendo ? null : () => _tomar(p),
                  icon: Icon(ok ? Icons.refresh : Icons.photo_camera),
                  label: Text(ok ? 'Tomar otra vez' : 'Tomar foto'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _fotos() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('¿Qué vas a registrar?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final e in _tipos.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: _tipo == e.key,
              onSelected: (_) {
                if (_tipo == e.key) return;
                setState(() => _tipo = e.key);
                _cargarGuia();
              },
            ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Text(
              'Toma las fotos que se piden. El sistema lee solo el texto de las etiquetas (marca, modelo, serie, IMEI, placa) y se guardan hasta 3 fotos como evidencia. Para series pequeñas, toma la foto bien de cerca.',
              style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 12),
        if (_cargandoGuia)
          const Center(child: CircularProgressIndicator())
        else
          for (var i = 0; i < _pasos.length; i++) _tarjetaPaso(i, _pasos[i]),
        if (!_cargandoGuia)
          OutlinedButton.icon(
            onPressed: _menuOtraFoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Agregar otra foto (serie, modelo...)'),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        FilledButton.icon(
          onPressed: _listo && !_consultando && !_pasos.any((p) => p.leyendo)
              ? _leerDatos
              : null,
          icon: _consultando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_fix_high),
          label: Text(_consultando ? 'Leyendo...' : 'Leer datos'),
        ),
        if (!_listo)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Falta tomar las fotos que no dicen "opcional".',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear bien'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(child: _res == null ? _fotos() : _revision()),
    );
  }
}

/// Resultado de capturar un solo campo (serie, modelo...) con una foto.
class CapturaCampo {
  CapturaCampo(this.valor, this.foto, [this.tipo = 'OTRO']);
  final String valor;
  final XFile foto;
  /// Tipo de bien que reconoció el sistema (CELULAR, LAPTOP, MOTO_LINEAL...), para elegir la categoría solo.
  final String tipo;
}

List<String> _candidatos(String texto) {
  final out = <String>[];
  for (final linea in texto.split(RegExp(r'[\r\n]+'))) {
    final l = linea.trim();
    if (l.length >= 3 && l.length <= 40 && !out.contains(l)) out.add(l);
    for (final t in l.split(RegExp(r'[\s,;:]+'))) {
      final x = t.replaceAll(RegExp(r'[^A-Za-z0-9\-/]'), '');
      if (x.length >= 4 && x.length <= 30 && RegExp(r'\d').hasMatch(x) && !out.contains(x)) {
        out.add(x);
      }
    }
  }
  return out.take(12).toList();
}

/// Botón de cámara para cualquier buscador: se toman hasta 4 fotos del bien (aunque no tengan texto) y sale la lista de
/// bienes iguales o parecidos. Al tocar uno, su código o serie se pone en el buscador.
Widget botonBuscarConFoto(BuildContext context, {required void Function(String valor) alLeer}) {
  return IconButton(
    tooltip: 'Buscar con foto: el mismo bien o los parecidos',
    icon: const Icon(Icons.photo_camera_outlined),
    onPressed: () async {
      final v = await Navigator.of(context).push<String>(
        MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _BuscarParecidosPage()),
      );
      if (v == null || v.trim().isEmpty) return;
      alLeer(v.trim());
    },
  );
}

class _FotoBusqueda {
  _FotoBusqueda(this.foto, this.textos, this.codigos, this.etiquetas, this.imagen);
  final XFile foto;
  /// La foto en base64 (ya reducida) para que el servidor compare cómo se ve contra las fotos registradas.
  final String imagen;
  final String textos;
  final List<String> codigos;
  final List<String> etiquetas;
}

class _BuscarParecidosPage extends StatefulWidget {
  const _BuscarParecidosPage();
  @override
  State<_BuscarParecidosPage> createState() => _BuscarParecidosPageState();
}

class _BuscarParecidosPageState extends State<_BuscarParecidosPage> {
  final List<_FotoBusqueda> _fotos = [];
  List<Map<String, dynamic>> _resultados = [];
  bool _leyendo = false;
  bool _buscando = false;
  bool _buscado = false;
  String _error = '';
  String _color = '';

  static const _colores = ['negro', 'blanco', 'plata', 'gris', 'rojo', 'azul', 'verde', 'amarillo', 'dorado'];

  Future<void> _tomarFoto(ImageSource origen) async {
    final foto = await ImagePicker().pickImage(source: origen, imageQuality: 85, maxWidth: 1000);
    if (foto == null || !mounted) return;
    setState(() => _leyendo = true);
    var imagen64 = '';
    try {
      imagen64 = base64Encode(await foto.readAsBytes());
    } catch (_) {}
    var texto = '';
    var codigos = <String>[];
    final etiquetas = await _etiquetasDeImagen(foto.path);
    final reconocedor = TextRecognizer(script: TextRecognitionScript.latin);
    final lector = BarcodeScanner();
    try {
      final entrada = InputImage.fromFilePath(foto.path);
      texto = (await reconocedor.processImage(entrada)).text;
      codigos = (await lector.processImage(entrada))
          .map((b) => b.rawValue ?? '')
          .where((x) => x.isNotEmpty)
          .toList();
    } catch (_) {
    } finally {
      await reconocedor.close();
      await lector.close();
    }
    if (!mounted) return;
    setState(() {
      _fotos.add(_FotoBusqueda(foto, texto, codigos, etiquetas, imagen64));
      _leyendo = false;
    });
    // con la primera foto ya se busca solo; las siguientes afinan
    await _buscar();
  }

  String _avisoImagen = '';

  Future<void> _buscar({bool sinImagen = false}) async {
    if (_fotos.isEmpty) return;
    setState(() {
      _buscando = true;
      _error = '';
      if (!sinImagen) _avisoImagen = '';
    });
    try {
      final r = await _dioEscaner.post('/operacion/escaner/consultar-parecidos', data: {
        'fuentes': [
          for (var i = 0; i < _fotos.length; i++)
            {
              'etiqueta': 'foto ${i + 1}',
              'rol': 'GENERAL',
              'textos': [_fotos[i].textos],
              'codigos': _fotos[i].codigos,
              'etiquetas': _fotos[i].etiquetas,
              if (!sinImagen && _fotos[i].imagen.isNotEmpty) 'imagen': _fotos[i].imagen,
            }
        ],
        if (_color.isNotEmpty) 'color': _color,
      });
      final b = _body(r);
      final lista = (b is Map && b['resultados'] is List) ? (b['resultados'] as List) : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _resultados = lista.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _buscado = true;
        _buscando = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Si el servidor corta la conexión al recibir la foto, se reintenta una vez solo con texto, códigos y color
      final sinRespuesta = e is! DioException || e.response == null;
      final hayImagen = _fotos.any((f) => f.imagen.isNotEmpty);
      if (!sinImagen && sinRespuesta && hayImagen) {
        setState(() => _avisoImagen = 'No se pudo comparar la imagen con el servidor; se buscó solo con el texto, códigos y color de la foto.');
        return _buscar(sinImagen: true);
      }
      var msg = 'No se pudo buscar. Revisa la conexión e intenta de nuevo.';
      if (e is DioException) {
        final code = e.response?.statusCode;
        final d = e.response?.data;
        if (code == 404) {
          msg = 'El servidor todavía no tiene la búsqueda con foto (se está actualizando). Espera unos minutos y toca "Buscar de nuevo".';
        } else if (code != null && d is Map && d['message'] != null) {
          msg = 'El servidor respondió: ${d['message']}';
        } else if (code != null) {
          msg = 'El servidor tuvo un problema (código $code). Intenta de nuevo en un momento.';
        } else if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
          msg = 'El servidor demoró en responder. Toca "Buscar de nuevo".';
        } else {
          msg = 'No llegó respuesta del servidor. Revisa tu señal y toca "Buscar de nuevo". [${e.type.name}${e.error != null ? ': ${e.error.toString().split('\n').first}' : ''}]';
        }
      } else {
        msg = 'No se pudo leer la respuesta de la búsqueda: $e';
      }
      setState(() {
        _error = msg;
        _buscando = false;
      });
    }
  }

  String _identificador(Map<String, dynamic> r) {
    for (final k in ['codigoInventario', 'prestamoCodigo', 'serie', 'placa']) {
      final v = '${r[k] ?? ''}'.trim();
      if (v.isNotEmpty && v != 'null') return v;
    }
    return '${r['descripcion'] ?? ''}'.trim();
  }

  Color _colorNivel(String n) {
    if (n == 'EXACTO') return Colors.green.shade700;
    if (n == 'MUY_PARECIDO') return Colors.orange.shade800;
    return Colors.blueGrey;
  }

  String _textoNivel(String n) {
    if (n == 'EXACTO') return 'ES ESTE';
    if (n == 'MUY_PARECIDO') return 'MUY PARECIDO';
    return 'PARECIDO';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar con foto')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'Toma una foto del bien (hasta 4: de frente, la etiqueta, la serie). Aunque no tenga letras, te muestro los iguales y los parecidos.',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _fotos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(_fotos[i].foto.path), width: 88, height: 88, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: InkWell(
                          onTap: () {
                            setState(() => _fotos.removeAt(i));
                            if (_fotos.isEmpty) {
                              setState(() {
                                _resultados = [];
                                _buscado = false;
                              });
                            } else {
                              _buscar();
                            }
                          },
                          child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                        ),
                      ),
                    ]),
                  ),
                if (_fotos.length < 4)
                  InkWell(
                    onTap: _leyendo ? null : () => _tomarFoto(ImageSource.camera),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: _leyendo
                          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined), SizedBox(height: 4), Text('Foto', style: TextStyle(fontSize: 12))]),
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _leyendo || _fotos.length >= 4 ? null : () => _tomarFoto(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Elegir de la galería'),
          ),
          Wrap(spacing: 6, children: [
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('Color:')),
            for (final c in _colores)
              ChoiceChip(
                label: Text(c),
                selected: _color == c,
                onSelected: (v) {
                  setState(() => _color = v ? c : '');
                  _buscar();
                },
              ),
          ]),
          const Divider(),
          if (_buscando) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          if (_avisoImagen.isNotEmpty && _error.isEmpty) Text(_avisoImagen, style: const TextStyle(color: Colors.orange, fontSize: 12)),
          if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
          if (_error.isNotEmpty && _fotos.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(onPressed: _buscando ? null : _buscar, icon: const Icon(Icons.refresh), label: const Text('Buscar de nuevo')),
            ),
          if (_buscado && !_buscando && _resultados.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No encontré nada parecido. Prueba con otra foto (la etiqueta o la serie ayudan mucho).')),
          for (final r in _resultados)
            Card(
              child: ListTile(
                leading: (r['imagen'] != null && '${r['imagen']}'.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network('$endPointPrincipal/${r['imagen']}', width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined)),
                      )
                    : const Icon(Icons.inventory_2_outlined),
                title: Text('${r['descripcion'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text([
                    if ('${r['marca'] ?? ''}'.isNotEmpty) '${r['marca']}',
                    if ('${r['modelo'] ?? ''}'.isNotEmpty) '${r['modelo']}',
                    if ('${r['color'] ?? ''}'.isNotEmpty) '${r['color']}',
                  ].where((e) => e != 'null').join(' · ')),
                  if (r['prestamoCodigo'] != null) Text('Préstamo ${r['prestamoCodigo']}${r['estado'] != null ? ' · ${r['estado']}' : ''}'),
                  if (r['codigoInventario'] != null) Text('Código ${r['codigoInventario']}'),
                  Text(((r['motivos'] as List?) ?? const []).take(2).join(' · '), style: const TextStyle(fontSize: 12)),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: _colorNivel('${r['nivel']}'), borderRadius: BorderRadius.circular(10)),
                    child: Text(_textoNivel('${r['nivel']}'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]),
                isThreeLine: true,
                onTap: () => Navigator.of(context).pop(_identificador(r)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Toma una foto y lee solo ese campo: 'serie', 'modelo' o 'descripcion'. La persona confirma o corrige antes de usarlo.
Future<CapturaCampo?> capturarCampo(
  BuildContext context, {
  required String campo,
  required String tipo,
}) async {
  final cap = await _elegirCaptura(context);
  if (cap == null || !context.mounted) return null;
  if (cap.vivo) {
    final v = await abrirEscanerVivo(context, campo: campo);
    if (v == null || !context.mounted) return null;
    if (v.sinCamara || v.foto == null || v.valor.isEmpty) {
      if (v.sinCamara) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la cámara en vivo. Usa «Tomar foto ahora».')));
      }
      return null;
    }
    // el tipo de bien (celular, laptop, moto...) se reconoce con lo leído, sin molestar a la persona
    var tipoVivo = tipo;
    try {
      final r = await _dioEscaner.post('/operacion/escaner/consultar', data: {
        'tipo': (tipo.isEmpty || tipo == 'OTRO') ? 'DETECTAR' : tipo,
        'fuentes': [
          {
            'etiqueta': campo,
            'rol': campo == 'modelo' ? 'MODELO' : (campo == 'serie' ? 'SERIE' : 'GENERAL'),
            'textos': v.textos,
            'codigos': v.codigos,
            'etiquetas': <String>[],
          }
        ],
      }, options: Options(receiveTimeout: const Duration(seconds: 8), sendTimeout: const Duration(seconds: 8)));
      final b = _body(r);
      if (b is Map && '${b['tipo'] ?? ''}'.isNotEmpty) tipoVivo = '${b['tipo']}';
    } catch (_) {}
    return CapturaCampo(v.valor, v.foto!, tipoVivo);
  }
  final foto = await ImagePicker().pickImage(source: cap.origen!, imageQuality: 92);
  if (foto == null || !context.mounted) return null;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(children: [
        SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 16),
        Expanded(child: Text('Leyendo la foto...')),
      ]),
    ),
  );

  var texto = '';
  var codigos = <String>[];
  final etiquetas = await _etiquetasDeImagen(foto.path);
  final reconocedor = TextRecognizer(script: TextRecognitionScript.latin);
  final lector = BarcodeScanner();
  try {
    final entrada = InputImage.fromFilePath(foto.path);
    texto = (await reconocedor.processImage(entrada)).text;
    codigos = (await lector.processImage(entrada))
        .map((b) => b.rawValue ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  } catch (_) {
  } finally {
    await reconocedor.close();
    await lector.close();
  }

  var propuesto = '';
  var tipoReconocido = tipo;
  try {
    final r = await _dioEscaner.post('/operacion/escaner/consultar', data: {
      'tipo': (tipo.isEmpty || tipo == 'OTRO') ? 'DETECTAR' : tipo,
      'fuentes': [
        {
          'etiqueta': campo,
          'rol': campo == 'modelo' ? 'MODELO' : (campo == 'serie' ? 'SERIE' : 'GENERAL'),
          'textos': [texto],
          'codigos': codigos,
          'etiquetas': etiquetas,
        }
      ],
    });
    final b = _body(r);
    if (b is Map && b['campos'] is Map) {
      propuesto = '${(b['campos'] as Map)[campo] ?? ''}';
      tipoReconocido = '${b['tipo'] ?? 'OTRO'}';
    }
  } catch (_) {
    // sin conexión con el servidor: igual se puede elegir el texto leído
  }
  if (propuesto.isEmpty && codigos.isNotEmpty && campo == 'serie') propuesto = codigos.first;

  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop(); // cierra "Leyendo..."

  final cands = {..._candidatos(texto), ...codigos}.where((e) => e != propuesto).take(12).toList();
  final ctl = TextEditingController(text: propuesto);
  final nombre = campo == 'serie' ? 'la serie' : (campo == 'modelo' ? 'el modelo' : (campo == 'placa' ? 'la placa' : 'la descripción'));
  final elegido = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(propuesto.isEmpty ? 'No se pudo leer $nombre' : 'Esto se leyó. Revísalo con el bien.',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: ctl,
              autofocus: propuesto.isEmpty,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: campo == 'serie' ? 'Serie' : (campo == 'modelo' ? 'Modelo' : (campo == 'placa' ? 'Placa' : 'Descripción')),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (cands.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Otros textos que se leyeron (toca uno para usarlo):',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 0, children: [
                for (final c in cands)
                  ActionChip(
                    label: Text(c, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ctl.text = c,
                  ),
              ]),
            ],
            const SizedBox(height: 12),
            Row(children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
                icon: const Icon(Icons.check),
                label: const Text('Usar'),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
  ctl.dispose();
  if (elegido == null || elegido.isEmpty) return null;
  return CapturaCampo(elegido, foto, tipoReconocido);
}
