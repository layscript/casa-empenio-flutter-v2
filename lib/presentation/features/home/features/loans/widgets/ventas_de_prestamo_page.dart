import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/contrato_compraventa.dart';
import 'package:casa_empenio_pe/presentation/app/utils/expediente_page.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/contrato_venta_firma_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// "¿A quién se vendió?": comprador, fecha, precio, documento y contrato firmado
/// del bien de un préstamo.
class VentasDePrestamoPage extends StatefulWidget {
  const VentasDePrestamoPage({super.key, required this.prestamo});

  final LoansEntity prestamo;

  @override
  State<VentasDePrestamoPage> createState() => _VentasDePrestamoPageState();
}

class _VentasDePrestamoPageState extends State<VentasDePrestamoPage> {
  bool _cargando = true;
  List<Map<String, dynamic>> _ventas = [];
  List<Map<String, dynamic>> _contratos = [];
  bool _abriendo = false;

  int get _codigo => widget.prestamo.codigo ?? 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final repo = context.read<SalesRepository>();
    final v = await repo.ventasDePrestamo(_codigo);
    final c = await repo.contratosDePrestamo(_codigo);
    if (!mounted) return;
    setState(() {
      _ventas = v;
      _contratos = c;
      _cargando = false;
    });
  }

  Map<String, dynamic>? _contratoDe(int ventaId) {
    for (final c in _contratos) {
      if ((c['ventaId'] as num?)?.toInt() == ventaId) return c;
    }
    return null;
  }

  Future<void> _verPdf(String ruta, String titulo) async {
    setState(() => _abriendo = true);
    try {
      final r = await Dio().get<List<int>>(
        '$endPointPrincipal/$ruta',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(r.data ?? <int>[]);
      if (bytes.isEmpty) throw 'vacío';
      if (!mounted) return;
      abrirVistaPdf(context,
          titulo: titulo, archivo: 'Contrato_venta.pdf', build: () async => bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el contrato')));
      }
    }
    if (mounted) setState(() => _abriendo = false);
  }

  /// Venta con contrato privado que quedó sin firma/huella: se completa aquí.
  Future<void> _completarContrato(Map<String, dynamic> venta) async {
    final cli = Map<String, dynamic>.from((venta['cliente'] as Map?) ?? {});
    final bienes = widget.prestamo.bienesGarantia ?? [];
    final b = bienes.isNotEmpty ? bienes.first : null;
    final vehiculo = (b?.motor ?? '').isNotEmpty || (b?.placa ?? '').isNotEmpty;
    final datos = DatosContrato(
      empresaCompra: false,
      esVehiculo: vehiculo,
      nombre: '${cli['nombres'] ?? ''} ${cli['apellidos'] ?? ''}'.trim(),
      dni: '${cli['dni'] ?? ''}',
      domicilio: '${cli['domicilio'] ?? ''}',
      descripcion: bienes.map((e) => e.description ?? '').where((e) => e.isNotEmpty).join(' + '),
      marca: b?.marca ?? '',
      modelo: b?.modelo ?? '',
      color: b?.color ?? '',
      serie: b?.serie ?? '',
      placa: b?.placa ?? '',
      motor: b?.motor ?? '',
      carroceria: b?.carroceria ?? '',
      anio: b?.anio?.toString() ?? '',
      clase: 'Vehículo menor',
      estado: b?.estado ?? '',
      precio: double.tryParse('${venta['total']}') ?? 0,
      ciudad: 'Atalaya',
      fecha: DateTime.tryParse('${venta['fecha']}')?.toLocal() ?? DateTime.now(),
    );
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ContratoVentaFirmaPage(
          datos: datos,
          payloadVenta: const {},
          prestamoCodigo: _codigo,
          ventaIdExistente: (venta['id'] as num).toInt(),
        ),
      ),
    );
    if (ok == true) {
      setState(() => _cargando = true);
      await _cargar();
    }
  }

  String _docNombre(String? d) {
    switch (d) {
      case 'CONTRATO_PRIVADO':
        return 'Contrato privado';
      case 'BOLETA':
        return 'Boleta';
      case 'PROFORMA':
        return 'Proforma';
      default:
        return 'Venta normal';
    }
  }

  Widget _tarjeta(Map<String, dynamic> v) {
    final cli = Map<String, dynamic>.from((v['cliente'] as Map?) ?? {});
    final usu = Map<String, dynamic>.from((v['usuario'] as Map?) ?? {});
    final fecha = DateTime.tryParse('${v['fecha']}')?.toLocal();
    final total = double.tryParse('${v['total']}') ?? 0;
    final id = (v['id'] as num?)?.toInt() ?? 0;
    final contrato = _contratoDe(id);
    final esContrato = v['documento'] == 'CONTRATO_PRIVADO';
    final quien = '${usu['nombres'] ?? usu['nombre'] ?? usu['usuario'] ?? ''}'.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cli['nombres'] ?? ''} ${cli['apellidos'] ?? ''}'.trim().toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('DNI: ${cli['dni'] ?? '-'}'),
            if ('${cli['domicilio'] ?? ''}'.isNotEmpty && cli['domicilio'] != '-')
              Text('Domicilio: ${cli['domicilio']}'),
            const Divider(),
            Text('Venta N° $id · ${_docNombre(v['documento'] as String?)}'),
            Text('Precio: S/. ${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (fecha != null)
              Text('Fecha: ${DateFormat('dd/MM/yyyy · hh:mm a').format(fecha)}'),
            if (quien.isNotEmpty) Text('Atendió: $quien'),
            if (esContrato) ...[
              const SizedBox(height: 8),
              if (contrato != null) ...[
                Row(children: const [
                  Icon(Icons.verified, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Contrato firmado con firma y huella',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: _abriendo ? null : () => _verPdf('${contrato['pdf']}', 'Contrato firmado'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Ver contrato firmado'),
                ),
              ] else ...[
                Row(children: const [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Falta la firma y la huella del comprador',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: () => _completarContrato(v),
                  icon: const Icon(Icons.draw),
                  label: const Text('Firmar contrato ahora'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prestamo;
    return Scaffold(
      appBar: AppBar(title: const Text('¿A quién se vendió?')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
              children: [
                Text('Préstamo N° ${p.codigoFormateado ?? p.codigo}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                for (final b in p.bienesGarantia ?? <WarrantyEntity>[])
                  Text('• ${b.description ?? ''}'),
                const SizedBox(height: 10),
                if (_ventas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Todavía no hay una venta registrada para este bien.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final v in _ventas) _tarjeta(v),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ExpedientePage(prestamoCodigo: _codigo),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Ver expediente completo del préstamo'),
                ),
              ],
            ),
    );
  }
}
