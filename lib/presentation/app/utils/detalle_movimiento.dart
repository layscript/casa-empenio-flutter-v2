import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/full_screen_image.dart';
import 'package:dio/dio.dart';
import 'package:casa_empenio_pe/presentation/app/utils/sesion_segura.dart';
import 'package:flutter/material.dart';

/// Pantalla a la que se llega al tocar un aviso de movimiento: la operación completa y sus capturas.
class DetalleMovimientoPage extends StatefulWidget {
  const DetalleMovimientoPage({super.key, required this.movimientoId, required this.usuarioId});
  final int movimientoId;
  final int usuarioId;

  @override
  State<DetalleMovimientoPage> createState() => _DetalleMovimientoPageState();
}

class _DetalleMovimientoPageState extends State<DetalleMovimientoPage> {
  Map<String, dynamic>? _d;
  String? _error;
  bool _cargando = true;

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
      final dio = crearDio(BaseOptions(baseUrl: endPointPrincipal, connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 15)));
      final r = await dio.get('/finanza/movimiento/detalle/${widget.movimientoId}', queryParameters: {'usuarioId': widget.usuarioId});
      final data = r.data is String ? jsonDecode(r.data as String) : r.data;
      final b = (data is Map ? data['body'] : null) as Map?;
      if (b == null) throw 'sin datos';
      if (!mounted) return;
      setState(() {
        _d = Map<String, dynamic>.from(b);
        _cargando = false;
      });
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? '${(e.response!.data as Map)['message'] ?? ''}' : '';
      if (!mounted) return;
      setState(() {
        _error = msg.isNotEmpty ? msg : 'No se pudo abrir la operación. Revisa la conexión.';
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo abrir la operación.';
        _cargando = false;
      });
    }
  }

  static String _soles(num n) => 'S/ ${n.toStringAsFixed(2)}';

  /// Fecha y hora de Lima (UTC-5) a partir de la hora del servidor.
  static String _fecha(dynamic f) {
    final d = DateTime.tryParse('$f');
    if (d == null) return '';
    final l = d.toUtc().subtract(const Duration(hours: 5));
    String dos(int x) => x.toString().padLeft(2, '0');
    return '${dos(l.day)}/${dos(l.month)}/${l.year}  ${dos(l.hour)}:${dos(l.minute)}';
  }

  static const _clases = {
    'PAGO': 'Pago de préstamo',
    'VENTA': 'Venta',
    'INGRESO': 'Ingreso',
    'PRESTAMO': 'Préstamo entregado',
    'AUMENTO': 'Aumento de préstamo',
    'COMPRA': 'Compra',
    'GASTO': 'Gasto',
    'ANULACION': 'Movimiento anulado',
  };

  Widget _fila(String k, String v) => v.trim().isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 118, child: Text(k, style: const TextStyle(color: Colors.black54))),
            Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      appBar: AppBar(title: const Text('Operación')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
                    ]),
                  ),
                )
              : _contenido(d!),
    );
  }

  Widget _contenido(Map<String, dynamic> d) {
    final suma = d['suma'] == true;
    final monto = (d['monto'] as num?) ?? 0;
    final medio = '${d['medioPago'] ?? ''}';
    final banco = '${d['banco'] ?? ''}';
    final fotos = ((d['fotos'] as List?) ?? []).map((e) => '$e').where((e) => e.isNotEmpty).toList();
    final anulado = d['anulado'] == true;
    final interes = d['interesMonto'] as num?;
    final capital = d['capitalMonto'] as num?;
    final color = suma ? Colors.green.shade700 : Colors.red.shade700;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (anulado)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
          child: Text('ANULADO${'${d['motivoAnulacion'] ?? ''}'.isNotEmpty ? ': ${d['motivoAnulacion']}' : ''}', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
        ),
      Text(_clases['${d['clase']}'] ?? '${d['tipo']}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
      Text('${suma ? '+' : '−'} ${_soles(monto)}', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 8),
      _fila('Medio de pago', medio == 'DEPOSITO' && banco.isNotEmpty ? 'DEPÓSITO · $banco' : medio),
      _fila('Cliente', '${d['cliente'] ?? ''}'),
      _fila('DNI', '${d['dni'] ?? ''}'),
      _fila('Préstamo', '${d['prestamoCodigo'] ?? ''}'),
      if (interes != null && capital != null && (interes > 0 || capital > 0)) _fila('Interés / capital', '${_soles(interes)}  /  ${_soles(capital)}'),
      _fila('Sucursal', '${d['sucursal'] ?? ''}'),
      _fila('Registrado por', '${d['usuario'] ?? ''}'),
      _fila('Fecha y hora', _fecha(d['fecha'])),
      _fila('Detalle', '${d['observaciones'] ?? ''}'),
      if (fotos.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(fotos.length > 1 ? 'Capturas del pago (${fotos.length})' : 'Captura del pago', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final f in fotos)
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageUrl: f, galeria: fotos, titulo: 'Captura'))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: '$endPointPrincipal/$f',
                  width: 110,
                  height: 140,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(width: 110, height: 140, color: Colors.black12, child: const Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
        ]),
      ],
    ]);
  }
}
