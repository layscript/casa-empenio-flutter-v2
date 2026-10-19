import 'dart:convert';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/selector_medio_pago.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Renovar un préstamo cobrando SOLO el interés del periodo.
/// El contrato, el número y el bien en garantía no cambian; el capital sigue
/// igual hasta liquidar; solo se corre la fecha de vencimiento.
class RenewInterestDialog extends StatefulWidget {
  const RenewInterestDialog({super.key, required this.prestamo});

  final LoansEntity prestamo;

  @override
  State<RenewInterestDialog> createState() => _RenewInterestDialogState();
}

class _RenewInterestDialogState extends State<RenewInterestDialog> {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: endPointPrincipal,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  late final TextEditingController _montoCtrl;
  late final TextEditingController _diasCtrl;
  final TextEditingController _obsCtrl = TextEditingController();
  String _medio = 'EFECTIVO';
  String? _banco;
  bool _medioCompleto = true;
  bool _enviando = false;
  String? _error;

  double get _capital => double.tryParse(widget.prestamo.monto ?? '0') ?? 0;
  double get _interesPeriodo {
    final i = (widget.prestamo.interes ?? 0).toDouble();
    return (_capital * i / 100 * 100).round() / 100;
  }

  int get _plazo => widget.prestamo.plazoDias ?? 30;

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(text: _interesPeriodo.toStringAsFixed(2));
    _diasCtrl = TextEditingController(text: _plazo.toString());
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _diasCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  DateTime? get _venceActual {
    final f = widget.prestamo.fechaPago;
    if (f == null) return null;
    return DateTime.tryParse(f)?.toLocal();
  }

  DateTime get _nuevoVence {
    final dias = int.tryParse(_diasCtrl.text.trim()) ?? _plazo;
    final ahora = DateTime.now();
    final actual = _venceActual;
    final base = (actual != null && actual.isAfter(ahora)) ? actual : ahora;
    return base.add(Duration(days: dias));
  }

  String _fecha(DateTime? d) {
    if (d == null) return '-';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(d.day)}/${dos(d.month)}/${d.year}';
  }

  Future<int?> _cajaId(int sucursalId) async {
    final r = await _dio.get<dynamic>('/finanza/caja/actual/$sucursalId');
    dynamic d = r.data;
    if (d is String) d = jsonDecode(d);
    final body = d is Map ? d['body'] : null;
    return body is Map ? (body['id'] as num?)?.toInt() : null;
  }

  Future<void> _renovar() async {
    final monto = double.tryParse(_montoCtrl.text.trim().replaceAll(',', '.'));
    if (monto == null || monto + 0.005 < _interesPeriodo) {
      setState(() => _error =
          'Para renovar se cobra como mínimo el interés: S/ ${_interesPeriodo.toStringAsFixed(2)}');
      return;
    }
    if (!_medioCompleto) {
      setState(() => _error = 'Elija el banco del depósito');
      return;
    }
    final dias = int.tryParse(_diasCtrl.text.trim());
    if (dias == null || dias <= 0) {
      setState(() => _error = 'Escriba los días del nuevo plazo');
      return;
    }
    final prefs = context.read<Preferences>();
    final user = prefs.token;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final sucursalId = user?.sucursal?.id ?? 1;
      final cajaId = await _cajaId(sucursalId);
      if (cajaId == null) {
        throw Exception('Abra la caja de hoy antes de renovar');
      }
      await _dio.post<dynamic>('/prestamos/pagos/renovar-intereses', data: {
        'prestamoId': widget.prestamo.codigo,
        'usuarioId': user?.id,
        'cajaId': cajaId,
        'medioPago': _medio,
        'banco': _banco,
        'monto': monto,
        'dias': dias,
        'observaciones': _obsCtrl.text.trim(),
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Préstamo renovado',
              style: TextStyle(color: Colors.green)),
          content: Text(
            'Se cobró S/ ${monto.toStringAsFixed(2)} de intereses.\n'
            'El capital sigue en S/ ${_capital.toStringAsFixed(2)}.\n'
            'Nuevo vencimiento: ${_fecha(_nuevoVence)}.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Aceptar')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      var msg = e.toString().replaceFirst('Exception: ', '');
      if (e is DioException) {
        final d = e.response?.data;
        try {
          final m = d is String ? jsonDecode(d) : d;
          if (m is Map && m['message'] != null) {
            msg = m['message'] is List
                ? (m['message'] as List).join(', ')
                : m['message'].toString();
          } else {
            msg = 'No se pudo conectar con el servidor';
          }
        } catch (_) {
          msg = 'No se pudo conectar con el servidor';
        }
      }
      if (mounted) {
        setState(() {
          _enviando = false;
          _error = msg;
        });
      }
    }
  }

  Widget _fila(String a, String b, {bool fuerte = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(a, style: const TextStyle(fontSize: 13))),
            Text(b,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: fuerte ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.prestamo;
    return AlertDialog(
      scrollable: true,
      title: const Text('Renovar (solo intereses)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fila('Contrato', p.codigoFormateado ?? '${p.codigo}', fuerte: true),
          _fila('Capital (no cambia)', 'S/ ${_capital.toStringAsFixed(2)}'),
          _fila('Interés del periodo (${p.interes ?? 0}%)',
              'S/ ${_interesPeriodo.toStringAsFixed(2)}'),
          _fila('Vence ahora', _fecha(_venceActual)),
          _fila('Nuevo vencimiento', _fecha(_nuevoVence), fuerte: true),
          const SizedBox(height: 4),
          const Text(
            'El contrato y el bien siguen igual; solo se corre la fecha. '
            'Si ya venció, el nuevo plazo cuenta desde hoy.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto de intereses a cobrar (S/)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _diasCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Días del nuevo plazo',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SelectorMedioPago(
            pregunta: '¿Cómo pagó el cliente?',
            ayudaEfectivo: 'Entra dinero a la caja (efectivo).',
            verbo: 'entró',
            alCambiar: (m, b, ok) {
              _medio = m;
              _banco = b;
              _medioCompleto = ok;
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _obsCtrl,
            decoration: const InputDecoration(
              labelText: 'Observación (opcional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _enviando ? null : _renovar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Renovar'),
        ),
      ],
    );
  }
}
