import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Módulo "Auditoría": quién hizo qué, cuándo y desde dónde.
// Usa las rutas /auditoria del servidor (solo lectura).
// ---------------------------------------------------------------------------

class _AccionInfo {
  const _AccionInfo(this.titulo, this.icono, this.color, this.explicacion);
  final String titulo;
  final IconData icono;
  final Color color;
  final String explicacion;
}

const Map<String, _AccionInfo> _acciones = <String, _AccionInfo>{
  'ELIMINAR': _AccionInfo('Eliminó', Icons.delete_forever, Colors.red,
      'Se borró un registro. Revise quién fue y si era correcto.'),
  'ANULAR': _AccionInfo('Anuló / canceló', Icons.cancel, Colors.red,
      'Se anuló o canceló algo (préstamo, venta, pago...).'),
  'LOGIN_FALLIDO': _AccionInfo('Acceso fallido', Icons.gpp_bad, Colors.red,
      'Alguien intentó entrar y no pudo: usuario o clave incorrectos. Si se repite, puede ser un intruso.'),
  'EDITAR': _AccionInfo('Modificó', Icons.edit, Colors.orange,
      'Se cambió información que ya existía.'),
  'RESTAURAR': _AccionInfo('Restauró', Icons.restore, Colors.orange,
      'Se recuperó información de un respaldo o se revirtió algo.'),
  'RESPALDO': _AccionInfo('Respaldo', Icons.backup, Colors.orange,
      'Se creó, restauró o borró un respaldo del sistema.'),
  'CREAR': _AccionInfo('Registró', Icons.add_circle, Colors.green,
      'Se agregó algo nuevo (cliente, préstamo, pago...).'),
  'LOGIN': _AccionInfo('Inició sesión', Icons.login, Colors.green,
      'Un usuario entró correctamente al sistema.'),
  'EXPEDIENTE': _AccionInfo('Expediente', Icons.fact_check, Colors.teal,
      'Acciones del expediente digital: generar, firmar, huella, finalizar.'),
  'BUSCAR': _AccionInfo('Búsqueda', Icons.search, Colors.blue,
      'Alguien buscó o consultó a un cliente, DNI u otro dato.'),
};

const Set<String> _alertas = <String>{'ELIMINAR', 'ANULAR', 'LOGIN_FALLIDO'};

_AccionInfo _info(String accion) =>
    _acciones[accion] ??
    _AccionInfo(accion, Icons.history, Colors.grey, 'Otra acción del sistema.');

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

String _dos(int n) => n.toString().padLeft(2, '0');

String _fechaHora(dynamic v) {
  final d = DateTime.tryParse(v?.toString() ?? '')?.toLocal();
  if (d == null) return '-';
  return '${_dos(d.day)}/${_dos(d.month)}/${d.year} ${_dos(d.hour)}:${_dos(d.minute)}';
}

String _hace(dynamic v) {
  final d = DateTime.tryParse(v?.toString() ?? '')?.toLocal();
  if (d == null) return '';
  final dif = DateTime.now().difference(d);
  if (dif.inMinutes < 1) return 'hace un momento';
  if (dif.inMinutes < 60) return 'hace ${dif.inMinutes} min';
  if (dif.inHours < 24) return 'hace ${dif.inHours} h';
  if (dif.inDays < 30) return 'hace ${dif.inDays} días';
  return '';
}

String _dispositivo(String? ua) {
  final u = (ua ?? '').toLowerCase();
  if (u.isEmpty) return 'No disponible';
  String so = '';
  if (u.contains('android')) {
    so = 'Android';
  } else if (u.contains('iphone') || u.contains('ipad')) {
    so = 'iPhone / iPad';
  } else if (u.contains('windows')) {
    so = 'Windows';
  } else if (u.contains('mac os')) {
    so = 'Mac';
  } else if (u.contains('linux')) {
    so = 'Linux';
  }
  String app = '';
  if (u.contains('dart')) {
    app = 'App de la empresa';
  } else if (u.contains('chrome')) {
    app = 'Navegador Chrome';
  } else if (u.contains('firefox')) {
    app = 'Navegador Firefox';
  } else if (u.contains('safari')) {
    app = 'Navegador Safari';
  }
  final partes = <String>[if (app.isNotEmpty) app, if (so.isNotEmpty) so];
  return partes.isEmpty ? ua! : partes.join(' · ');
}

class AuditoriaView extends StatefulWidget {
  const AuditoriaView({Key? key}) : super(key: key);

  @override
  State<AuditoriaView> createState() => _AuditoriaViewState();
}

class _AuditoriaViewState extends State<AuditoriaView> {
  static const int _pagina = 20;
  static const List<String> _periodos = ['Hoy', '7 días', '30 días', 'Todo'];

  final Dio _dio = _crearDio();
  final TextEditingController _buscar = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  int _periodo = 1; // 7 días por defecto
  int _usuarioId = 0;
  String _accion = '';
  String _modulo = '';
  bool _soloAlertas = false;
  bool _soloErrores = false;

  int _total = 0;
  bool _cargando = false;
  String? _error;
  Map<String, dynamic>? _resumen;
  List<Map<String, dynamic>> _usuarios = <Map<String, dynamic>>[];
  List<String> _modulos = <String>[];

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
    _cargarFiltros();
    _recargarTodo();
  }

  @override
  void dispose() {
    _buscar.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String? get _desde {
    final h = DateTime.now();
    final inicio = DateTime(h.year, h.month, h.day);
    switch (_periodo) {
      case 0:
        return inicio.toUtc().toIso8601String();
      case 1:
        return inicio.subtract(const Duration(days: 6)).toUtc().toIso8601String();
      case 2:
        return inicio.subtract(const Duration(days: 29)).toUtc().toIso8601String();
      default:
        return null;
    }
  }

  Map<String, dynamic> _parametros() => <String, dynamic>{
        if (_desde != null) 'desde': _desde,
        if (_usuarioId > 0) 'usuarioId': _usuarioId,
        if (_accion.isNotEmpty) 'accion': _accion,
        if (_modulo.isNotEmpty) 'modulo': _modulo,
        if (_soloAlertas) 'soloAlertas': true,
        if (_soloErrores) 'resultado': 'ERROR',
        if (_buscar.text.trim().isNotEmpty) 'q': _buscar.text.trim(),
      };

  Future<void> _cargarFiltros() async {
    try {
      final r = await _dio.get('/auditoria/filtros');
      final b = _cuerpo(r);
      if (b is Map) {
        _usuarios = <Map<String, dynamic>>[];
        if (b['usuarios'] is List) {
          for (final u in b['usuarios'] as List) {
            if (u is Map) _usuarios.add(Map<String, dynamic>.from(u));
          }
        }
        _modulos = (b['modulos'] is List)
            ? (b['modulos'] as List).map((e) => e.toString()).toList()
            : <String>[];
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _cargarResumen() async {
    try {
      final r = await _dio.get('/auditoria/resumen',
          queryParameters: {if (_desde != null) 'desde': _desde});
      final b = _cuerpo(r);
      if (b is Map && mounted) {
        setState(() => _resumen = Map<String, dynamic>.from(b));
      }
    } catch (_) {}
  }

  Future<void> _recargarTodo() async {
    _cargarResumen();
    await _cargar(reiniciar: true);
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
      final r = await _dio.get('/auditoria', queryParameters: {
        ..._parametros(),
        'limit': _pagina,
        'offset': _items.length,
      });
      final b = _cuerpo(r);
      if (b is Map) {
        if (b['items'] is List) {
          for (final x in b['items'] as List) {
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

  int _n(String accion) => (_resumen?['acciones'] is Map)
      ? ((_resumen!['acciones'] as Map)[accion] as num?)?.toInt() ?? 0
      : 0;

  Widget _tarjetaResumen(String titulo, int valor, Color color, IconData icono,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 118,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(height: 4),
            Text('$valor',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(titulo, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _aplicarAccion(String accion) {
    _accion = accion;
    _soloAlertas = false;
    _recargarTodo();
  }

  void _verLeyenda() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Qué significa cada tipo?'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Rojo = revisar con atención. Naranja = cambios. Verde = normal. Azul = consultas.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              for (final e in _acciones.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(e.value.icono, color: e.value.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.titulo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(e.value.explicacion,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const Text(
                'La ubicación se calcula por la dirección IP de la conexión: indica la red desde donde se hizo la acción, no el punto exacto.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _verDetalle(Map<String, dynamic> it) {
    final a = _info((it['accion'] ?? '').toString());
    final datos = it['datos'];
    final lineas = <MapEntry<String, String>>[];
    void agregar(String prefijo, dynamic m) {
      if (m is Map) {
        m.forEach((k, v) {
          if (v == null || (v is Map && v.isEmpty)) return;
          final texto = v is Map || v is List ? v.toString() : v.toString();
          lineas.add(MapEntry('$prefijo$k', texto.length > 160 ? '${texto.substring(0, 160)}…' : texto));
        });
      }
    }

    if (datos is Map) {
      agregar('', datos['query']);
      agregar('', datos['body']);
      if (datos['intento_con'] != null &&
          datos['intento_con'].toString().isNotEmpty) {
        lineas.add(MapEntry('Usuario que intentó entrar', datos['intento_con'].toString()));
      }
    }
    final cambios = <Map<String, dynamic>>[];
    if (datos is Map && datos['cambios'] is List) {
      for (final c in (datos['cambios'] as List)) {
        if (c is Map) cambios.add(Map<String, dynamic>.from(c));
      }
    }
    final fallo = (it['resultado'] ?? 'OK') == 'ERROR';
    final uid = (it['usuarioId'] as num?)?.toInt() ?? 0;
    final usuarioTxt = (it['usuario'] ?? '').toString();
    final quien = uid > 0 ? '$usuarioTxt  (usuario N° $uid)' : usuarioTxt;
    final estadoHttp = (it['estadoHttp'] ?? '').toString();
    final resultadoTxt = fallo
        ? 'No se completó (el sistema respondió con error $estadoHttp).'
        : 'Se completó correctamente.';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: a.color.withOpacity(0.15),
                  child: Icon(a.icono, color: a.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(a.titulo,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (fallo)
                  const Chip(
                    label: Text('FALLÓ', style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _bloque(
                '¿Qué pasó?',
                () {
                  final d = (it['descripcion'] ?? '').toString();
                  if (cambios.isEmpty) return d;
                  final i = d.indexOf('. ');
                  return i > 0 ? d.substring(0, i) : d;
                }()),
            _bloque('¿Quién lo hizo?', quien),
            _bloque('¿Cuándo?', '${_fechaHora(it['fecha'])}  ${_hace(it['fecha'])}'),
            _bloque('¿Desde dónde?',
                'IP: ${it['ip'] ?? 'No disponible'}\n${_dispositivo(it['dispositivo']?.toString())}'),
            _bloque('¿En qué parte?',
                '${it['modulo']}${it['entidadId'] != null ? ' · registro N° ${it['entidadId']}' : ''}'),
            _bloque('Resultado', resultadoTxt),
            if (datos is Map && datos['codigoPrestamo'] != null)
              _bloque('Préstamo modificado',
                  'N° ${datos['codigoPrestamo']}  ·  ${datos['cliente'] ?? ''}'),
            if (datos is Map &&
                datos['codigoPrestamo'] == null &&
                datos['tabla'] != null)
              _bloque('Registro afectado',
                  '${datos['tabla']} N° ${datos['registro'] ?? ''}'),
            if (cambios.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Text('Qué se cambió',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              for (final c in cambios)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD9E2EC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((c['campo'] ?? '').toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text.rich(TextSpan(children: [
                        const TextSpan(
                            text: 'Antes: ',
                            style: TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w600)),
                        TextSpan(text: (c['antes'] ?? '').toString()),
                      ])),
                      const SizedBox(height: 2),
                      Text.rich(TextSpan(children: [
                        const TextSpan(
                            text: 'Quedó: ',
                            style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600)),
                        TextSpan(text: (c['despues'] ?? '').toString()),
                      ])),
                    ],
                  ),
                ),
            ] else if (datos is Map && datos['codigoPrestamo'] != null)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Se guardó sin cambios en los datos.',
                    style: TextStyle(color: Colors.grey)),
              ),
            if (lineas.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Datos que se enviaron',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Text(
                  'Las claves y los contenidos muy largos (fotos, firmas) se ocultan por seguridad.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              for (final l in lineas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                        text: '${l.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: l.value),
                  ])),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bloque(String titulo, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(texto.isEmpty ? '-' : texto,
              style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> it) {
    final a = _info((it['accion'] ?? '').toString());
    final fallo = (it['resultado'] ?? 'OK') == 'ERROR';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: a.color.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => _verDetalle(it),
        leading: CircleAvatar(
          backgroundColor: a.color.withOpacity(0.15),
          child: Icon(a.icono, color: a.color),
        ),
        title: Text(
          '${it['usuario']}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((it['descripcion'] ?? '').toString(),
                maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${_fechaHora(it['fecha'])}  ${_hace(it['fecha'])}'
              '${it['ip'] != null ? '  ·  IP ${it['ip']}' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: fallo
            ? const Chip(
                label: Text('FALLÓ', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneFiltros = _usuarioId > 0 ||
        _accion.isNotEmpty ||
        _modulo.isNotEmpty ||
        _soloAlertas ||
        _soloErrores ||
        _buscar.text.trim().isNotEmpty;
    final cabecera = <Widget>[
        Container(
          width: double.infinity,
          color: Colors.blue.shade50,
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Aquí ve quién hizo qué, cuándo y desde dónde. Lo que se eliminó, anuló o los accesos fallidos aparecen en rojo.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: '¿Qué significa cada color?',
                icon: const Icon(Icons.help_outline),
                onPressed: _verLeyenda,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              for (var i = 0; i < _periodos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_periodos[i]),
                    selected: _periodo == i,
                    onSelected: (_) {
                      _periodo = i;
                      _recargarTodo();
                    },
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            children: [
              _tarjetaResumen('Movimientos', (_resumen?['total'] as num?)?.toInt() ?? 0,
                  Colors.blue, Icons.history, () => _aplicarAccion('')),
              _tarjetaResumen('Eliminaciones', _n('ELIMINAR'), Colors.red,
                  Icons.delete_forever, () => _aplicarAccion('ELIMINAR')),
              _tarjetaResumen('Anulaciones', _n('ANULAR'), Colors.red,
                  Icons.cancel, () => _aplicarAccion('ANULAR')),
              _tarjetaResumen('Accesos fallidos', _n('LOGIN_FALLIDO'),
                  Colors.red, Icons.gpp_bad, () => _aplicarAccion('LOGIN_FALLIDO')),
              _tarjetaResumen('Con error', (_resumen?['errores'] as num?)?.toInt() ?? 0,
                  Colors.orange, Icons.error_outline, () {
                _soloErrores = !_soloErrores;
                _recargarTodo();
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
          child: TextField(
            controller: _buscar,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _recargarTodo(),
            decoration: InputDecoration(
              hintText: 'Buscar: persona, DNI, IP, "eliminó"...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _buscar.clear();
                  _recargarTodo();
                },
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        ExpansionTile(
          title: Text(tieneFiltros ? 'Filtros (activos)' : 'Filtros'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: _usuarios.any((u) => u['id'] == _usuarioId) ? _usuarioId : 0,
                    decoration: const InputDecoration(
                        labelText: 'Usuario', isDense: true, border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<int>(value: 0, child: Text('Todos los usuarios')),
                      for (final u in _usuarios)
                        DropdownMenuItem<int>(
                          value: (u['id'] as num).toInt(),
                          child: Text(u['nombre'].toString()),
                        ),
                    ],
                    onChanged: (v) {
                      _usuarioId = v ?? 0;
                      _recargarTodo();
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _accion,
                    decoration: const InputDecoration(
                        labelText: 'Qué hizo', isDense: true, border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('Todo')),
                      for (final e in _acciones.entries)
                        DropdownMenuItem<String>(value: e.key, child: Text(e.value.titulo)),
                    ],
                    onChanged: (v) {
                      _accion = v ?? '';
                      _recargarTodo();
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _modulos.contains(_modulo) ? _modulo : '',
                    decoration: const InputDecoration(
                        labelText: 'Dónde (módulo)', isDense: true, border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('Todos')),
                      for (final m in _modulos)
                        DropdownMenuItem<String>(value: m, child: Text(m)),
                    ],
                    onChanged: (v) {
                      _modulo = v ?? '';
                      _recargarTodo();
                    },
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Solo alertas (eliminar, anular, accesos fallidos)'),
                    value: _soloAlertas,
                    onChanged: (v) {
                      _soloAlertas = v;
                      if (v) _accion = '';
                      _recargarTodo();
                    },
                  ),
                  if (tieneFiltros)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          _usuarioId = 0;
                          _accion = '';
                          _modulo = '';
                          _soloAlertas = false;
                          _soloErrores = false;
                          _buscar.clear();
                          _recargarTodo();
                        },
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Quitar filtros'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('$_total movimientos (lo más reciente primero)',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
    ];
    return RefreshIndicator(
      onRefresh: _recargarTodo,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: cabecera.length + _items.length + 1,
        itemBuilder: (context, i) {
          if (i < cabecera.length) return cabecera[i];
          final k = i - cabecera.length;
          if (k < _items.length) return _tarjeta(_items[k]);
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
              child: Text(
                  'No hay movimientos con estos filtros.\nLos movimientos nuevos aparecerán aquí automáticamente.',
                  textAlign: TextAlign.center),
            );
          }
          return const SizedBox(height: 20);
        },
      ),
    );
  }
}
