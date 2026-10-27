import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/categorias_orden_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ---------------------------------------------------------------------------
// Módulo "Administración": roles y módulos, usuarios, campos por categoría
// y configuración del sistema. Usa rutas que ya existen en el servidor.
// ---------------------------------------------------------------------------

Dio _crearDio() => Dio(
      BaseOptions(
        baseUrl: endPointPrincipal,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );

// Cliente de red que además identifica a la persona que usa la pantalla
Dio _dioUsuario(BuildContext c) {
  final dio = _crearDio();
  final u = c.read<Preferences>().token;
  if (u != null) {
    dio.options.headers['x-usuario-id'] = u.id.toString();
    dio.options.headers['x-usuario-nombre'] =
        Uri.encodeComponent('${u.nombre ?? ''} ${u.apellido ?? ''}'.trim());
  }
  return dio;
}

String _msg(Object e) {
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

void _aviso(BuildContext c, String t) {
  if (!c.mounted) return;
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(t)));
}

Future<bool> _confirmar(BuildContext c, String titulo, String texto) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aceptar')),
      ],
    ),
  );
  return r == true;
}

// Convierte las respuestas del servidor en una lista de mapas.
// Acepta [filas, total], [filas] o una lista directa.
List<Map<String, dynamic>> _filas(dynamic b) {
  dynamic lista = b;
  if (b is List && b.isNotEmpty && b.first is List) lista = b.first;
  final out = <Map<String, dynamic>>[];
  if (lista is List) {
    for (final x in lista) {
      if (x is Map) out.add(Map<String, dynamic>.from(x));
    }
  }
  return out;
}

dynamic _cuerpo(Response<dynamic> r) {
  final d = r.data;
  return d is Map ? d['body'] : d;
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto, {Key? key}) : super(key: key);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(12),
      child: Text(texto, style: const TextStyle(fontSize: 13)),
    );
  }
}

// ===========================================================================
// Pantalla principal con pestañas
// ===========================================================================

class AdministracionView extends StatelessWidget {
  const AdministracionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 9,
      child: Column(
        children: [
          Container(
            color: Colors.blueGrey.shade50,
            child: const TabBar(
              isScrollable: true,
              labelColor: Colors.black87,
              tabs: [
                Tab(icon: Icon(Icons.home), text: 'Inicio'),
                Tab(icon: Icon(Icons.people), text: 'Usuarios'),
                Tab(icon: Icon(Icons.store), text: 'Sucursales'),
                Tab(icon: Icon(Icons.admin_panel_settings), text: 'Puestos y módulos'),
                Tab(icon: Icon(Icons.shield), text: 'Permisos'),
                Tab(icon: Icon(Icons.how_to_reg), text: 'Solicitudes'),
                Tab(icon: Icon(Icons.playlist_add_check), text: 'Campos'),
                Tab(icon: Icon(Icons.category), text: 'Catálogos'),
                Tab(icon: Icon(Icons.tune), text: 'Sistema'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _InicioTab(),
                _UsuariosTab(),
                _SucursalesTab(),
                _RolesTab(),
                _PermisosTab(),
                _SolicitudesTab(),
                _CamposTab(),
                _CatalogosTab(),
                _SistemaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 0) Inicio: guía paso a paso
// ===========================================================================

class _InicioTab extends StatefulWidget {
  const _InicioTab({Key? key}) : super(key: key);

  @override
  State<_InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<_InicioTab> {
  late final Dio _dio = _dioUsuario(context);
  bool _activo = false;
  int _pendientes = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await _dio.get('/acceso/estado');
      final b = _cuerpo(r);
      if (b is Map && mounted) {
        setState(() {
          _activo = b['activo'] == true;
          _pendientes = (b['pendientes'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  Widget _opcion(IconData icono, Color color, String titulo, String texto,
      int pestana, {String? insignia}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        onTap: () {
          DefaultTabController.of(context).animateTo(pestana);
        },
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icono, color: color),
        ),
        title: Row(
          children: [
            Flexible(
                child: Text(titulo,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            if (insignia != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(10)),
                child: Text(insignia,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
          ],
        ),
        subtitle: Text(texto),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _activo ? Colors.green.shade50 : Colors.orange.shade50,
              border: Border.all(
                  color: _activo ? Colors.green : Colors.orange, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(_activo ? Icons.lock : Icons.lock_open,
                    color: _activo ? Colors.green : Colors.orange, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _activo
                        ? 'Las restricciones están ACTIVAS. Cada puesto solo puede hacer lo que usted permitió.'
                        : 'Las restricciones están APAGADAS: nadie está bloqueado todavía. Puede configurarlas con calma y activarlas al final.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('¿Qué desea hacer?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _opcion(Icons.how_to_reg, Colors.red, 'Aprobar solicitudes',
              'Personas que pidieron permiso para una acción bloqueada.', 5,
              insignia: _pendientes > 0 ? '$_pendientes' : null),
          _opcion(Icons.people, Colors.teal, 'Usuarios',
              'Cree, edite o elimine a las personas que usan el sistema.', 1),
          _opcion(Icons.store, Colors.green, 'Sucursales',
              'Agregue y edite los locales de su negocio.', 2),
          _opcion(Icons.shield, Colors.indigo, 'Controlar qué puede hacer cada puesto',
              'Ordene los puestos por autoridad y bloquee crear, editar, eliminar o anular.', 4),
          _opcion(Icons.admin_panel_settings, Colors.blueGrey, 'Elegir qué ve cada puesto en el menú',
              'Cree puestos y marque los módulos que pueden abrir.', 3),
          _opcion(Icons.playlist_add_check, Colors.orange, 'Campos extra por categoría',
              'Por ejemplo, "Placa" solo para Vehículos.', 6),
          _opcion(Icons.category, Colors.purple, 'Catálogos',
              'Categorías de productos, tipos de movimiento e intereses.', 7),
          _opcion(Icons.tune, Colors.brown, 'Configuración del sistema',
              'Mora, tasas de interés, descuentos y rangos.', 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: ListTile(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const _RecuperarObservacionesPage())),
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.15),
                child: const Icon(Icons.restore, color: Colors.red),
              ),
              title: const Text('Recuperar observaciones perdidas',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Devuelve las contraseñas y datos extra de las prendas desde el historial.'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Consejo: configure primero los puestos y permisos, pruebe con un usuario de prueba y solo después active las restricciones.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 1) Roles y módulos
// ===========================================================================

class _RolesTab extends StatefulWidget {
  const _RolesTab({Key? key}) : super(key: key);

  @override
  State<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<_RolesTab> {
  late final Dio _dio = _dioUsuario(context);
  List<Map<String, dynamic>> _roles = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _modulos = <Map<String, dynamic>>[];
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
      final rr = await _dio.get('/auth/roles', queryParameters: {'limit': 200, 'offset': 0});
      final rm = await _dio.get('/modulos', queryParameters: {'limit': 300, 'offset': 0});
      _roles = _filas(_cuerpo(rr));
      _modulos = _filas(_cuerpo(rm));
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _ejecutar(Future<void> Function() fn, String ok) async {
    try {
      await fn();
      _aviso(context, ok);
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  Future<void> _editarRol({Map<String, dynamic>? rol}) async {
    final sel = <int>{};
    if (rol != null && rol['modulos'] is List) {
      for (final m in rol['modulos'] as List) {
        if (m is Map && m['id'] is num) sel.add((m['id'] as num).toInt());
      }
    }
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RolDialog(
        titulo: rol == null ? 'Nuevo rol' : 'Editar rol',
        modulos: _modulos,
        nombre: (rol?['nombre'] ?? '').toString(),
        seleccion: sel,
      ),
    );
    if (r == null) return;
    await _ejecutar(() async {
      if (rol == null) {
        await _dio.post('/auth/roles', data: r);
      } else {
        await _dio.put('/auth/roles/${rol['id']}', data: r);
      }
    }, rol == null ? 'Rol creado' : 'Rol actualizado');
  }

  Future<void> _borrarRol(Map<String, dynamic> rol) async {
    final ok = await _confirmar(context, 'Eliminar rol',
        'Se eliminará el rol "${rol['nombre']}". Los usuarios con este rol podrían quedar sin acceso. ¿Continuar?');
    if (!ok) return;
    await _ejecutar(() async {
      await _dio.delete('/auth/roles/${rol['id']}');
    }, 'Rol eliminado');
  }

  Future<void> _editarModulo({Map<String, dynamic>? modulo}) async {
    final c = TextEditingController(text: (modulo?['nombre'] ?? '').toString());
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(modulo == null ? 'Nuevo módulo' : 'Renombrar módulo'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre del módulo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    c.dispose();
    if (nombre == null || nombre.isEmpty) return;
    await _ejecutar(() async {
      if (modulo == null) {
        await _dio.post('/modulos', data: {'nombre': nombre});
      } else {
        await _dio.put('/modulos/${modulo['id']}', data: {'nombre': nombre});
      }
    }, 'Módulo guardado');
  }

  Future<void> _crearBasicos() async {
    final ok = await _confirmar(context, 'Crear puestos básicos',
        'Se crearán los puestos que falten entre: Administrador, Gerente y Encargado de tienda. '
        'Los que ya existan no se tocan. Después podrá cambiar los módulos de cada uno. ¿Continuar?');
    if (!ok) return;
    try {
      final r = await _dio.post('/auth/roles/basicos');
      final b = _cuerpo(r);
      final creados = b is Map && b['creados'] is List ? (b['creados'] as List) : const [];
      final yaEstaban = b is Map && b['yaExistian'] is List ? (b['yaExistian'] as List) : const [];
      _aviso(
          context,
          creados.isEmpty
              ? 'Ya existían los tres puestos'
              : 'Creados: ${creados.join(', ')}'
                  '${yaEstaban.isEmpty ? '' : ' · Ya existían: ${yaEstaban.join(', ')}'}');
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  Future<void> _borrarModulo(Map<String, dynamic> m) async {
    final ok = await _confirmar(context, 'Eliminar módulo',
        'Se quitará el módulo "${m['nombre']}" de la lista. Los roles que lo tenían dejarán de verlo. ¿Continuar?');
    if (!ok) return;
    await _ejecutar(() async {
      await _dio.delete('/modulos/${m['id']}');
    }, 'Módulo eliminado');
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const _Aviso(
              'Un rol es un puesto (administrador, cajero...). Los módulos que marque en cada rol son los que sus usuarios ven en el menú. '
              'Un módulo nuevo solo agrega la opción al menú: la pantalla debe existir en la app.'),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                const Expanded(
                    child: Text('Roles',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                OutlinedButton.icon(
                  onPressed: _crearBasicos,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Puestos básicos'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _editarRol(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo rol'),
                ),
              ],
            ),
          ),
          for (final r in _roles)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Text((r['nombre'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final m in (r['modulos'] is List ? r['modulos'] as List : []))
                        if (m is Map)
                          Chip(
                            label: Text((m['nombre'] ?? '').toString(),
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ),
                      if (!(r['modulos'] is List) || (r['modulos'] as List).isEmpty)
                        const Text('Sin módulos asignados',
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => v == 'e' ? _editarRol(rol: r) : _borrarRol(r),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'e', child: Text('Editar')),
                    PopupMenuItem(value: 'b', child: Text('Eliminar')),
                  ],
                ),
                onTap: () => _editarRol(rol: r),
              ),
            ),
          const Divider(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                const Expanded(
                    child: Text('Módulos del sistema',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                OutlinedButton.icon(
                  onPressed: () => _editarModulo(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
          ),
          for (final m in _modulos)
            ListTile(
              dense: true,
              leading: const Icon(Icons.apps),
              title: Text((m['nombre'] ?? '').toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editarModulo(modulo: m)),
                  IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _borrarModulo(m)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RolDialog extends StatefulWidget {
  const _RolDialog({
    Key? key,
    required this.titulo,
    required this.modulos,
    required this.nombre,
    required this.seleccion,
  }) : super(key: key);

  final String titulo;
  final List<Map<String, dynamic>> modulos;
  final String nombre;
  final Set<int> seleccion;

  @override
  State<_RolDialog> createState() => _RolDialogState();
}

class _RolDialogState extends State<_RolDialog> {
  late final TextEditingController _nombre =
      TextEditingController(text: widget.nombre);
  late final Set<int> _sel = Set<int>.from(widget.seleccion);

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre del rol'),
              ),
              const SizedBox(height: 12),
              const Text('Módulos que puede ver este rol:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              for (final m in widget.modulos)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text((m['nombre'] ?? '').toString()),
                  value: _sel.contains((m['id'] as num).toInt()),
                  onChanged: (v) => setState(() {
                    final id = (m['id'] as num).toInt();
                    if (v == true) {
                      _sel.add(id);
                    } else {
                      _sel.remove(id);
                    }
                  }),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_nombre.text.trim().isEmpty) return;
            Navigator.pop(context, <String, dynamic>{
              'nombre': _nombre.text.trim(),
              'modulosId': _sel.toList(),
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ===========================================================================
// 2) Usuarios: rol y administrador
// ===========================================================================

class _UsuariosTab extends StatefulWidget {
  const _UsuariosTab({Key? key}) : super(key: key);

  @override
  State<_UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<_UsuariosTab> {
  late final Dio _dio = _dioUsuario(context);
  final TextEditingController _buscar = TextEditingController();
  List<Map<String, dynamic>> _usuarios = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _roles = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _sucursales = <Map<String, dynamic>>[];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ru = await _dio.get('/usuarios/', queryParameters: {'limit': 300, 'offset': 0});
      final rr = await _dio.get('/auth/roles', queryParameters: {'limit': 200, 'offset': 0});
      _usuarios = _filas(_cuerpo(ru));
      _roles = _filas(_cuerpo(rr));
      try {
        final rs = await _dio.get('/sucursal');
        _sucursales = _filas(_cuerpo(rs));
      } catch (_) {}
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _formulario({Map<String, dynamic>? u}) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _UsuarioDialog(usuario: u, roles: _roles, sucursales: _sucursales),
    );
    if (r == null) return;
    try {
      if (u == null) {
        await _dio.post('/usuarios', data: r);
      } else {
        await _dio.put('/usuarios/${u['id']}', data: r);
      }
      _aviso(context, u == null ? 'Usuario creado' : 'Usuario actualizado');
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  bool get _puedeRestablecer {
    final yo = context.read<Preferences>().token;
    if (yo == null) return false;
    if (yo.isAdmin == true) return true;
    final rol = (yo.role?.nombre ?? '')
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
    return rol == 'administrador' ||
        rol == 'administradora' ||
        rol == 'admin' ||
        rol == 'gerente' ||
        rol == 'gerenta';
  }

  Future<void> _restablecerClave(Map<String, dynamic> u) async {
    final nombre = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
    final ok = await _confirmar(context, 'Restablecer contraseña',
        'Las contraseñas están cifradas y nadie puede verlas. Lo que sí se puede es crear una '
        'contraseña NUEVA para "$nombre". La actual dejará de servir. ¿Continuar?');
    if (!ok) return;
    try {
      final r = await _dio.post('/usuarios/${u['id']}/restablecer-clave');
      final b = _cuerpo(r);
      final clave = b is Map ? (b['clave'] ?? '').toString() : '';
      final usuario = b is Map ? (b['userName'] ?? '').toString() : '';
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Contraseña nueva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Para $nombre${usuario.isEmpty ? '' : ' (usuario: $usuario)'}'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: SelectableText(
                  clave,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Anótela o cópiela ahora: solo se muestra esta vez. '
                'Pídale a la persona que la cambie cuando ingrese.',
                style: TextStyle(fontSize: 12.5),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: clave));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Contraseña copiada')));
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar'),
            ),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Listo')),
          ],
        ),
      );
    } catch (e) {
      _aviso(context, _msg(e));
    }
  }

  Future<void> _borrar(Map<String, dynamic> u) async {
    final ok = await _confirmar(context, 'Eliminar usuario',
        'Se eliminará a "${u['nombre']} ${u['apellido']}". Si tiene movimientos registrados, el sistema puede no permitirlo. ¿Continuar?');
    if (!ok) return;
    try {
      await _dio.delete('/usuarios/${u['id']}');
      _aviso(context, 'Usuario eliminado');
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    final t = _buscar.text.trim().toLowerCase();
    final lista = _usuarios.where((u) {
      if (t.isEmpty) return true;
      final s = '${u['nombre'] ?? ''} ${u['apellido'] ?? ''} ${u['userName'] ?? ''} ${u['email'] ?? ''}'.toLowerCase();
      return s.contains(t);
    }).toList();
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const _Aviso(
              'Aquí crea, edita y elimina a las personas que usan el sistema. Cada una tiene un puesto (rol) y una sucursal. '
              'Marque "administrador" solo a personas de total confianza.'),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscar,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar usuario',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _formulario(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
          ),
          for (final u in lista)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                onTap: () => _formulario(u: u),
                leading: CircleAvatar(
                  child: Text(((u['nombre'] ?? '?').toString().isEmpty
                          ? '?'
                          : (u['nombre'] ?? '?').toString()[0])
                      .toUpperCase()),
                ),
                title: Text('${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim()),
                subtitle: Text(
                    '${u['userName'] != null ? '@${u['userName']}  ·  ' : ''}'
                    'Rol: ${u['role'] is Map ? u['role']['nombre'] : 'Sin rol'}\n'
                    'Sucursal: ${u['sucursal'] is Map ? u['sucursal']['nombre'] : 'Sin sucursal'}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (u['isAdmin'] == true)
                      const Chip(
                          label: Text('ADMIN', style: TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'e') {
                          _formulario(u: u);
                        } else if (v == 'k') {
                          _restablecerClave(u);
                        } else {
                          _borrar(u);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'e', child: Text('Editar')),
                        if (_puedeRestablecer)
                          const PopupMenuItem(
                              value: 'k', child: Text('Restablecer contraseña')),
                        const PopupMenuItem(value: 'b', child: Text('Eliminar')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (lista.isEmpty)
            const Padding(
                padding: EdgeInsets.all(30),
                child: Text('No hay usuarios.', textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _UsuarioDialog extends StatefulWidget {
  const _UsuarioDialog({
    Key? key,
    this.usuario,
    required this.roles,
    required this.sucursales,
  }) : super(key: key);

  final Map<String, dynamic>? usuario;
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> sucursales;

  @override
  State<_UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<_UsuarioDialog> {
  late final TextEditingController _nombre =
      TextEditingController(text: (widget.usuario?['nombre'] ?? '').toString());
  late final TextEditingController _apellido =
      TextEditingController(text: (widget.usuario?['apellido'] ?? '').toString());
  late final TextEditingController _email =
      TextEditingController(text: (widget.usuario?['email'] ?? '').toString());
  late final TextEditingController _userName =
      TextEditingController(text: (widget.usuario?['userName'] ?? '').toString());
  late final TextEditingController _celular =
      TextEditingController(text: (widget.usuario?['celular'] ?? '').toString());
  final TextEditingController _password = TextEditingController();
  late int _rolId = (widget.usuario?['role'] is Map
          ? (widget.usuario!['role']['id'] as num?)?.toInt()
          : null) ??
      0;
  late int _sucursalId = (widget.usuario?['sucursal'] is Map
          ? (widget.usuario!['sucursal']['id'] as num?)?.toInt()
          : null) ??
      0;
  late bool _admin = widget.usuario?['isAdmin'] == true;
  bool _ver = false;
  String? _error;

  bool get _nuevo => widget.usuario == null;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _email.dispose();
    _userName.dispose();
    _celular.dispose();
    _password.dispose();
    super.dispose();
  }

  void _guardar() {
    String? falta;
    if (_nombre.text.trim().isEmpty) {
      falta = 'Escriba el nombre';
    } else if (_apellido.text.trim().isEmpty) {
      falta = 'Escriba el apellido';
    } else if (!_email.text.contains('@')) {
      falta = 'Escriba un correo válido';
    } else if (_userName.text.trim().isEmpty) {
      falta = 'Escriba el nombre de usuario para ingresar';
    } else if (_nuevo && _password.text.length < 4) {
      falta = 'La contraseña debe tener al menos 4 caracteres';
    } else if (_rolId == 0) {
      falta = 'Elija el rol (puesto)';
    } else if (_sucursalId == 0) {
      falta = 'Elija la sucursal';
    } else if (_nuevo && int.tryParse(_celular.text.trim()) == null) {
      falta = 'Escriba el celular (solo números)';
    }
    if (falta != null) {
      setState(() => _error = falta);
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'nombre': _nombre.text.trim(),
      'apellido': _apellido.text.trim(),
      'email': _email.text.trim(),
      'userName': _userName.text.trim(),
      if (_password.text.isNotEmpty) 'password': _password.text,
      'rolId': _rolId,
      'sucursalId': _sucursalId,
      if (int.tryParse(_celular.text.trim()) != null)
        'celular': int.parse(_celular.text.trim()),
      'isAdmin': _admin,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_nuevo ? 'Nuevo usuario' : 'Editar usuario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
                controller: _apellido,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Apellido')),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo')),
            TextField(
                controller: _userName,
                decoration: const InputDecoration(
                    labelText: 'Usuario para ingresar')),
            TextField(
              controller: _password,
              obscureText: !_ver,
              decoration: InputDecoration(
                labelText: _nuevo ? 'Contraseña' : 'Contraseña (vacía = no cambiarla)',
                suffixIcon: IconButton(
                  icon: Icon(_ver ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _ver = !_ver),
                ),
              ),
            ),
            TextField(
                controller: _celular,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Celular')),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: widget.roles.any((r) => (r['id'] as num).toInt() == _rolId)
                  ? _rolId
                  : null,
              decoration: const InputDecoration(labelText: 'Rol (puesto)'),
              items: [
                for (final r in widget.roles)
                  DropdownMenuItem<int>(
                    value: (r['id'] as num).toInt(),
                    child: Text((r['nombre'] ?? '').toString()),
                  ),
              ],
              onChanged: (v) => setState(() => _rolId = v ?? 0),
            ),
            DropdownButtonFormField<int>(
              value: widget.sucursales.any((r) => (r['id'] as num).toInt() == _sucursalId)
                  ? _sucursalId
                  : null,
              decoration: const InputDecoration(labelText: 'Sucursal'),
              items: [
                for (final r in widget.sucursales)
                  DropdownMenuItem<int>(
                    value: (r['id'] as num).toInt(),
                    child: Text((r['nombre'] ?? '').toString()),
                  ),
              ],
              onChanged: (v) => setState(() => _sucursalId = v ?? 0),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Es administrador'),
              subtitle: const Text('Acceso total de administración'),
              value: _admin,
              onChanged: (v) => setState(() => _admin = v),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

// ===========================================================================
// Catálogos genéricos: sucursales, categorías, tipos de movimiento, intereses
// ===========================================================================

class _CampoCat {
  const _CampoCat(this.clave, this.etiqueta,
      {this.numero = false, this.obligatorio = true});
  final String clave;
  final String etiqueta;
  final bool numero;
  final bool obligatorio;
}

class _CatalogoView extends StatefulWidget {
  const _CatalogoView({
    Key? key,
    required this.ruta,
    required this.singular,
    required this.campos,
    required this.titulo,
    this.subtitulo,
    this.ayuda,
    this.extras,
  }) : super(key: key);

  final String ruta;
  final String singular;
  final List<_CampoCat> campos;
  final String Function(Map<String, dynamic>) titulo;
  final String Function(Map<String, dynamic>)? subtitulo;
  final String? ayuda;
  final Map<String, dynamic> Function()? extras;

  @override
  State<_CatalogoView> createState() => _CatalogoViewState();
}

class _CatalogoViewState extends State<_CatalogoView> {
  late final Dio _dio = _dioUsuario(context);
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
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
      final r = await _dio.get(widget.ruta);
      _items = _filas(_cuerpo(r));
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _formulario({Map<String, dynamic>? item}) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CatalogoDialog(
          singular: widget.singular, campos: widget.campos, item: item),
    );
    if (r == null) return;
    try {
      if (item == null) {
        await _dio.post(widget.ruta, data: {...r, ...?widget.extras?.call()});
      } else {
        await _dio.put('${widget.ruta}/${item['id']}', data: r);
      }
      _aviso(context, 'Guardado');
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  Future<void> _borrar(Map<String, dynamic> item) async {
    final ok = await _confirmar(context, 'Eliminar ${widget.singular}',
        'Se eliminará "${widget.titulo(item)}". Si ya se usa en otros registros, el sistema puede no permitirlo. ¿Continuar?');
    if (!ok) return;
    try {
      await _dio.delete('${widget.ruta}/${item['id']}');
      _aviso(context, 'Eliminado');
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          if (widget.ayuda != null) _Aviso(widget.ayuda!),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _formulario(),
                icon: const Icon(Icons.add),
                label: Text('Agregar ${widget.singular}'),
              ),
            ),
          ),
          for (final it in _items)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                onTap: () => _formulario(item: it),
                title: Text(widget.titulo(it),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: widget.subtitulo == null
                    ? null
                    : Text(widget.subtitulo!(it)),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => v == 'e' ? _formulario(item: it) : _borrar(it),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'e', child: Text('Editar')),
                    PopupMenuItem(value: 'b', child: Text('Eliminar')),
                  ],
                ),
              ),
            ),
          if (_items.isEmpty)
            Padding(
                padding: const EdgeInsets.all(30),
                child: Text('Todavía no hay registros de ${widget.singular}.',
                    textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _CatalogoDialog extends StatefulWidget {
  const _CatalogoDialog({
    Key? key,
    required this.singular,
    required this.campos,
    this.item,
  }) : super(key: key);

  final String singular;
  final List<_CampoCat> campos;
  final Map<String, dynamic>? item;

  @override
  State<_CatalogoDialog> createState() => _CatalogoDialogState();
}

class _CatalogoDialogState extends State<_CatalogoDialog> {
  late final List<TextEditingController> _c = [
    for (final f in widget.campos)
      TextEditingController(text: (widget.item?[f.clave] ?? '').toString()),
  ];
  String? _error;

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    final datos = <String, dynamic>{};
    for (var i = 0; i < widget.campos.length; i++) {
      final f = widget.campos[i];
      final t = _c[i].text.trim();
      if (f.obligatorio && t.isEmpty) {
        setState(() => _error = 'Complete: ${f.etiqueta}');
        return;
      }
      if (f.numero) {
        final n = num.tryParse(t.replaceAll(',', '.'));
        if (n == null) {
          setState(() => _error = '${f.etiqueta} debe ser un número');
          return;
        }
        datos[f.clave] = n;
      } else {
        datos[f.clave] = t;
      }
    }
    Navigator.pop(context, datos);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null
          ? 'Nuevo ${widget.singular}'
          : 'Editar ${widget.singular}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.campos.length; i++)
              TextField(
                controller: _c[i],
                keyboardType:
                    widget.campos[i].numero ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                    labelText:
                        '${widget.campos[i].etiqueta}${widget.campos[i].obligatorio ? '' : ' (opcional)'}'),
              ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

class _SucursalesTab extends StatelessWidget {
  const _SucursalesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _CatalogoView(
      ruta: '/sucursal',
      singular: 'sucursal',
      ayuda:
          'Las sucursales son los locales de su negocio. Cada usuario y cada caja pertenece a una sucursal.',
      campos: const [
        _CampoCat('nombre', 'Nombre'),
        _CampoCat('direccion', 'Dirección'),
        _CampoCat('telefono', 'Teléfono'),
        _CampoCat('extas', 'Información adicional', obligatorio: false),
      ],
      titulo: (m) => (m['nombre'] ?? '').toString(),
      subtitulo: (m) =>
          '${m['direccion'] ?? ''}${(m['telefono'] ?? '').toString().isNotEmpty ? '  ·  Tel. ${m['telefono']}' : ''}',
    );
  }
}

class _CatalogosTab extends StatefulWidget {
  const _CatalogosTab({Key? key}) : super(key: key);

  @override
  State<_CatalogosTab> createState() => _CatalogosTabState();
}

class _CatalogosTabState extends State<_CatalogosTab> {
  int _sel = 0;
  static const List<String> _nombres = [
    'Categorías de productos',
    'Tipos de movimiento',
    'Intereses (%)',
  ];

  Widget _contenido() {
    switch (_sel) {
      case 1:
        return _CatalogoView(
          key: const ValueKey('tipos'),
          ruta: '/finanza/tipo-movimiento',
          singular: 'tipo de movimiento',
          ayuda:
              'Los tipos de movimiento clasifican las entradas y salidas de dinero de la caja (gastos, ingresos, etc.).',
          campos: const [
            _CampoCat('codigo', 'Código'),
            _CampoCat('descripcion', 'Descripción'),
          ],
          titulo: (m) => (m['descripcion'] ?? '').toString(),
          subtitulo: (m) => 'Código: ${m['codigo'] ?? ''}',
          extras: () => {
            'usuarioId': context.read<Preferences>().token?.id ?? 0,
          },
        );
      case 2:
        return _CatalogoView(
          key: const ValueKey('intereses'),
          ruta: '/configuraciones/intereses',
          singular: 'interés',
          ayuda:
              'Los porcentajes de interés que se pueden elegir al crear un préstamo.',
          campos: const [_CampoCat('interes', 'Interés (%)', numero: true)],
          titulo: (m) => '${m['interes'] ?? ''} %',
        );
      default:
        return _CatalogoView(
          key: const ValueKey('categorias'),
          ruta: '/almacen/producto/categoria',
          singular: 'categoría',
          ayuda:
              'Las categorías agrupan los bienes que recibe (celulares, vehículos, artefactos...). Los campos extra de cada categoría se crean en la pestaña "Campos".',
          campos: const [_CampoCat('descripcion', 'Nombre de la categoría')],
          titulo: (m) => (m['descripcion'] ?? '').toString(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (var i = 0; i < _nombres.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_nombres[i]),
                    selected: _sel == i,
                    onSelected: (_) => setState(() => _sel = i),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _contenido()),
      ],
    );
  }
}

// ===========================================================================
// 3) Campos por categoría (campos dinámicos)
// ===========================================================================

const Map<String, String> _tipos = <String, String>{
  'text': 'Texto',
  'number': 'Número',
  'date': 'Fecha',
  'select': 'Lista de opciones',
  'multi-select': 'Selección múltiple',
  'textarea': 'Texto largo',
  'checkbox': 'Sí / No',
  'photo': 'Foto',
  'file': 'Documento (foto)',
};

String _slug(String t) {
  const de = 'áéíóúüñÁÉÍÓÚÜÑ';
  const a = 'aeiouunAEIOUUN';
  var s = t.trim();
  for (var i = 0; i < de.length; i++) {
    s = s.replaceAll(de[i], a[i]);
  }
  s = s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return s.isEmpty ? 'campo' : s;
}

List<String> _parseOpciones(dynamic o) {
  if (o == null) return <String>[];
  final s = o.toString().trim();
  if (s.isEmpty) return <String>[];
  try {
    final d = jsonDecode(s);
    if (d is List) return d.map((e) => e.toString()).toList();
  } catch (_) {}
  return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

class _CamposTab extends StatefulWidget {
  const _CamposTab({Key? key}) : super(key: key);

  @override
  State<_CamposTab> createState() => _CamposTabState();
}

class _CamposTabState extends State<_CamposTab> {
  late final Dio _dio = _dioUsuario(context);
  List<Map<String, dynamic>> _categorias = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _campos = <Map<String, dynamic>>[];
  int _categoria = 0;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/almacen/producto/categoria');
      _categorias = _filas(_cuerpo(r));
      if (_categorias.isNotEmpty && _categoria == 0) {
        _categoria = (_categorias.first['id'] as num).toInt();
      }
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
    if (_categoria > 0) await _cargarCampos();
  }

  Future<void> _cargarCampos() async {
    if (_categoria == 0) return;
    setState(() => _cargando = true);
    try {
      final r = await _dio.get('/api/dynamic-fields/definitions',
          queryParameters: {'category_id': _categoria});
      _campos = _filas(r.data);
      _campos.sort((a, b) => ((a['display_order'] as num?) ?? 0)
          .compareTo((b['display_order'] as num?) ?? 0));
      _error = null;
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Map<String, dynamic>? _catPorId(int? id) {
    if (id == null) return null;
    for (final c in _categorias) {
      if ((c['id'] as num).toInt() == id) return c;
    }
    return null;
  }

  String _etiquetaCategoria(Map<String, dynamic> c) {
    final nombre = (c['descripcion'] ?? c['nombre'] ?? '').toString();
    final padre = _catPorId((c['padreId'] as num?)?.toInt());
    return padre == null
        ? nombre
        : '${(padre['descripcion'] ?? '').toString()} › $nombre';
  }

  List<Map<String, dynamic>> _categoriasOrdenadas() {
    String n(Map<String, dynamic> c) => (c['descripcion'] ?? '').toString().toLowerCase();
    final ids = _categorias.map((c) => (c['id'] as num).toInt()).toSet();
    final raices = _categorias
        .where((c) => c['padreId'] == null || !ids.contains((c['padreId'] as num).toInt()))
        .toList()
      ..sort((a, b) => n(a).compareTo(n(b)));
    final out = <Map<String, dynamic>>[];
    for (final r in raices) {
      out.add(r);
      out.addAll(_categorias
          .where((c) => c['padreId'] != null && (c['padreId'] as num).toInt() == (r['id'] as num).toInt())
          .toList()
        ..sort((a, b) => n(a).compareTo(n(b))));
    }
    return out;
  }

  String? _infoPadre() {
    final padre = _catPorId((_catPorId(_categoria)?['padreId'] as num?)?.toInt());
    if (padre == null) return null;
    return 'Es subcategoría de «${padre['descripcion']}»: además de estos campos, '
        'también pide los campos de «${padre['descripcion']}».';
  }

  Future<void> _ordenarCategorias() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CategoriasOrdenPage(dio: _dio)),
    );
    await _cargarCategorias();
  }

  Future<void> _plantilla() async {
    try {
      final r = await _dio.get<dynamic>('/api/dynamic-fields/plantillas');
      final lista = _filas(r.data);
      final cat = _catPorId(_categoria);
      final sug = sugerirPlantillaCategoria(
          (cat?['descripcion'] ?? '').toString(), lista);
      if (!mounted) return;
      final clave = await elegirPlantilla(context, lista,
          sugerida: sug?['clave']?.toString());
      if (clave == null) return;
      final res = await _dio.post<dynamic>('/api/dynamic-fields/plantillas/aplicar',
          data: {'category_id': _categoria, 'plantilla': clave});
      final d = res.data;
      if (mounted) {
        final nuevos = d is Map ? (d['creados'] ?? 0) : 0;
        final act = d is Map ? (d['actualizados'] ?? 0) : 0;
        _aviso(
            context,
            'Campos nuevos: $nuevos'
            '${act is num && act > 0 ? ' · Opciones completadas en $act campos' : ''}'
            '${nuevos == 0 && (act is! num || act == 0) ? ' (ya estaba todo al día)' : ''}');
      }
    } catch (e) {
      if (mounted) _aviso(context, _msg(e));
    }
    await _cargarCategorias();
  }

  Future<void> _ejecutar(Future<void> Function() fn, String ok) async {
    try {
      await fn();
      _aviso(context, ok);
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargarCampos();
  }

  Future<void> _editar({Map<String, dynamic>? campo}) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CampoDialog(campo: campo),
    );
    if (r == null) return;
    await _ejecutar(() async {
      if (campo == null) {
        await _dio.post('/api/dynamic-fields/definitions', data: {
          'name': _slug(r['label'].toString()),
          'label': r['label'],
          'field_type': r['field_type'],
          'options': r['options'],
          'is_required': r['is_required'],
          'is_active': r['is_active'],
          'display_order': _campos.length + 1,
          'category_id': _categoria,
        });
      } else {
        await _dio.put('/api/dynamic-fields/definitions/${campo['id']}', data: {
          'label': r['label'],
          'field_type': r['field_type'],
          'options': r['options'],
          'is_required': r['is_required'],
          'is_active': r['is_active'],
        });
      }
    }, campo == null ? 'Campo agregado' : 'Campo actualizado');
  }

  Future<void> _borrar(Map<String, dynamic> c) async {
    final ok = await _confirmar(context, 'Quitar campo',
        'Se quitará el campo "${c['label']}" de esta categoría. Los datos ya guardados no se pierden. ¿Continuar?');
    if (!ok) return;
    await _ejecutar(() async {
      await _dio.delete('/api/dynamic-fields/definitions/${c['id']}');
    }, 'Campo quitado');
  }

  Future<void> _activar(Map<String, dynamic> c, bool v) async {
    await _ejecutar(() async {
      await _dio.put('/api/dynamic-fields/definitions/${c['id']}',
          data: {'is_active': v});
    }, v ? 'Campo activado' : 'Campo desactivado');
  }

  Future<void> _mover(int i, int delta) async {
    final j = i + delta;
    if (j < 0 || j >= _campos.length) return;
    final copia = List<Map<String, dynamic>>.from(_campos);
    final t = copia[i];
    copia[i] = copia[j];
    copia[j] = t;
    await _ejecutar(() async {
      await _dio.post('/api/dynamic-fields/definitions/reorder', data: {
        'orders': [
          for (var k = 0; k < copia.length; k++)
            {'id': copia[k]['id'], 'display_order': k + 1},
        ],
      });
    }, 'Orden actualizado');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Aviso(
            'Cree aquí los datos extra que lleva cada categoría. Por ejemplo, "Placa" solo en Vehículos, '
            'y nada extra en Artefactos. Cada categoría tiene sus propios campos.'),
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<int>(
            value: _categorias.any((c) => (c['id'] as num).toInt() == _categoria)
                ? _categoria
                : null,
            decoration: const InputDecoration(
                labelText: 'Categoría', border: OutlineInputBorder(), isDense: true),
            isExpanded: true,
            items: [
              for (final c in _categoriasOrdenadas())
                DropdownMenuItem<int>(
                  value: (c['id'] as num).toInt(),
                  child: Text(_etiquetaCategoria(c), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) {
              _categoria = v ?? 0;
              _cargarCampos();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _ordenarCategorias,
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('Ordenar mis categorías'),
              ),
              if (_categoria > 0)
                OutlinedButton.icon(
                  onPressed: _plantilla,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Campos sugeridos'),
                ),
              if (_categoria > 0)
                ElevatedButton.icon(
                  onPressed: () => _editar(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar campo'),
                ),
            ],
          ),
        ),
        if (_infoPadre() != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(_infoPadre()!,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red))))
                  : RefreshIndicator(
                      onRefresh: _cargarCampos,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 30),
                        children: [
                          if (_campos.isEmpty)
                            const Padding(
                                padding: EdgeInsets.all(30),
                                child: Text(
                                    'Esta categoría no tiene campos extra todavía.',
                                    textAlign: TextAlign.center)),
                          for (var i = 0; i < _campos.length; i++)
                            Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                onTap: () => _editar(campo: _campos[i]),
                                title: Text((_campos[i]['label'] ?? '').toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Wrap(
                                  spacing: 6,
                                  children: [
                                    Chip(
                                      label: Text(
                                          _tipos[_campos[i]['field_type']] ??
                                              _campos[i]['field_type'].toString(),
                                          style: const TextStyle(fontSize: 11)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (_campos[i]['is_required'] == true)
                                      const Chip(
                                        label: Text('Obligatorio',
                                            style: TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    if (_campos[i]['is_active'] == false)
                                      const Chip(
                                        label: Text('Desactivado',
                                            style: TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                            onTap: () => _mover(i, -1),
                                            child: const Icon(Icons.keyboard_arrow_up)),
                                        InkWell(
                                            onTap: () => _mover(i, 1),
                                            child: const Icon(Icons.keyboard_arrow_down)),
                                      ],
                                    ),
                                    Switch(
                                      value: _campos[i]['is_active'] != false,
                                      onChanged: (v) => _activar(_campos[i], v),
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _borrar(_campos[i])),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class _CampoDialog extends StatefulWidget {
  const _CampoDialog({Key? key, this.campo}) : super(key: key);

  final Map<String, dynamic>? campo;

  @override
  State<_CampoDialog> createState() => _CampoDialogState();
}

class _CampoDialogState extends State<_CampoDialog> {
  late final TextEditingController _label =
      TextEditingController(text: (widget.campo?['label'] ?? '').toString());
  late final TextEditingController _opciones = TextEditingController(
      text: _parseOpciones(widget.campo?['options']).join(', '));
  late String _tipo = _tipos.containsKey(widget.campo?['field_type'])
      ? widget.campo!['field_type'].toString()
      : 'text';
  late bool _obligatorio = widget.campo?['is_required'] == true;
  late bool _activo = widget.campo?['is_active'] != false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _opciones.dispose();
    super.dispose();
  }

  bool get _usaOpciones => _tipo == 'select' || _tipo == 'multi-select';

  void _guardar() {
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Escriba el nombre del campo');
      return;
    }
    final lista = _opciones.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (_usaOpciones && lista.isEmpty) {
      setState(() => _error = 'Escriba las opciones separadas por coma');
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'label': label,
      'field_type': _tipo,
      'options': _usaOpciones ? jsonEncode(lista) : null,
      'is_required': _obligatorio,
      'is_active': _activo,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.campo == null ? 'Nuevo campo' : 'Editar campo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Nombre del campo (ej. Placa)'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de dato'),
              items: [
                for (final e in _tipos.entries)
                  DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? 'text'),
            ),
            if (_usaOpciones)
              TextField(
                controller: _opciones,
                decoration: const InputDecoration(
                    labelText: 'Opciones (separadas por coma)',
                    hintText: 'Rojo, Azul, Negro'),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Obligatorio'),
              value: _obligatorio,
              onChanged: (v) => setState(() => _obligatorio = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activo'),
              value: _activo,
              onChanged: (v) => setState(() => _activo = v),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

// ===========================================================================
// 4) Configuración del sistema
// ===========================================================================

class _SistemaTab extends StatefulWidget {
  const _SistemaTab({Key? key}) : super(key: key);

  @override
  State<_SistemaTab> createState() => _SistemaTabState();
}

class _SistemaTabState extends State<_SistemaTab> {
  late final Dio _dio = _dioUsuario(context);
  List<Map<String, dynamic>> _config = <Map<String, dynamic>>[];
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
      final r = await _dio.get('/api/admin/config');
      _config = _filas(r.data);
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _editar(Map<String, dynamic> c) async {
    final actual = (c['config_value'] ?? '').toString();
    final ctrl = TextEditingController(text: actual);
    String? error;
    final nuevo = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text((c['description'] ?? c['config_key']).toString()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clave: ${c['config_key']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Valor anterior: $actual',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrl,
                  maxLines: actual.length > 40 ? 6 : 1,
                  decoration: InputDecoration(
                      labelText: 'Nuevo valor',
                      border: const OutlineInputBorder(),
                      errorText: error),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final v = ctrl.text.trim();
                final t = actual.trim();
                if (t.startsWith('{') || t.startsWith('[')) {
                  try {
                    jsonDecode(v);
                  } catch (_) {
                    setS(() => error = 'El formato no es válido');
                    return;
                  }
                } else if (double.tryParse(t) != null && double.tryParse(v) == null) {
                  setS(() => error = 'Debe ser un número');
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (nuevo == null || nuevo == actual) return;
    try {
      await _dio.put('/api/admin/config/${c['config_key']}',
          data: {'config_value': nuevo});
      _aviso(context, 'Configuración guardada');
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  Future<void> _restablecer(Map<String, dynamic> c) async {
    final ok = await _confirmar(context, 'Restablecer',
        'Se volverá al valor original de "${c['config_key']}". ¿Continuar?');
    if (!ok) return;
    try {
      await _dio.post('/api/admin/config/${c['config_key']}/reset');
      _aviso(context, 'Valor restablecido');
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    final grupos = <String, List<Map<String, dynamic>>>{};
    for (final c in _config) {
      grupos.putIfAbsent((c['config_type'] ?? 'general').toString(), () => <Map<String, dynamic>>[]).add(c);
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const _Aviso(
              'Estos valores controlan cálculos del sistema (mora, tasas, descuentos, rangos). '
              'Anote el valor anterior antes de cambiar: un valor mal puesto afecta a todos los préstamos nuevos.'),
          if (_config.isEmpty)
            const Padding(
                padding: EdgeInsets.all(30),
                child: Text('No hay configuraciones guardadas.', textAlign: TextAlign.center)),
          for (final e in grupos.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              child: Text(e.key.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            for (final c in e.value)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  onTap: () => _editar(c),
                  title: Text((c['description'] ?? c['config_key']).toString()),
                  subtitle: Text(
                    (c['config_value'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => v == 'e' ? _editar(c) : _restablecer(c),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'e', child: Text('Cambiar valor')),
                      PopupMenuItem(value: 'r', child: Text('Restablecer')),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// 3) Permisos: escalera de mando y qué puede hacer cada puesto
// ===========================================================================

const Map<String, String> _accionTxt = <String, String>{
  'crear': 'Crear',
  'editar': 'Editar',
  'eliminar': 'Eliminar',
  'anular': 'Anular o cancelar',
};

String _haceTxt(dynamic v) {
  final d = DateTime.tryParse(v?.toString() ?? '')?.toLocal();
  if (d == null) return '';
  final dif = DateTime.now().difference(d);
  if (dif.inMinutes < 1) return 'hace un momento';
  if (dif.inMinutes < 60) return 'hace ${dif.inMinutes} min';
  if (dif.inHours < 24) return 'hace ${dif.inHours} h';
  return 'hace ${dif.inDays} días';
}

class _Paso extends StatelessWidget {
  const _Paso(this.numero, this.titulo, this.texto, {Key? key}) : super(key: key);
  final int numero;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.indigo,
            child: Text('$numero',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(texto,
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermisosTab extends StatefulWidget {
  const _PermisosTab({Key? key}) : super(key: key);

  @override
  State<_PermisosTab> createState() => _PermisosTabState();
}

class _PermisosTabState extends State<_PermisosTab> {
  late final Dio _dio = _dioUsuario(context);
  bool _activo = false;
  List<Map<String, dynamic>> _roles = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _modulos = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _acciones = <Map<String, dynamic>>[];
  int _rolSel = 0;
  Set<String> _bloqueados = <String>{};
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Map<String, dynamic>? get _rol {
    for (final r in _roles) {
      if ((r['id'] as num).toInt() == _rolSel) return r;
    }
    return null;
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final rc = await _dio.get('/acceso/catalogo');
      final cb = _cuerpo(rc);
      if (cb is Map) {
        _modulos = _filas(cb['modulos']);
        _acciones = _filas(cb['acciones']);
      }
      final re = await _dio.get('/acceso/estado');
      final eb = _cuerpo(re);
      _activo = eb is Map && eb['activo'] == true;
      final rr = await _dio.get('/acceso/roles');
      _roles = _filas(_cuerpo(rr));
      if (_rolSel == 0 && _roles.isNotEmpty) {
        final noAdmin = _roles.where((r) => r['esAdmin'] != true).toList();
        _rolSel = ((noAdmin.isNotEmpty ? noAdmin.first : _roles.first)['id'] as num).toInt();
      }
      await _cargarBloqueos();
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarBloqueos() async {
    _bloqueados = <String>{};
    if (_rolSel == 0) return;
    final r = await _dio.get('/acceso/permisos/$_rolSel');
    final b = _cuerpo(r);
    if (b is Map && b['bloqueados'] is List) {
      for (final x in b['bloqueados'] as List) {
        if (x is Map) _bloqueados.add('${x['modulo']}|${x['accion']}');
      }
    }
  }

  // Orden sugerido: Administrador, Gerente, Encargado de tienda y después los demás
  // puestos (caja, etc.) tal como ya estaban.
  int _rango(String nombre) {
    final n = nombre
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
    if (n == 'administrador' || n == 'administradora' || n == 'admin') return 1;
    if (n == 'gerente' || n == 'gerenta') return 2;
    if (n.startsWith('encargad')) return 3;
    return 4;
  }

  Future<void> _ordenSugerido() async {
    final copia = List<Map<String, dynamic>>.from(_roles);
    final pos = <Object?, int>{
      for (var i = 0; i < copia.length; i++) copia[i]['id']: i,
    };
    copia.sort((a, b) {
      final c = _rango((a['nombre'] ?? '').toString())
          .compareTo(_rango((b['nombre'] ?? '').toString()));
      return c != 0 ? c : pos[a['id']]!.compareTo(pos[b['id']]!);
    });
    setState(() => _roles = copia);
    try {
      await _dio.put('/acceso/roles/orden',
          data: {'orden': copia.map((r) => r['id']).toList()});
      _aviso(context, 'Escalera ordenada: Administrador, Gerente, Encargado y los demás');
    } catch (e) {
      _aviso(context, _msg(e));
      await _cargar();
    }
  }

  Future<void> _mover(int i, int delta) async {
    final j = i + delta;
    if (j < 0 || j >= _roles.length) return;
    final copia = List<Map<String, dynamic>>.from(_roles);
    final t = copia[i];
    copia[i] = copia[j];
    copia[j] = t;
    setState(() => _roles = copia);
    try {
      await _dio.put('/acceso/roles/orden',
          data: {'orden': _roles.map((r) => r['id']).toList()});
    } catch (e) {
      _aviso(context, _msg(e));
      await _cargar();
    }
  }

  Future<void> _marcarAdmin(Map<String, dynamic> r, bool v) async {
    try {
      await _dio.put('/acceso/roles/${r['id']}/admin', data: {'esAdmin': v});
      await _cargar();
    } catch (e) {
      _aviso(context, _msg(e));
    }
  }

  Future<void> _cambiar(String modulo, String accion, bool permitido) async {
    final clave = '$modulo|$accion';
    setState(() {
      if (permitido) {
        _bloqueados.remove(clave);
      } else {
        _bloqueados.add(clave);
      }
    });
    try {
      await _dio.put('/acceso/permisos/$_rolSel', data: {
        'cambios': [
          {'modulo': modulo, 'accion': accion, 'permitido': permitido}
        ],
      });
    } catch (e) {
      setState(() {
        if (permitido) {
          _bloqueados.add(clave);
        } else {
          _bloqueados.remove(clave);
        }
      });
      _aviso(context, _msg(e));
    }
  }

  Future<void> _plantilla(String tipo, String nombre) async {
    final ok = await _confirmar(context, 'Aplicar "$nombre"',
        'Se reemplazarán todos los permisos actuales de este puesto. ¿Continuar?');
    if (!ok) return;
    bool bloquea(String accion) {
      switch (tipo) {
        case 'cajero':
          return accion == 'eliminar' || accion == 'anular';
        case 'supervisor':
          return accion == 'eliminar';
        case 'consulta':
          return true;
        default:
          return false;
      }
    }

    final cambios = <Map<String, dynamic>>[];
    for (final m in _modulos) {
      for (final a in _acciones) {
        cambios.add({
          'modulo': m['clave'],
          'accion': a['clave'],
          'permitido': !bloquea(a['clave'].toString()),
        });
      }
    }
    try {
      await _dio.put('/acceso/permisos/$_rolSel', data: {'cambios': cambios});
      _aviso(context, 'Permisos aplicados');
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  Future<void> _cambiarEstado(bool v) async {
    final ok = await _confirmar(
        context,
        v ? 'Activar restricciones' : 'Apagar restricciones',
        v
            ? 'Desde ahora, los puestos que no son administradores no podrán hacer lo que usted bloqueó. '
                'Si lo intentan, podrán pedirle autorización. Puede apagar esto cuando quiera. ¿Activar?'
            : 'Nadie quedará bloqueado. ¿Apagar las restricciones?');
    if (!ok) return;
    try {
      await _dio.put('/acceso/estado', data: {'activo': v});
      _aviso(context, v ? 'Restricciones activadas' : 'Restricciones apagadas');
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    final rol = _rol;
    final esAdminRol = rol != null && rol['esAdmin'] == true;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const _Aviso(
              'En 3 pasos: 1) ordene los puestos por autoridad, 2) elija qué puede hacer cada puesto, '
              '3) active las restricciones. Mientras estén apagadas, nadie queda bloqueado.'),
          // ------------------------------------------------ Paso 1
          const _Paso(1, 'Escalera de mando',
              'Arriba, mayor autoridad. Una persona puede autorizar las solicitudes de los puestos que están más abajo.'),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _ordenSugerido,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Ordenar: Administrador, Gerente, Encargado…'),
              ),
            ),
          ),
          for (var i = 0; i < _roles.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text((_roles[i]['nombre'] ?? '').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${_roles[i]['usuarios']} personas · ${_roles[i]['bloqueos']} acciones bloqueadas'
                        '${i == 0 ? '\nMayor autoridad' : (i == _roles.length - 1 ? '\nMenor autoridad' : '')}'),
                    isThreeLine: i == 0 || i == _roles.length - 1,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            tooltip: 'Subir',
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: i == 0 ? null : () => _mover(i, -1)),
                        IconButton(
                            tooltip: 'Bajar',
                            icon: const Icon(Icons.arrow_downward),
                            onPressed:
                                i == _roles.length - 1 ? null : () => _mover(i, 1)),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    dense: true,
                    title: const Text('Administrador total'),
                    subtitle: const Text('Puede hacer todo, sin restricciones'),
                    value: _roles[i]['esAdmin'] == true,
                    onChanged: (v) => _marcarAdmin(_roles[i], v),
                  ),
                ],
              ),
            ),
          // ------------------------------------------------ Paso 2
          const _Paso(2, 'Qué puede hacer cada puesto',
              'Elija un puesto y active o apague lo que puede hacer en cada parte del sistema. Se guarda solo.'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<int>(
              value: _roles.any((r) => (r['id'] as num).toInt() == _rolSel) ? _rolSel : null,
              decoration: const InputDecoration(
                  labelText: 'Puesto', border: OutlineInputBorder(), isDense: true),
              items: [
                for (final r in _roles)
                  DropdownMenuItem<int>(
                    value: (r['id'] as num).toInt(),
                    child: Text((r['nombre'] ?? '').toString()),
                  ),
              ],
              onChanged: (v) async {
                _rolSel = v ?? 0;
                setState(() => _cargando = true);
                try {
                  await _cargarBloqueos();
                } catch (e) {
                  _aviso(context, _msg(e));
                }
                if (mounted) setState(() => _cargando = false);
              },
            ),
          ),
          if (esAdminRol)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Este puesto es "Administrador total": puede hacerlo todo. Para restringirlo, quítele esa marca en el paso 1.',
                style: TextStyle(color: Colors.orange),
              ),
            )
          else if (rol != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ActionChip(
                      avatar: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Todo permitido'),
                      onPressed: () => _plantilla('todo', 'Todo permitido')),
                  ActionChip(
                      avatar: const Icon(Icons.point_of_sale, size: 18),
                      label: const Text('Cajero: sin eliminar ni anular'),
                      onPressed: () => _plantilla('cajero', 'Cajero')),
                  ActionChip(
                      avatar: const Icon(Icons.supervisor_account, size: 18),
                      label: const Text('Supervisor: sin eliminar'),
                      onPressed: () => _plantilla('supervisor', 'Supervisor')),
                  ActionChip(
                      avatar: const Icon(Icons.visibility, size: 18),
                      label: const Text('Solo consulta'),
                      onPressed: () => _plantilla('consulta', 'Solo consulta')),
                ],
              ),
            ),
            const SizedBox(height: 6),
            for (final m in _modulos)
              ExpansionTile(
                title: Text((m['nombre'] ?? '').toString()),
                subtitle: Text(() {
                  final bloq = _acciones
                      .where((a) => _bloqueados.contains('${m['clave']}|${a['clave']}'))
                      .length;
                  return bloq == 0
                      ? 'Todo permitido'
                      : '$bloq de ${_acciones.length} acciones bloqueadas';
                }(),
                    style: TextStyle(
                        color: _acciones.any((a) =>
                                _bloqueados.contains('${m['clave']}|${a['clave']}'))
                            ? Colors.red
                            : Colors.green)),
                children: [
                  for (final a in _acciones)
                    SwitchListTile(
                      dense: true,
                      title: Text(_accionTxt[a['clave']] ?? a['nombre'].toString()),
                      subtitle: Text((a['explicacion'] ?? '').toString(),
                          style: const TextStyle(fontSize: 12)),
                      value: !_bloqueados.contains('${m['clave']}|${a['clave']}'),
                      onChanged: (v) =>
                          _cambiar(m['clave'].toString(), a['clave'].toString(), v),
                    ),
                ],
              ),
          ],
          // ------------------------------------------------ Paso 3
          const _Paso(3, 'Activar las restricciones',
              'Cuando termine, actívelas. Al principio están apagadas para que pueda configurar tranquilo.'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: _activo ? Colors.green.shade50 : Colors.orange.shade50,
            child: SwitchListTile(
              title: Text(_activo ? 'Restricciones ACTIVAS' : 'Restricciones APAGADAS',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_activo
                  ? 'Los puestos no administradores solo pueden hacer lo que usted permitió.'
                  : 'Nadie está bloqueado.'),
              value: _activo,
              onChanged: _cambiarEstado,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Cuando alguien intente algo bloqueado, la app le ofrecerá pedir autorización. '
              'Usted la aprueba en la pestaña "Solicitudes".',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 4) Solicitudes de autorización
// ===========================================================================

class _SolicitudesTab extends StatefulWidget {
  const _SolicitudesTab({Key? key}) : super(key: key);

  @override
  State<_SolicitudesTab> createState() => _SolicitudesTabState();
}

class _SolicitudesTabState extends State<_SolicitudesTab> {
  late final Dio _dio = _dioUsuario(context);
  List<Map<String, dynamic>> _pendientes = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _historial = <Map<String, dynamic>>[];
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
      final rp = await _dio.get('/acceso/solicitudes', queryParameters: {'estado': 'PENDIENTE'});
      final rh = await _dio.get('/acceso/solicitudes', queryParameters: {'estado': 'HISTORIAL'});
      _pendientes = _filas(_cuerpo(rp));
      _historial = _filas(_cuerpo(rh));
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _aprobar(Map<String, dynamic> s) async {
    String opcion = '30';
    final nota = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Aprobar solicitud'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s['usuario']} podrá ${(_accionTxt[s['accion']] ?? s['accion']).toString().toLowerCase()} en "${s['moduloNombre']}".'),
                const SizedBox(height: 8),
                const Text('¿Por cuánto tiempo?',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                RadioListTile<String>(
                    dense: true,
                    title: const Text('Una sola vez'),
                    value: 'una',
                    groupValue: opcion,
                    onChanged: (v) => setS(() => opcion = v!)),
                RadioListTile<String>(
                    dense: true,
                    title: const Text('30 minutos'),
                    value: '30',
                    groupValue: opcion,
                    onChanged: (v) => setS(() => opcion = v!)),
                RadioListTile<String>(
                    dense: true,
                    title: const Text('2 horas'),
                    value: '120',
                    groupValue: opcion,
                    onChanged: (v) => setS(() => opcion = v!)),
                TextField(
                  controller: nota,
                  decoration: const InputDecoration(labelText: 'Nota (opcional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aprobar')),
          ],
        ),
      ),
    );
    final texto = nota.text.trim();
    nota.dispose();
    if (ok != true) return;
    await _resolver(s, {
      'aprobar': true,
      'unaVez': opcion == 'una',
      'minutos': opcion == 'una' ? 60 : int.parse(opcion),
      'nota': texto,
    }, 'Solicitud aprobada');
  }

  Future<void> _rechazar(Map<String, dynamic> s) async {
    final nota = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: TextField(
          controller: nota,
          decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rechazar')),
        ],
      ),
    );
    final texto = nota.text.trim();
    nota.dispose();
    if (ok != true) return;
    await _resolver(s, {'aprobar': false, 'nota': texto}, 'Solicitud rechazada');
  }

  Future<void> _resolver(Map<String, dynamic> s, Map<String, dynamic> datos, String ok) async {
    try {
      await _dio.put('/acceso/solicitudes/${s['id']}/resolver', data: datos);
      _aviso(context, ok);
    } catch (e) {
      _aviso(context, _msg(e));
    }
    await _cargar();
  }

  Color _color(String estado) {
    switch (estado) {
      case 'APROBADA':
        return Colors.green;
      case 'RECHAZADA':
        return Colors.red;
      case 'PENDIENTE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const _Aviso(
              'Aquí llegan los pedidos de personas que intentaron algo bloqueado. '
              'Usted decide si lo permite una vez o por un tiempo. Solo un administrador o un puesto superior puede aprobar.'),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Text('Pendientes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          if (_pendientes.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay solicitudes pendientes.', textAlign: TextAlign.center)),
          for (final s in _pendientes)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${s['usuario']}${s['rol'] != null ? ' (${s['rol']})' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                        'Quiere: ${_accionTxt[s['accion']] ?? s['accion']} en ${s['moduloNombre']}'),
                    if ((s['motivo'] ?? '').toString().isNotEmpty)
                      Text('Motivo: ${s['motivo']}'),
                    Text(_haceTxt(s['fecha']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                            onPressed: () => _rechazar(s),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: const Text('Rechazar',
                                style: TextStyle(color: Colors.red))),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                            onPressed: () => _aprobar(s),
                            icon: const Icon(Icons.check),
                            label: const Text('Aprobar')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 20, 14, 4),
            child: Text('Historial reciente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          if (_historial.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Todavía no hay historial.', textAlign: TextAlign.center)),
          for (final s in _historial)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: ListTile(
                dense: true,
                title: Text(
                    '${s['usuario']}: ${_accionTxt[s['accion']] ?? s['accion']} en ${s['moduloNombre']}'),
                subtitle: Text(
                  '${s['resolvio'] != null ? 'Resolvió: ${s['resolvio']}  ·  ' : ''}${_haceTxt(s['resueltoAt'] ?? s['fecha'])}'
                  '${(s['nota'] ?? '').toString().isNotEmpty ? '\nNota: ${s['nota']}' : ''}',
                ),
                trailing: Chip(
                  label: Text(s['estado'].toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: _color(s['estado'].toString()),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// ===========================================================================
// Recuperar observaciones (contraseñas, datos extra) de las prendas
// ===========================================================================

class _RecuperarObservacionesPage extends StatefulWidget {
  const _RecuperarObservacionesPage({Key? key}) : super(key: key);

  @override
  State<_RecuperarObservacionesPage> createState() =>
      _RecuperarObservacionesPageState();
}

class _RecuperarObservacionesPageState
    extends State<_RecuperarObservacionesPage> {
  late final Dio _dio = _dioUsuario(context);
  Map<String, dynamic>? _vista;
  String? _resultado;
  String? _error;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _ver();
  }

  Future<void> _ver() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _dio.get('/recuperacion/observaciones/vista');
      final d = r.data;
      _vista = Map<String, dynamic>.from((d is Map ? d['body'] : null) ?? {});
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _aplicar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Recuperar ahora?'),
        content: const Text(
            'Solo se llenan las prendas que hoy están vacías. Lo que ya tiene datos no se toca.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Recuperar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final u = context.read<Preferences>().token;
      final r = await _dio.post('/recuperacion/observaciones/aplicar',
          data: {'usuarioId': u?.id ?? 0});
      final b = (r.data is Map ? r.data['body'] : null) ?? {};
      _resultado =
          'Se recuperaron ${b['aplicados'] ?? 0} prendas. Quedan ${b['sinRespaldo'] ?? 0} sin respaldo en el historial.';
      await _ver();
    } catch (e) {
      _error = _msg(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final v = _vista;
    final ejemplos = ((v?['ejemplos'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final pendientes = ((v?['pendientes'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar observaciones')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                if (_resultado != null)
                  Card(
                      color: Colors.green.shade50,
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_resultado!))),
                if (v != null) ...[
                  Text('Prendas sin observaciones: ${v['totalSinObservaciones']}'),
                  Text('Se pueden recuperar: ${v['recuperables']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('Sin respaldo en el historial: ${v['sinRespaldo']}'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: (v['recuperables'] ?? 0) > 0 ? _aplicar : null,
                    icon: const Icon(Icons.restore),
                    label: const Text('Recuperar ahora'),
                  ),
                  const SizedBox(height: 12),
                  if (ejemplos.isNotEmpty)
                    const Text('Lo que se devolverá:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  for (final e in ejemplos)
                    Card(
                      child: ListTile(
                        dense: true,
                        title: Text(
                            'Préstamo ${e['prestamoCodigo']} · ${e['descripcion']}'),
                        subtitle: Text('${e['valor']}'),
                      ),
                    ),
                  if (pendientes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Sin respaldo (hay que revisarlos a mano):',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    for (final e in pendientes)
                      ListTile(
                        dense: true,
                        title: Text(
                            'Préstamo ${e['prestamoCodigo']} · ${e['descripcion']}'),
                      ),
                  ],
                ],
              ],
            ),
    );
  }
}
