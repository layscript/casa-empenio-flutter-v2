import 'dart:convert';

import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/views/movements_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/desglose_medios.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Panel de SUCURSALES (solo administrador): ver, sin cerrar sesión, la caja de
// hoy, las cajas anteriores y la cartera de cada sucursal.
// ---------------------------------------------------------------------------

final _dio = Dio(
  BaseOptions(
    baseUrl: endPointPrincipal,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ),
);

final _soles = NumberFormat('#,##0.00', 'en_US');

double _n(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

String _s(double v) => 'S/.${_soles.format(v)}';

Future<dynamic> _cuerpo(String ruta) async {
  final r = await _dio.get<dynamic>(ruta);
  final data = r.data;
  final map = (data is String ? json.decode(data) : data) as Map;
  return map['body'];
}

String _error(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return 'No hay conexión con el servidor';
  }
  return 'Ocurrió un error';
}

Widget _cargando() => const Center(child: CircularProgressIndicator());

Widget _errorVista(String mensaje, VoidCallback reintentar) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 42, color: Colors.grey),
            const SizedBox(height: 10),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: reintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );

// ============================================================== PANEL GENERAL
class SucursalesPanelView extends StatefulWidget {
  const SucursalesPanelView({super.key});

  @override
  State<SucursalesPanelView> createState() => _SucursalesPanelViewState();
}

class _SucursalesPanelViewState extends State<SucursalesPanelView> {
  late Future<dynamic> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cuerpo('/finanza/caja/panel-sucursales');
  }

  void _recargar() {
    setState(() => _futuro = _cuerpo('/finanza/caja/panel-sucursales'));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _cargando();
        if (snap.hasError) {
          return _errorVista(_error(snap.error!), _recargar);
        }
        final body = snap.data as Map<String, dynamic>? ?? {};
        final lista = (body['sucursales'] as List? ?? [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();

        var efectivo = 0.0, cobrado = 0.0, prestado = 0.0, vencidos = 0.0;
        for (final s in lista) {
          efectivo += _n((s['cajaHoy'] as Map?)?['efectivoEnMano']);
          cobrado += _n((s['hoy'] as Map?)?['cobrado']);
          prestado += _n((s['hoy'] as Map?)?['prestado']);
          vencidos += _n((s['cartera'] as Map?)?['vencidos']);
        }

        return RefreshIndicator(
          onRefresh: () async {
            _recargar();
            await _futuro.catchError((_) => null);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aquí ves todas tus sucursales sin cerrar sesión. '
                        'Toca una sucursal para ver su caja, los movimientos '
                        'y su cartera. Desliza hacia abajo para actualizar.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Todas las sucursales · hoy',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _s(efectivo),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const Text(
                      'efectivo en cajas abiertas',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _kpiBlanco('Cobrado', _s(cobrado)),
                        const SizedBox(width: 8),
                        _kpiBlanco('Prestado', _s(prestado)),
                        const SizedBox(width: 8),
                        _kpiBlanco('Vencidos', vencidos.toStringAsFixed(0)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('No hay sucursales registradas.')),
                ),
              for (final s in lista) _tarjeta(context, s),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiBlanco(String titulo, String valor) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                titulo,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _tarjeta(BuildContext context, Map<String, dynamic> s) {
    final caja = (s['cajaHoy'] as Map?)?.cast<String, dynamic>();
    final ultima = (s['ultimaCaja'] as Map?)?.cast<String, dynamic>();
    final cartera = (s['cartera'] as Map?)?.cast<String, dynamic>() ?? {};
    final hoy = (s['hoy'] as Map?)?.cast<String, dynamic>() ?? {};
    final abierta = caja != null;
    final vencidos = _n(cartera['vencidos']);
    final difUlt = _n(ultima?['diferencia']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SucursalDetalleView(sucursal: s)),
          );
          if (mounted) _recargar();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront, color: AppColors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${s['nombre']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: (abierta ? Colors.green : Colors.blueGrey)
                          .withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      abierta ? 'Caja abierta' : 'Caja cerrada',
                      style: TextStyle(
                        color: abierta ? Colors.green[800] : Colors.blueGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if ('${s['direccion'] ?? ''}'.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(
                    '${s['direccion']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              const Divider(height: 20),
              if (abierta) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Efectivo en caja',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    Text(
                      _s(_n(caja['efectivoEnMano'])),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Abrió ${caja['abiertaPor'] ?? '-'} a las ${caja['horaApertura'] ?? '-'} · '
                  'Entró ${_s(_n(caja['ingresos']))} · Salió ${_s(_n(caja['egresos']))} · '
                  '${caja['movimientos']} movimientos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ] else
                Text(
                  ultima == null
                      ? 'Todavía no tiene cajas.'
                      : 'Última caja: ${ultima['fecha']} · '
                          '${difUlt == 0 ? 'cuadró ✔' : (difUlt > 0 ? 'faltó ${_s(difUlt)}' : 'sobró ${_s(-difUlt)}')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: ultima != null && difUlt != 0
                        ? Colors.red[700]
                        : Colors.grey[700],
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(Icons.payments_outlined,
                      'Cobrado hoy ${_s(_n(hoy['cobrado']))}', Colors.green),
                  _chip(Icons.request_quote_outlined,
                      'Prestado hoy ${_s(_n(hoy['prestado']))}', Colors.blue),
                  _chip(
                    Icons.warning_amber_rounded,
                    '${vencidos.toStringAsFixed(0)} vencidos',
                    vencidos > 0 ? Colors.red : Colors.blueGrey,
                  ),
                  _chip(
                    Icons.folder_open,
                    '${_n(cartera['abiertos']).toStringAsFixed(0)} préstamos · ${_s(_n(cartera['capitalEnCalle']))}',
                    Colors.blueGrey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icono, String texto, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 14, color: color),
            const SizedBox(width: 4),
            Text(texto, style: TextStyle(fontSize: 11.5, color: color)),
          ],
        ),
      );
}

// ============================================================ DETALLE SUCURSAL
class SucursalDetalleView extends StatelessWidget {
  const SucursalDetalleView({super.key, required this.sucursal});

  final Map<String, dynamic> sucursal;

  @override
  Widget build(BuildContext context) {
    final id = (sucursal['id'] as num).toInt();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(
          backgroundColor: AppColors.blue,
          title: Text('${sucursal['nombre']}'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Caja de hoy'),
              Tab(text: 'Cajas anteriores'),
              Tab(text: 'Cartera'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CajaHoyTab(sucursalId: id),
            _CajasAnterioresTab(sucursalId: id),
            _CarteraTab(sucursalId: id),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- caja de hoy
class _CajaHoyTab extends StatefulWidget {
  const _CajaHoyTab({required this.sucursalId});
  final int sucursalId;

  @override
  State<_CajaHoyTab> createState() => _CajaHoyTabState();
}

class _CajaHoyTabState extends State<_CajaHoyTab>
    with AutomaticKeepAliveClientMixin {
  late Future<dynamic> _futuro;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futuro = _cuerpo('/finanza/caja/actual/${widget.sucursalId}');
  }

  void _recargar() => setState(
      () => _futuro = _cuerpo('/finanza/caja/actual/${widget.sucursalId}'));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<dynamic>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _cargando();
        if (snap.hasError) return _errorVista(_error(snap.error!), _recargar);
        if (snap.data == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Esta sucursal no tiene la caja abierta ahora.\n'
                'Mira la pestaña "Cajas anteriores" para ver las cerradas.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final caja = CajaEntity.getCajaFromMap(snap.data, false);
        final movs = caja.movimientos ?? [];
        final enMano = efectivoEnMano(movs);
        return RefreshIndicator(
          onRefresh: () async {
            _recargar();
            await _futuro.catchError((_) => null);
          },
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Efectivo que debe haber en caja',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      _s(enMano),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    Text(
                      'Abierta ${caja.fecha ?? ''} · ${caja.horaApertura ?? ''}'
                      '${caja.usuarioApertura != null ? ' · ${caja.usuarioApertura!.fullName}' : ''}',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              DesgloseMedios(movimientos: movs),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: movs.isEmpty
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovementsView(
                              id: caja.id ?? 0,
                              movimientos: movs,
                              isClosed: false,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.list_alt),
                label: Text('Ver los ${movs.length} movimientos con detalle'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------ cajas anteriores
class _CajasAnterioresTab extends StatefulWidget {
  const _CajasAnterioresTab({required this.sucursalId});
  final int sucursalId;

  @override
  State<_CajasAnterioresTab> createState() => _CajasAnterioresTabState();
}

class _CajasAnterioresTabState extends State<_CajasAnterioresTab>
    with AutomaticKeepAliveClientMixin {
  late Future<dynamic> _futuro;

  @override
  bool get wantKeepAlive => true;

  String get _ruta =>
      '/finanza/caja?sucursalId=${widget.sucursalId}&limit=30&offset=0';

  @override
  void initState() {
    super.initState();
    _futuro = _cuerpo(_ruta);
  }

  void _recargar() => setState(() => _futuro = _cuerpo(_ruta));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<dynamic>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _cargando();
        if (snap.hasError) return _errorVista(_error(snap.error!), _recargar);
        final crudo = (snap.data is List && (snap.data as List).isNotEmpty)
            ? (snap.data as List)[0] as List
            : <dynamic>[];
        final cajas = CajaEntity.listGetCajaFromMap(crudo, false)
            .where((c) => c.estado != 'Abierta')
            .toList();
        if (cajas.isEmpty) {
          return const Center(child: Text('Aún no hay cajas cerradas.'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            _recargar();
            await _futuro.catchError((_) => null);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: cajas.length,
            itemBuilder: (context, i) {
              final c = cajas[i];
              // Diferencia = lo contado − lo que debía haber (0 = cuadrada)
              final d0 = double.tryParse(c.montoDiferencia ?? '0') ?? 0;
              final dif = d0 != 0 ? d0 * -1 : 0.0;
              final color = dif == 0 ? Colors.green[700]! : Colors.red[700]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovementsView(
                        id: c.id ?? 0,
                        movimientos: c.movimientos ?? [],
                        isClosed: true,
                      ),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.14),
                    child: Icon(
                      dif == 0 ? Icons.check : Icons.priority_high,
                      color: color,
                    ),
                  ),
                  title: Text(
                    '${c.fecha ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Entró ${_s(_n(c.totalIngresos))} · Salió ${_s(_n(c.totalEgresos))}\n'
                    '${dif == 0 ? 'Cuadró exacto' : (dif < 0 ? 'Faltaron ${_s(-dif)}' : 'Sobraron ${_s(dif)}')}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------- cartera
class _CarteraTab extends StatefulWidget {
  const _CarteraTab({required this.sucursalId});
  final int sucursalId;

  @override
  State<_CarteraTab> createState() => _CarteraTabState();
}

class _CarteraTabState extends State<_CarteraTab>
    with AutomaticKeepAliveClientMixin {
  late Future<dynamic> _futuro;

  @override
  bool get wantKeepAlive => true;

  String get _ruta => '/prestamos/prestamos/panel/${widget.sucursalId}';

  @override
  void initState() {
    super.initState();
    _futuro = _cuerpo(_ruta);
  }

  void _recargar() => setState(() => _futuro = _cuerpo(_ruta));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<dynamic>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _cargando();
        if (snap.hasError) return _errorVista(_error(snap.error!), _recargar);
        final p = (snap.data as Map).cast<String, dynamic>();
        final vencidos = (p['vencidos'] as List? ?? []).cast<dynamic>();
        final porVencer = (p['porVencer'] as List? ?? []).cast<dynamic>();

        Widget kpi(String t, String v, Color c) => Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    Text(t,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.secondaryText)),
                    const SizedBox(height: 2),
                    FittedBox(
                      child: Text(v,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: c)),
                    ),
                  ],
                ),
              ),
            );

        Widget fila(dynamic f, Color color) {
          final m = (f as Map).cast<String, dynamic>();
          final dias = _n(m['dias']).toInt();
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(
                '${m['cliente'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Préstamo N° ${m['codigoFormateado'] ?? m['codigo']} · DNI ${m['dni'] ?? '-'}'
                '${(m['celular'] ?? '').toString().isNotEmpty ? ' · Cel. ${m['celular']}' : ''}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _s(_n(m['saldo'])),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    dias < 0
                        ? 'hace ${-dias} d'
                        : (dias == 0 ? 'vence hoy' : 'en $dias d'),
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _recargar();
            await _futuro.catchError((_) => null);
          },
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Row(
                children: [
                  kpi('Préstamos abiertos', '${_n(p['abiertos']).toInt()}',
                      AppColors.blue),
                  const SizedBox(width: 8),
                  kpi('Capital en calle', _s(_n(p['capitalCalle'])),
                      Colors.blueGrey),
                  const SizedBox(width: 8),
                  kpi('Por cobrar', _s(_n(p['saldoPorCobrar'])),
                      Colors.green[700]!),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Vencidos (${_n(p['vencidosTotal']).toInt()})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
              ),
              const SizedBox(height: 6),
              if (vencidos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('No hay préstamos vencidos 🎉'),
                ),
              for (final f in vencidos) fila(f, Colors.red[700]!),
              const SizedBox(height: 10),
              Text(
                'Vencen en 3 días (${_n(p['porVencerTotal']).toInt()})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.orange),
              ),
              const SizedBox(height: 6),
              if (porVencer.isEmpty)
                const Text('Ninguno por vencer en los próximos 3 días.'),
              for (final f in porVencer) fila(f, Colors.orange[800]!),
            ],
          ),
        );
      },
    );
  }
}
