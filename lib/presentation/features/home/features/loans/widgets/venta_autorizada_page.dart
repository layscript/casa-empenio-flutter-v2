import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/sesion_segura.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final Dio _dio = crearDio(BaseOptions(
  baseUrl: endPointPrincipal,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(minutes: 2),
));

dynamic _cuerpo(Response<dynamic> r) {
  final d = r.data is String ? jsonDecode(r.data as String) : r.data;
  if (d is Map) return d['body'];
  throw 'El servidor todavía no tiene esta función (se está actualizando). Espera unos minutos y vuelve a intentar.';
}

String _err(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['message'] != null) return d['message'].toString();
    return 'No hay conexión con el servidor';
  }
  return e.toString();
}

Map<String, dynamic> _mapa(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
double _n(dynamic v) => double.tryParse('${v ?? ''}'.replaceAll(',', '.')) ?? 0;
String _s(double v) => 'S/ ${v.toStringAsFixed(2)}';

/// Venta con autorización del cliente: el cliente deja su prenda y nos autoriza a venderla.
/// Paso 1: se anota la autorización. Paso 2: se vende (se cobra la deuda, se cierra el préstamo y lo que sobra
/// queda para el cliente). Paso 3: se entrega el sobrante. Si el cliente se arrepiente, se anula.
class VentaAutorizadaPage extends StatefulWidget {
  const VentaAutorizadaPage({super.key, required this.prestamo, this.yaEstabaEnVenta = false});

  final LoansEntity prestamo;
  final bool yaEstabaEnVenta;

  @override
  State<VentaAutorizadaPage> createState() => _VentaAutorizadaPageState();
}

class _VentaAutorizadaPageState extends State<VentaAutorizadaPage> {
  Map<String, dynamic>? _aut;
  bool _cargando = true;
  bool _trabajando = false;
  String? _error;
  Map<String, dynamic>? _sim;

  final _nota = TextEditingController();
  final _pedido = TextEditingController();
  final _minimo = TextEditingController();
  final _comision = TextEditingController();
  bool _porcentaje = false;

  final _precio = TextEditingController();
  final _dni = TextEditingController();
  final _nombre = TextEditingController();
  final _domicilio = TextEditingController();
  final _motivo = TextEditingController();
  final _entrega = TextEditingController();
  String _medio = 'EFECTIVO';

  int get _codigo => widget.prestamo.codigo ?? 0;
  int get _uid => context.read<Preferences>().token?.id ?? 0;
  int get _sid => context.read<Preferences>().token?.sucursal?.id ?? 1;

  String get _estado => _aut == null ? 'NADA' : '${_aut!['estado']}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    for (final c in [_nota, _pedido, _minimo, _comision, _precio, _dni, _nombre, _domicilio, _motivo, _entrega]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await _dio.get<dynamic>('/almacen/venta-autorizada/prestamo/$_codigo');
      final b = _cuerpo(r);
      _aut = b == null ? null : _mapa(b);
      if (_estado == 'ACTIVA' && _precio.text.isEmpty && _n(_aut!['precioPedido']) > 0) {
        _precio.text = _n(_aut!['precioPedido']).toStringAsFixed(2);
      }
      if (_estado == 'VENDIDA') {
        _entrega.text = _n(_aut!['pendienteEntregar']).toStringAsFixed(2);
      }
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<bool> _post(String ruta, Map<String, dynamic> body, String ok) async {
    setState(() {
      _trabajando = true;
      _error = null;
    });
    try {
      await _dio.post<dynamic>(ruta, data: body);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      await _cargar();
      _sim = null;
      if (mounted) setState(() => _trabajando = false);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _trabajando = false;
          _error = _err(e);
        });
      }
      return false;
    }
  }

  Future<bool> _confirmar(String titulo, String texto, String boton) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(boton)),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _autorizar() async {
    if (_nota.text.trim().length < 5) {
      setState(() => _error = 'Escribe cómo autorizó el cliente (firmó, llamó, mandó WhatsApp...).');
      return;
    }
    final ok = await _confirmar(
      'Poner a la venta',
      'El cliente autorizó vender su bien. El préstamo quedará "A LA VENTA" y dejará de cobrar mora.\n\nSi después el cliente viene a recoger, podrás anular esta autorización.',
      'Sí, registrar',
    );
    if (!ok) return;
    await _post(
      '/almacen/venta-autorizada',
      {
        'prestamoCodigo': _codigo,
        'usuarioId': _uid,
        'sucursalId': _sid,
        'nota': _nota.text.trim(),
        if (_n(_pedido.text) > 0) 'precioPedido': _n(_pedido.text),
        if (_n(_minimo.text) > 0) 'precioMinimo': _n(_minimo.text),
        'comisionTipo': _porcentaje ? 'PORCENTAJE' : 'MONTO',
        'comisionValor': _n(_comision.text),
        if (widget.yaEstabaEnVenta) 'yaEstabaEnVenta': true,
      },
      'Autorización registrada. El bien está a la venta.',
    );
  }

  Future<void> _simular() async {
    final p = _n(_precio.text);
    if (p <= 0) {
      setState(() => _error = 'Escribe el precio de venta.');
      return;
    }
    setState(() {
      _trabajando = true;
      _error = null;
    });
    try {
      final r = await _dio.get<dynamic>('/almacen/venta-autorizada/${_aut!['id']}/simular', queryParameters: {'precio': p});
      _sim = _mapa(_cuerpo(r));
    } catch (e) {
      _error = _err(e);
    }
    if (mounted) setState(() => _trabajando = false);
  }

  Future<void> _vender() async {
    final p = _n(_precio.text);
    if (p <= 0) return setState(() => _error = 'Escribe el precio de venta.');
    if (_dni.text.trim().length < 6) return setState(() => _error = 'Escribe el DNI del comprador.');
    if (_nombre.text.trim().isEmpty) return setState(() => _error = 'Escribe el nombre del comprador.');
    await _simular();
    if (_sim == null || !mounted) return;
    final ok = await _confirmar('¿Vender y cerrar el préstamo?', '${_sim!['resumen']}\n\nEsto entra a la caja de hoy como una venta.', 'Sí, vender');
    if (!ok) return;
    final partes = _nombre.text.trim().split(RegExp(r'\s+'));
    await _post(
      '/almacen/venta-autorizada/${_aut!['id']}/vender',
      {
        'precio': p,
        'dni': _dni.text.trim(),
        'nombres': partes.first,
        'apellidos': partes.length > 1 ? partes.sublist(1).join(' ') : '-',
        'direccion': _domicilio.text.trim().isEmpty ? '-' : _domicilio.text.trim(),
        'usuarioId': _uid,
        'sucursalId': _sid,
        'medioPago': _medio,
        if (_motivo.text.trim().isNotEmpty) 'motivo': _motivo.text.trim(),
      },
      'Venta registrada. El préstamo quedó cerrado.',
    );
  }

  Future<void> _anular() async {
    if (_motivo.text.trim().length < 5) return setState(() => _error = 'Escribe el motivo (por ejemplo: el cliente vino a recoger).');
    final ok = await _confirmar('El cliente recoge su bien', 'Se anula la autorización y el préstamo vuelve a como estaba. Luego se cobra normal.', 'Sí, anular');
    if (!ok) return;
    final hecho = await _post('/almacen/venta-autorizada/${_aut!['id']}/anular', {'usuarioId': _uid, 'motivo': _motivo.text.trim()}, 'Autorización anulada. El préstamo volvió a cobrarse normal.');
    if (hecho && mounted) Navigator.pop(context, true);
  }

  Future<void> _entregar() async {
    final m = _n(_entrega.text);
    if (m <= 0) return setState(() => _error = 'Escribe el monto a entregar.');
    final ok = await _confirmar('Entregar sobrante', 'Saldrán ${_s(m)} de la caja de hoy y quedará registrado.\n\nPide al cliente que firme o deje constancia de que recibió.', 'Sí, entregar');
    if (!ok) return;
    await _post('/almacen/venta-autorizada/${_aut!['id']}/entregar-excedente', {'usuarioId': _uid, 'sucursalId': _sid, 'monto': m, 'medioPago': _medio}, 'Sobrante entregado y registrado en caja.');
  }

  Widget _campo(TextEditingController c, String t, {TextInputType? tipo, int lineas = 1, String? ayuda}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: tipo,
          maxLines: lineas,
          decoration: InputDecoration(labelText: t, helperText: ayuda, helperMaxLines: 3, border: const OutlineInputBorder(), isDense: true),
        ),
      );

  Widget _titulo(String t) => Padding(padding: const EdgeInsets.only(top: 6, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _caja(String t, {Color? color}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: (color ?? Colors.blue).withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
        child: Text(t),
      );

  Widget _medios() => Wrap(
        spacing: 8,
        children: [
          for (final m in const ['EFECTIVO', 'YAPE', 'PLIN', 'DEPOSITO'])
            ChoiceChip(label: Text(m), selected: _medio == m, onSelected: (_) => setState(() => _medio = m)),
        ],
      );

  Widget _formAutorizar() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _caja('El cliente nos autoriza a vender su bien. Aquí se anota quién autorizó, el precio mínimo y la comisión. Al vender, el sistema cobra la deuda con ese dinero y calcula lo que le toca al cliente.'),
          _titulo('1. ¿Cómo autorizó el cliente?'),
          _campo(_nota, 'Autorización (firmó, llamó, WhatsApp...)', lineas: 2, ayuda: 'Es obligatorio: queda como constancia.'),
          _titulo('2. Precios (opcional)'),
          _campo(_pedido, 'Precio que se pide (S/)', tipo: TextInputType.number),
          _campo(_minimo, 'Precio mínimo que aceptó el cliente (S/)', tipo: TextInputType.number, ayuda: 'Si se vende más barato, solo el administrador podrá autorizarlo.'),
          _titulo('3. Comisión de la casa por vender'),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('Monto fijo (S/)'), selected: !_porcentaje, onSelected: (_) => setState(() => _porcentaje = false)),
            ChoiceChip(label: const Text('% del precio'), selected: _porcentaje, onSelected: (_) => setState(() => _porcentaje = true)),
          ]),
          const SizedBox(height: 8),
          _campo(_comision, _porcentaje ? 'Porcentaje (ej. 10)' : 'Monto (S/)', tipo: TextInputType.number, ayuda: 'Déjalo vacío si no se cobra comisión.'),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            onPressed: _trabajando ? null : _autorizar,
            icon: const Icon(Icons.verified_user),
            label: const Text('Registrar autorización y poner a la venta'),
          ),
        ],
      );

  Widget _activa() {
    final a = _aut!;
    final min = _n(a['precioMinimo']);
    final tipo = '${a['comisionTipo']}' == 'PORCENTAJE';
    final com = _n(a['comisionValor']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _caja('Autorizó: ${a['nota']}\n'
            '${min > 0 ? 'Precio mínimo: ${_s(min)}\n' : ''}'
            'Comisión: ${com <= 0 ? 'ninguna' : tipo ? '${com.toStringAsFixed(0)}% del precio' : _s(com)}'),
        _titulo('Vender ahora'),
        _campo(_precio, 'Precio de venta (S/)', tipo: TextInputType.number),
        _campo(_dni, 'DNI del comprador', tipo: TextInputType.number),
        _campo(_nombre, 'Nombre completo del comprador'),
        _campo(_domicilio, 'Domicilio del comprador (opcional)'),
        const Text('¿Cómo pagó el comprador?'),
        const SizedBox(height: 4),
        _medios(),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: _trabajando ? null : _simular, icon: const Icon(Icons.calculate), label: const Text('Ver cuánto sale para la casa y el cliente')),
        if (_sim != null) ...[
          const SizedBox(height: 10),
          _caja(
            '${_sim!['resumen']}',
            color: _sim!['cubreDeuda'] == true ? Colors.green : Colors.orange,
          ),
          if (min > 0 && _n(_sim!['precio']) < min) _caja('Está por debajo del mínimo del cliente. Solo el administrador puede vender así y debe escribir el motivo abajo.', color: Colors.orange),
        ],
        _campo(_motivo, 'Motivo (si vendes bajo el mínimo, o si el cliente recoge)', lineas: 2),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
          onPressed: _trabajando ? null : _vender,
          icon: const Icon(Icons.sell),
          label: const Text('Vender y cerrar el préstamo'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _trabajando ? null : _anular,
          icon: const Icon(Icons.handshake),
          label: const Text('El cliente recoge su bien (anular autorización)'),
        ),
      ],
    );
  }

  Widget _vendida() {
    final a = _aut!;
    final pend = _n(a['pendienteEntregar']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _caja(
          'Vendido en ${_s(_n(a['precioVenta']))}\n'
          'Deuda cobrada: ${_s(_n(a['deuda']))}\n'
          'Comisión de la casa: ${_s(_n(a['comision']))}\n'
          'Le toca al cliente: ${_s(_n(a['excedente']))} (ya entregado: ${_s(_n(a['excedenteEntregado']))})'
          '${_n(a['faltante']) > 0 ? '\nFaltó para la deuda: ${_s(_n(a['faltante']))} (pérdida de la casa)' : ''}',
          color: Colors.green,
        ),
        if (pend > 0) ...[
          _titulo('Entregar el sobrante al cliente'),
          _campo(_entrega, 'Monto a entregar (S/)', tipo: TextInputType.number, ayuda: 'Pendiente: ${_s(pend)}. Puedes entregar una parte ahora y el resto después.'),
          _medios(),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _trabajando ? null : _entregar,
            icon: const Icon(Icons.payments),
            label: const Text('Entregar sobrante (sale de la caja)'),
          ),
        ] else
          const Text('Al cliente no le queda nada pendiente. Todo está al día.', style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Venta con autorización · N° ${widget.prestamo.codigoFormateado ?? widget.prestamo.codigo}')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) _caja(_error!, color: Colors.red),
                if (_estado == 'ACTIVA')
                  _activa()
                else if (_estado == 'VENDIDA')
                  _vendida()
                else
                  _formAutorizar(),
                if (_trabajando) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
              ],
            ),
    );
  }
}
