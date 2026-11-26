import 'dart:async';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/sesion_segura.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ---------------------------------------------------------------------------
// Recordatorio de fin de mes: facturas de compra/gastos, facturas emitidas (desde el 26, bloquean el cierre de caja)
// y recibos por honorarios (desde el 25). Rutas /recordatorios del servidor.
// ---------------------------------------------------------------------------

Dio _crearDio() => crearDio(
      BaseOptions(
        baseUrl: endPointPrincipal,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

Future<Map<String, dynamic>?> _cargarEstado(int sucursalId) async {
  final r = await _crearDio().get<dynamic>('/recordatorios/facturas', queryParameters: {'sucursalId': sucursalId});
  final d = r.data;
  if (d is Map && d['body'] is Map) return Map<String, dynamic>.from(d['body'] as Map);
  return null;
}

String _error(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return e.message ?? 'Error de conexión';
  }
  return e.toString();
}

/// Cartel del inicio: lo que falta verificar este mes. Si hay pendientes, también lo recuerda con un aviso.
class AvisoFacturasMes extends StatefulWidget {
  const AvisoFacturasMes({super.key});

  @override
  State<AvisoFacturasMes> createState() => _AvisoFacturasMesState();
}

class _AvisoFacturasMesState extends State<AvisoFacturasMes> {
  int _bloquean = 0;
  int _honorarios = 0;
  int _dias = 0;
  Timer? _timer;
  bool _dialogoAbierto = false;
  static DateTime? _ultimoRecordatorio;

  @override
  void initState() {
    super.initState();
    _cargar(recordar: true);
    _timer = Timer.periodic(const Duration(minutes: 20), (_) => _cargar(recordar: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool recordar = false}) async {
    try {
      final sid = context.read<Preferences>().token?.sucursal?.id ?? 1;
      final e = await _cargarEstado(sid);
      if (e == null || !mounted) return;
      final b = (e['pendientes'] as num?)?.toInt() ?? 0;
      final h = (e['pendientesHonorarios'] as num?)?.toInt() ?? 0;
      setState(() {
        _bloquean = b;
        _honorarios = h;
        _dias = (e['diasHastaFinDeMes'] as num?)?.toInt() ?? 0;
      });
      final hace = _ultimoRecordatorio == null ? 999 : DateTime.now().difference(_ultimoRecordatorio!).inMinutes;
      if (recordar && (b + h) > 0 && !_dialogoAbierto && hace >= 60) await _recordar();
    } catch (_) {}
  }

  Future<void> _abrir() async {
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(builder: (_) => const FacturasMesPage()));
    if (mounted) _cargar();
  }

  Future<void> _recordar() async {
    _ultimoRecordatorio = DateTime.now();
    _dialogoAbierto = true;
    final urgente = _dias <= 1;
    final ir = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (c) => AlertDialog(
        icon: Icon(Icons.receipt_long, color: urgente ? Colors.red : Colors.orange, size: 40),
        title: Text(urgente ? 'ÚLTIMO MOMENTO: facturas y recibos' : 'Facturas y recibos del mes'),
        content: Text(
          '${_dias == 0 ? 'HOY es el último día del mes. ' : 'Quedan $_dias día(s) del mes. '}'
          '${_bloquean > 0 ? 'Falta verificar $_bloquean punto(s) de facturas: sin esto NO podrás cerrar la caja. ' : ''}'
          '${_honorarios > 0 ? 'Faltan recibos por honorarios de $_honorarios trabajador(es). ' : ''}'
          'Después del 31 ya no se puede emitir ni pedir facturas a los proveedores.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Más tarde')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Revisar ahora')),
        ],
      ),
    );
    _dialogoAbierto = false;
    if (ir == true && mounted) await _abrir();
  }

  @override
  Widget build(BuildContext context) {
    final n = _bloquean + _honorarios;
    if (n == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: _dias <= 1 ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dias <= 1 ? Colors.red.shade300 : Colors.orange.shade300),
      ),
      child: ListTile(
        leading: Icon(Icons.receipt_long, color: _dias <= 1 ? Colors.red : Colors.orange.shade800),
        title: Text('Facturas y recibos del mes: faltan $n', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(
          '${_dias == 0 ? 'Hoy es el último día. ' : 'Quedan $_dias día(s). '}${_bloquean > 0 ? 'Sin esto no se cierra la caja.' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _abrir,
      ),
    );
  }
}

class FacturasMesPage extends StatefulWidget {
  const FacturasMesPage({super.key});

  @override
  State<FacturasMesPage> createState() => _FacturasMesPageState();
}

class _FacturasMesPageState extends State<FacturasMesPage> {
  Map<String, dynamic>? _e;
  String? _error_;
  bool _trabajando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  int get _sid => context.read<Preferences>().token?.sucursal?.id ?? 1;

  Future<void> _cargar() async {
    try {
      final e = await _cargarEstado(_sid);
      if (mounted) setState(() => _e = e);
    } catch (e) {
      if (mounted) setState(() => _error_ = _error(e));
    }
  }

  Future<void> _resolver(String tipo, String titulo, {bool conNota = true}) async {
    final nota = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Ya está resuelto?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Confirma solo si ya lo verificaste de verdad. Queda registrado con tu nombre.', style: TextStyle(fontSize: 13)),
          if (conNota) ...[
            const SizedBox(height: 10),
            TextField(controller: nota, maxLength: 300, decoration: const InputDecoration(labelText: 'Nota (opcional)', hintText: 'Ej: faltaba la factura de luz, ya se pidió')),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Todavía no')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, ya está resuelto')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _trabajando = true);
    try {
      final uid = context.read<Preferences>().token?.id ?? 0;
      await _crearDio().post<dynamic>('/recordatorios/facturas/resolver', data: {'sucursalId': _sid, 'tipo': tipo, 'usuarioId': uid, 'nota': nota.text.trim()});
      await _cargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error(e))));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Widget _tarjeta({required String titulo, required String detalle, required bool resuelto, String? quien, required VoidCallback onSi, bool bloquea = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(resuelto ? Icons.check_circle : Icons.pending_actions, color: resuelto ? Colors.green : Colors.orange.shade800),
            const SizedBox(width: 8),
            Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          ]),
          const SizedBox(height: 6),
          Text(detalle, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          if (resuelto)
            Text('Resuelto${quien != null && quien.isNotEmpty ? ' por $quien' : ''}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600))
          else ...[
            if (bloquea) Text('Sin esto no se puede cerrar la caja.', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _trabajando ? null : onSi, child: const Text('Sí, ya está resuelto'))),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = _e;
    final items = (e?['items'] as List?)?.cast<Map>() ?? const [];
    final hon = (e?['honorarios'] as List?)?.cast<Map>() ?? const [];
    final activo = e?['activo'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Facturas del mes')),
      body: e == null
          ? Center(child: _error_ != null ? Padding(padding: const EdgeInsets.all(24), child: Text(_error_!)) : const CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(padding: const EdgeInsets.all(14), children: [
                Text('Periodo ${e['periodo']} · quedan ${e['diasHastaFinDeMes']} día(s) del mes', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Después del último día del mes ya no se puede emitir ni pedir facturas. La boleta no sirve: se necesita factura.', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 10),
                if (!activo) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Las facturas se verifican desde el día 26.', style: TextStyle(fontSize: 13))),
                if (activo)
                  for (final i in items)
                    _tarjeta(
                      titulo: '${i['titulo']}',
                      detalle: '${i['detalle']}',
                      resuelto: i['resuelto'] == true,
                      quien: i['resueltoPor'] as String?,
                      bloquea: true,
                      onSi: () => _resolver('${i['tipo']}', '${i['titulo']}'),
                    ),
                if (hon.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('${e['tituloHonorarios']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('${e['detalleHonorarios']}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  for (final h in hon)
                    Card(
                      child: ListTile(
                        leading: Icon(h['resuelto'] == true ? Icons.check_circle : Icons.pending_actions, color: h['resuelto'] == true ? Colors.green : Colors.orange.shade800),
                        title: Text('${h['trabajador']}'),
                        subtitle: Text(h['resuelto'] == true ? 'Emitido (${h['resueltoPor'] ?? ''})' : 'Falta emitir el recibo por honorarios'),
                        trailing: h['resuelto'] == true
                            ? null
                            : TextButton(onPressed: _trabajando ? null : () => _resolver('${h['tipo']}', 'Recibo por honorarios de ${h['trabajador']}', conNota: false), child: const Text('Ya emitido')),
                      ),
                    ),
                ],
                if (activo && items.every((i) => i['resuelto'] == true) && hon.every((h) => h['resuelto'] == true))
                  const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: Text('Todo verificado este mes. ¡Gracias!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700)))),
              ]),
            ),
    );
  }
}
