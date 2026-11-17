import 'package:casa_empenio_pe/presentation/app/utils/sesion_segura.dart';
import 'dart:convert';
import 'dart:io';

import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
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
      return ['celular', 'telefono'];
    case 'LAPTOP':
      return ['laptop', 'computadora'];
    case 'MOTO_LINEAL':
      return ['moto lineal', 'lineal', 'moto'];
    case 'MOTOCAR':
      return ['motocar', 'motokar'];
    case 'AUTO':
      return ['auto', 'camioneta', 'vehiculo'];
    case 'MOTOR':
      return ['motor', 'maquinaria'];
    case 'ELECTRO':
      return ['electro'];
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
          .get('operacion/escaner/guia', queryParameters: {'tipo': _tipo});
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
    final picker = ImagePicker();
    final foto = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 92);
    if (foto == null) return;
    setState(() {
      p.foto = foto;
      p.textos = [];
      p.codigos = [];
      p.leyendo = p.leerTexto;
    });
    if (!p.leerTexto) return;
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
      final r = await _dioEscaner.post('operacion/escaner/consultar', data: {
        'tipo': _tipo,
        'fuentes': _pasos
            .where((p) => p.foto != null && p.leerTexto)
            .map((p) => {
                  'etiqueta': p.titulo,
                  'rol': p.rol,
                  'textos': p.textos,
                  'codigos': p.codigos,
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
      if (out.length >= 3) break;
      out.add(p);
    }
    return out.map((p) => p.foto!).toList();
  }

  List<XFile> _fotosParaGuardar() =>
      _pasos.where((p) => p.foto != null && _elegidas.contains(p.foto!.path)).map((p) => p.foto!).take(3).toList();

  void _usar() {
    final campos = <String, String>{
      for (final e in _ctl.entries)
        if (e.key != 'extras') e.key: e.value.text.trim(),
    };
    Navigator.of(context).pop(EscanerResultado(
      tipo: _tipoFinal,
      campos: campos,
      extras: _ctl['extras']?.text.trim() ?? '',
      observaciones: _obsAdicional.text.trim(),
      fotos: _fotosParaGuardar(),
    ));
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
      Text('Fotos que se guardan: ${_elegidas.length} de 3',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      const Text('El sistema eligió las que tienen más información. Toca para cambiar.',
          style: TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in con)
          GestureDetector(
            onTap: () => setState(() {
              final k = p.foto!.path;
              if (_elegidas.contains(k)) {
                _elegidas.remove(k);
              } else if (_elegidas.length < 3) {
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
          onPressed: _usar,
          icon: const Icon(Icons.check),
          label: const Text('Usar estos datos'),
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
  CapturaCampo(this.valor, this.foto);
  final String valor;
  final XFile foto;
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

/// Toma una foto y lee solo ese campo: 'serie', 'modelo' o 'descripcion'. La persona confirma o corrige antes de usarlo.
Future<CapturaCampo?> capturarCampo(
  BuildContext context, {
  required String campo,
  required String tipo,
}) async {
  final foto = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 92);
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
  try {
    final r = await _dioEscaner.post('operacion/escaner/consultar', data: {
      'tipo': tipo,
      'fuentes': [
        {
          'etiqueta': campo,
          'rol': campo == 'modelo' ? 'MODELO' : (campo == 'serie' ? 'SERIE' : 'GENERAL'),
          'textos': [texto],
          'codigos': codigos,
        }
      ],
    });
    final b = _body(r);
    if (b is Map && b['campos'] is Map) {
      propuesto = '${(b['campos'] as Map)[campo] ?? ''}';
    }
  } catch (_) {
    // sin conexión con el servidor: igual se puede elegir el texto leído
  }
  if (propuesto.isEmpty && codigos.isNotEmpty && campo == 'serie') propuesto = codigos.first;

  if (!context.mounted) return null;
  Navigator.of(context, rootNavigator: true).pop(); // cierra "Leyendo..."

  final cands = {..._candidatos(texto), ...codigos}.where((e) => e != propuesto).take(12).toList();
  final ctl = TextEditingController(text: propuesto);
  final nombre = campo == 'serie' ? 'la serie' : (campo == 'modelo' ? 'el modelo' : 'la descripción');
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
                labelText: campo == 'serie' ? 'Serie' : (campo == 'modelo' ? 'Modelo' : 'Descripción'),
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
  return CapturaCampo(elegido, foto);
}
