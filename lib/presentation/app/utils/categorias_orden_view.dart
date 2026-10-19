import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// "Ordenar mis categorías": revisa las categorías reales del negocio, avisa
// cuáles se repiten o conviene agrupar como subcategorías, y les pone sus
// campos propios (plantillas: vehículo, terreno, laptop...). Nada se borra de
// los préstamos ya hechos; todo se confirma antes de aplicarse.
// ---------------------------------------------------------------------------

List<Map<String, dynamic>> _lista(dynamic d) {
  dynamic x = d;
  if (x is String) {
    try {
      x = jsonDecode(x);
    } catch (_) {}
  }
  if (x is Map && x['body'] != null) x = x['body'];
  if (x is String) {
    try {
      x = jsonDecode(x);
    } catch (_) {}
  }
  if (x is List) {
    return x
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return <Map<String, dynamic>>[];
}

String _mensajeError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      return m is List ? m.join(', ') : m.toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'No hay conexión con el servidor';
    }
  }
  return 'No se pudo completar. Intente de nuevo.';
}

String _normalizar(String t) {
  const de = 'áéíóúüñÁÉÍÓÚÜÑ';
  const a = 'aeiouunAEIOUUN';
  var s = t.trim();
  for (var i = 0; i < de.length; i++) {
    s = s.replaceAll(de[i], a[i]);
  }
  return s.toLowerCase();
}

/// Clave para comparar nombres: sin tildes, sin espacios y en singular.
String _clave(String t) {
  var s = _normalizar(t).replaceAll(RegExp(r'[^a-z0-9]+'), '');
  if (s.length > 4 && s.endsWith('es')) {
    s = s.substring(0, s.length - 2);
  } else if (s.length > 3 && s.endsWith('s')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// Plantilla sugerida según el nombre de la categoría (o null).
Map<String, dynamic>? sugerirPlantillaCategoria(
    String descripcion, List<Map<String, dynamic>> plantillas) {
  final palabras = _normalizar(descripcion)
      .split(RegExp(r'[^a-z0-9]+'))
      .where((e) => e.isNotEmpty)
      .toList();
  for (final p in plantillas) {
    final claves = (p['palabras'] as List? ?? const []).map((e) => e.toString());
    for (final w in claves) {
      if (palabras.contains(w) ||
          palabras.contains('${w}s') ||
          palabras.contains('${w}es')) {
        return p;
      }
    }
  }
  return null;
}

/// Pregunta cuál plantilla aplicar. Devuelve la clave o null.
Future<String?> elegirPlantilla(
  BuildContext context,
  List<Map<String, dynamic>> plantillas, {
  String? sugerida,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('¿Qué tipo de bien es?'),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            'Se agregan los campos típicos de ese bien. Todos son opcionales '
            'y después puede quitar o agregar los que quiera.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        for (final p in plantillas)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, p['clave'].toString()),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${p['nombre']}  (${(p['campos'] as List).length} campos)',
                    style: TextStyle(
                      fontWeight: p['clave'] == sugerida
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (p['clave'] == sugerida)
                  const Text('sugerida',
                      style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ),
      ],
    ),
  );
}

class CategoriasOrdenPage extends StatefulWidget {
  const CategoriasOrdenPage({Key? key, required this.dio}) : super(key: key);

  final Dio dio;

  @override
  State<CategoriasOrdenPage> createState() => _CategoriasOrdenPageState();
}

class _CategoriasOrdenPageState extends State<CategoriasOrdenPage> {
  List<Map<String, dynamic>> _cats = [];
  List<Map<String, dynamic>> _plantillas = [];
  final Map<int, int> _camposPorCat = {};
  bool _cargando = true;
  bool _trabajando = false;
  String? _error;

  Dio get _dio => widget.dio;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  int _id(Map<String, dynamic> c) => (c['id'] as num).toInt();
  int? _padre(Map<String, dynamic> c) => (c['padreId'] as num?)?.toInt();
  String _nombre(Map<String, dynamic> c) => (c['descripcion'] ?? '').toString();
  int _nCampos(int id) => _camposPorCat[id] ?? 0;

  Map<String, dynamic>? _porId(int? id) {
    if (id == null) return null;
    for (final c in _cats) {
      if (_id(c) == id) return c;
    }
    return null;
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await Future.wait([
        _dio.get<dynamic>('/almacen/producto/categoria'),
        _dio.get<dynamic>('/api/dynamic-fields/plantillas'),
        _dio.get<dynamic>('/api/dynamic-fields/definitions',
            queryParameters: {'is_active': true}),
      ]);
      _cats = _lista(r[0].data);
      _plantillas = _lista(r[1].data);
      _camposPorCat.clear();
      for (final d in _lista(r[2].data)) {
        final cat = d['category'];
        final id = cat is Map ? (cat['id'] as num?)?.toInt() : null;
        if (id != null) _camposPorCat[id] = (_camposPorCat[id] ?? 0) + 1;
      }
    } catch (e) {
      _error = _mensajeError(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t)));
  }

  Future<bool> _confirmar(String titulo, String texto) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, hacerlo')),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _hacer(Future<String> Function() accion) async {
    setState(() => _trabajando = true);
    try {
      final msg = await accion();
      _aviso(msg);
    } catch (e) {
      _aviso(_mensajeError(e));
    }
    await _cargar();
    if (mounted) setState(() => _trabajando = false);
  }

  // ---- acciones ----

  Future<String> _aplicarPlantilla(int catId, String clave) async {
    final r = await _dio.post<dynamic>('/api/dynamic-fields/plantillas/aplicar',
        data: {'category_id': catId, 'plantilla': clave});
    final d = r.data;
    final n = d is Map ? (d['creados'] ?? 0) : 0;
    return 'Listo: se agregaron $n campos';
  }

  Future<String> _ponerPadre(int id, int? padreId) async {
    await _dio.put<dynamic>('/almacen/producto/categoria/$id/padre',
        data: {'padreId': padreId});
    return padreId == null ? 'Ahora es categoría principal' : 'Convertida en subcategoría';
  }

  Future<String> _unir(int origen, int destino) async {
    await _dio.post<dynamic>('/almacen/producto/categoria/$origen/fusionar',
        data: {'destinoId': destino});
    return 'Categorías unidas';
  }

  Future<int> _crearCategoria(String nombre) async {
    final r = await _dio
        .post<dynamic>('/almacen/producto/categoria', data: {'descripcion': nombre});
    var d = r.data;
    if (d is String) d = jsonDecode(d);
    final body = d is Map ? d['body'] : null;
    final id = body is Map ? (body['id'] as num?)?.toInt() : null;
    if (id == null) throw Exception('sin id');
    return id;
  }

  // ---- análisis ----

  /// Grupos de categorías cuyo nombre es el mismo (singular/plural, tildes...).
  List<List<Map<String, dynamic>>> _repetidas() {
    final mapa = <String, List<Map<String, dynamic>>>{};
    for (final c in _cats) {
      mapa.putIfAbsent(_clave(_nombre(c)), () => []).add(c);
    }
    return mapa.values.where((g) => g.length > 1).toList();
  }

  /// Familias: varias categorías sueltas del mismo tipo de bien (ej. Moto, Auto).
  List<_Familia> _familias() {
    final repetidasIds = <int>{};
    for (final g in _repetidas()) {
      for (final c in g.skip(1)) {
        repetidasIds.add(_id(c));
      }
    }
    final mapa = <String, List<Map<String, dynamic>>>{};
    final plant = <String, Map<String, dynamic>>{};
    for (final c in _cats) {
      if (_padre(c) != null || repetidasIds.contains(_id(c))) continue;
      final p = sugerirPlantillaCategoria(_nombre(c), _plantillas);
      if (p == null) continue;
      final k = p['clave'].toString();
      mapa.putIfAbsent(k, () => []).add(c);
      plant[k] = p;
    }
    final out = <_Familia>[];
    mapa.forEach((k, lista) {
      final p = plant[k]!;
      // ¿ya hay una categoría "general" (ej. "Vehículos")?
      final generales = (p['palabras'] as List).isEmpty
          ? <String>{}
          : {_clave(p['nombre'].toString()), _clave((p['palabras'] as List).first.toString())};
      Map<String, dynamic>? general;
      for (final c in lista) {
        if (generales.contains(_clave(_nombre(c)))) general = c;
      }
      final hijos = lista.where((c) => c != general).toList();
      // solo vale la pena agrupar si hay 2 o más, o hay una general con otra
      final hayHijosHuerfanos = hijos.isNotEmpty && (general != null || hijos.length > 1);
      if (!hayHijosHuerfanos) return;
      out.add(_Familia(plantilla: p, general: general, hijos: hijos));
    });
    return out;
  }

  /// Categorías con plantilla sugerida pero sin campos propios ni heredados.
  List<_SinCampos> _sinCampos() {
    final out = <_SinCampos>[];
    for (final c in _cats) {
      final p = sugerirPlantillaCategoria(_nombre(c), _plantillas);
      if (p == null) continue;
      if (_nCampos(_id(c)) > 0) continue;
      final padre = _porId(_padre(c));
      if (padre != null && _nCampos(_id(padre)) > 0) continue;
      out.add(_SinCampos(c, p));
    }
    return out;
  }

  // ---- UI ----

  Widget _tarjeta(Color color, IconData icono, String titulo, String detalle,
      {List<Widget> acciones = const []}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.5))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: color),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 4),
            Text(detalle, style: const TextStyle(fontSize: 13)),
            if (acciones.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: acciones),
            ],
          ],
        ),
      ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  Future<void> _unirGrupo(List<Map<String, dynamic>> grupo) async {
    // se queda la que tiene más campos (o la primera)
    final orden = [...grupo]
      ..sort((a, b) => _nCampos(_id(b)).compareTo(_nCampos(_id(a))));
    final destino = orden.first;
    final otras = orden.skip(1).toList();
    final ok = await _confirmar(
      'Unir categorías repetidas',
      'Se dejará solo «${_nombre(destino)}» y se quitará '
          '${otras.map((e) => '«${_nombre(e)}»').join(', ')} de la lista. '
          'Sus campos pasan a «${_nombre(destino)}». Los préstamos y bienes '
          'ya registrados NO se tocan. ¿Continuar?',
    );
    if (!ok) return;
    await _hacer(() async {
      for (final o in otras) {
        await _unir(_id(o), _id(destino));
      }
      return 'Categorías unidas en «${_nombre(destino)}»';
    });
  }

  Future<void> _agruparFamilia(_Familia f) async {
    final nombrePadre = f.general != null
        ? _nombre(f.general!)
        : f.plantilla['nombre'].toString();
    final ok = await _confirmar(
      'Agrupar como subcategorías',
      '${f.hijos.map((e) => '«${_nombre(e)}»').join(', ')} pasarán a ser '
          'subcategorías de «$nombrePadre»'
          '${f.general == null ? ' (se crea)' : ''}. '
          'Heredarán los campos de «$nombrePadre» y podrá agregar los propios '
          'de cada una. Todo lo registrado antes sigue igual. ¿Continuar?',
    );
    if (!ok) return;
    await _hacer(() async {
      final padreId = f.general != null
          ? _id(f.general!)
          : await _crearCategoria(nombrePadre);
      for (final h in f.hijos) {
        await _ponerPadre(_id(h), padreId);
      }
      // los campos van en la categoría principal; los hijos los heredan
      if ((f.general == null) || _nCampos(padreId) == 0) {
        await _aplicarPlantilla(padreId, f.plantilla['clave'].toString());
      }
      return 'Listo: «$nombrePadre» agrupa ${f.hijos.length} subcategorías';
    });
  }

  Future<void> _elegirPadre(Map<String, dynamic> c) async {
    final candidatas = _cats
        .where((x) => _id(x) != _id(c) && _padre(x) == null)
        .toList()
      ..sort((a, b) => _nombre(a).compareTo(_nombre(b)));
    if (candidatas.isEmpty) {
      _aviso('No hay otra categoría principal disponible');
      return;
    }
    final id = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('«${_nombre(c)}» será subcategoría de…'),
        children: [
          for (final p in candidatas)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, _id(p)),
              child: Text(_nombre(p)),
            ),
        ],
      ),
    );
    if (id == null) return;
    await _hacer(() => _ponerPadre(_id(c), id));
  }

  Widget _filaCategoria(Map<String, dynamic> c, {bool hijo = false}) {
    final id = _id(c);
    final padre = _porId(_padre(c));
    final propios = _nCampos(id);
    final heredados = padre != null ? _nCampos(_id(padre)) : 0;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: hijo ? 40 : 16, right: 8),
      leading: Icon(hijo ? Icons.subdirectory_arrow_right : Icons.folder_outlined),
      title: Text(_nombre(c),
          style: TextStyle(fontWeight: hijo ? FontWeight.normal : FontWeight.w600)),
      subtitle: Text(
        propios == 0 && heredados == 0
            ? 'Sin campos extra'
            : '$propios campos propios'
                '${heredados > 0 ? ' + $heredados heredados' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'plantilla') {
            final sug = sugerirPlantillaCategoria(_nombre(c), _plantillas);
            final clave = await elegirPlantilla(context, _plantillas,
                sugerida: sug?['clave']?.toString());
            if (clave != null) await _hacer(() => _aplicarPlantilla(id, clave));
          } else if (v == 'padre') {
            await _elegirPadre(c);
          } else if (v == 'principal') {
            await _hacer(() => _ponerPadre(id, null));
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'plantilla', child: Text('Aplicar campos de un tipo de bien')),
          if (_padre(c) == null)
            const PopupMenuItem(value: 'padre', child: Text('Convertir en subcategoría de…')),
          if (_padre(c) != null)
            const PopupMenuItem(value: 'principal', child: Text('Volver a categoría principal')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repetidas = _cargando ? <List<Map<String, dynamic>>>[] : _repetidas();
    final familias = _cargando ? <_Familia>[] : _familias();
    final sinCampos = _cargando ? <_SinCampos>[] : _sinCampos();
    final sinPlantilla = _cargando
        ? <Map<String, dynamic>>[]
        : _cats
            .where((c) =>
                sugerirPlantillaCategoria(_nombre(c), _plantillas) == null &&
                _nCampos(_id(c)) == 0 &&
                (_porId(_padre(c)) == null || _nCampos(_id(_porId(_padre(c))!)) == 0))
            .toList();

    final raices = _cats.where((c) => _padre(c) == null || _porId(_padre(c)) == null).toList()
      ..sort((a, b) => _nombre(a).toLowerCase().compareTo(_nombre(b).toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordenar mis categorías'),
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
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.only(bottom: 40),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Tiene ${_cats.length} categorías. Revisé los nombres y '
                            'encontré lo siguiente. Nada cambia hasta que usted '
                            'confirme, y los préstamos ya registrados no se tocan.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (repetidas.isEmpty && familias.isEmpty && sinCampos.isEmpty)
                          _tarjeta(Colors.green, Icons.check_circle, 'Todo en orden',
                              'No encontré categorías repetidas ni sin campos. Abajo puede '
                                  'ajustar cualquiera a mano.'),
                        if (repetidas.isNotEmpty) _titulo('1. Categorías repetidas'),
                        for (final g in repetidas)
                          _tarjeta(
                            Colors.red,
                            Icons.copy_all,
                            g.map((e) => '«${_nombre(e)}»').join(' = '),
                            'Parecen la misma categoría escrita de distinta forma. '
                                'Conviene dejar una sola.',
                            acciones: [
                              ElevatedButton(
                                  onPressed: _trabajando ? null : () => _unirGrupo(g),
                                  child: const Text('Unir en una sola')),
                            ],
                          ),
                        if (familias.isNotEmpty) _titulo('2. Pueden ser subcategorías'),
                        for (final f in familias)
                          _tarjeta(
                            Colors.orange,
                            Icons.account_tree_outlined,
                            f.hijos.map((e) => _nombre(e)).join(', ') +
                                ' → ${f.general != null ? _nombre(f.general!) : f.plantilla['nombre']}',
                            'Son tipos de "${f.plantilla['nombre']}". Agrupándolos, '
                                'comparten los campos comunes (${(f.plantilla['campos'] as List).length}) '
                                'y cada uno puede tener los suyos.',
                            acciones: [
                              ElevatedButton(
                                  onPressed: _trabajando ? null : () => _agruparFamilia(f),
                                  child: const Text('Agrupar')),
                            ],
                          ),
                        if (sinCampos.isNotEmpty) ...[
                          _titulo('3. Les faltan sus campos'),
                          _tarjeta(
                            Colors.blue,
                            Icons.playlist_add_check,
                            'Poner los campos sugeridos a ${sinCampos.length} categorías',
                            sinCampos
                                .map((e) => '${_nombre(e.cat)} → ${e.plantilla['nombre']}')
                                .join('\n'),
                            acciones: [
                              ElevatedButton(
                                onPressed: _trabajando
                                    ? null
                                    : () async {
                                        final ok = await _confirmar(
                                            'Aplicar campos sugeridos',
                                            'Se agregarán los campos de cada tipo de bien. '
                                                'Todos quedan opcionales y puede cambiarlos '
                                                'cuando quiera.');
                                        if (!ok) return;
                                        await _hacer(() async {
                                          for (final s in sinCampos) {
                                            await _aplicarPlantilla(
                                                _id(s.cat), s.plantilla['clave'].toString());
                                          }
                                          return 'Campos agregados a ${sinCampos.length} categorías';
                                        });
                                      },
                                child: const Text('Aplicar todo lo sugerido'),
                              ),
                            ],
                          ),
                        ],
                        if (sinPlantilla.isNotEmpty) ...[
                          _titulo('Sin sugerencia'),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'No supe qué tipo de bien es: '
                              '${sinPlantilla.map(_nombre).join(', ')}. '
                              'Use el menú ⋮ de cada una (abajo) para elegir sus campos '
                              'o convertirla en subcategoría.',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        _titulo('Todas mis categorías'),
                        for (final r in raices) ...[
                          _filaCategoria(r),
                          for (final h in _cats.where((x) => _padre(x) == _id(r)))
                            _filaCategoria(h, hijo: true),
                        ],
                      ],
                    ),
                    if (_trabajando)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x55FFFFFF),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _Familia {
  _Familia({required this.plantilla, required this.general, required this.hijos});
  final Map<String, dynamic> plantilla;
  final Map<String, dynamic>? general;
  final List<Map<String, dynamic>> hijos;
}

class _SinCampos {
  _SinCampos(this.cat, this.plantilla);
  final Map<String, dynamic> cat;
  final Map<String, dynamic> plantilla;
}
