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

  Map<String, dynamic>? _contratoDe(int ventaId, [String tipo = 'VENTA']) {
    for (final c in _contratos) {
      if ((c['ventaId'] as num?)?.toInt() == ventaId &&
          (c['tipo'] ?? 'VENTA') == tipo) {
        return c;
      }
    }
    return null;
  }

  Future<Uint8List?> _bajar(String ruta) async {
    try {
      final r = await Dio().get<List<int>>(
        '$endPointPrincipal/$ruta',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(r.data ?? <int>[]);
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _imprimir(String ruta, String nombre) async {
    setState(() => _abriendo = true);
    final b = await _bajar(ruta);
    if (mounted) setState(() => _abriendo = false);
    if (b == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el documento')));
      }
      return;
    }
    await imprimirPdf(b, nombre);
  }

  DatosContrato _datosDe(Map<String, dynamic> venta, {bool cancelacion = false}) {
    final cli = Map<String, dynamic>.from((venta['cliente'] as Map?) ?? {});
    final bienes = widget.prestamo.bienesGarantia ?? [];
    final b = bienes.isNotEmpty ? bienes.first : null;
    final vehiculo = (b?.motor ?? '').isNotEmpty || (b?.placa ?? '').isNotEmpty;
    final adel = double.tryParse('${venta['adelanto']}');
    final lim = DateTime.tryParse('${venta['fechaLimite']}');
    return DatosContrato(
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
      fecha: cancelacion
          ? DateTime.now()
          : (DateTime.tryParse('${venta['fecha']}')?.toLocal() ?? DateTime.now()),
      adelanto: adel,
      fechaLimite: lim,
      cocheraDia: double.tryParse('${venta['cocheraDia']}'),
    );
  }

  /// El cliente vuelve a cancelar el saldo: cobra, firma la constancia y se entrega.
  Future<void> _cancelarSaldo(Map<String, dynamic> venta, {bool yaCobrado = false}) async {
    double recargo = 0;
    if (!yaCobrado) {
      // Si pasó el plazo y se pactó cochera por día, se sugiere el cobro adicional.
      final lim = DateTime.tryParse('${venta['fechaLimite']}');
      final porDia = double.tryParse('${venta['cocheraDia']}') ?? 0;
      var sugerido = 0.0;
      var dias = 0;
      if (lim != null) {
        final hoy = DateTime.now();
        dias = DateTime(hoy.year, hoy.month, hoy.day)
            .difference(DateTime(lim.year, lim.month, lim.day))
            .inDays;
        if (dias > 0 && porDia > 0) sugerido = dias * porDia;
      }
      final r = await _pedirNumero(
        titulo: 'Cobro por cochera y cuidado',
        texto: dias > 0
            ? 'El cliente se pasó $dias día(s) del plazo.'
                '${porDia > 0 ? ' A S/. ${porDia.toStringAsFixed(2)} por día serían S/. ${sugerido.toStringAsFixed(2)}.' : ''}\n'
                'Puede cobrar este monto adicional (déjelo en 0 si no cobra).'
            : 'Cobro adicional por cochera y cuidado (déjelo en 0 si no corresponde).',
        inicial: sugerido,
        etiqueta: 'Cobro adicional S/.',
      );
      if (r == null) return;
      recargo = r;
    }
    if (!mounted) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ContratoVentaFirmaPage(
          datos: _datosDe(venta, cancelacion: true),
          payloadVenta: const {},
          prestamoCodigo: _codigo,
          ventaIdExistente: (venta['id'] as num).toInt(),
          cancelacion: true,
          saldoYaCobrado: yaCobrado,
          recargo: recargo,
          fechaContrato: DateTime.tryParse('${venta['fecha']}')?.toLocal(),
        ),
      ),
    );
    if (ok == true) {
      setState(() => _cargando = true);
      await _cargar();
    }
  }

  Future<double?> _pedirNumero({
    required String titulo,
    required String texto,
    required double inicial,
    required String etiqueta,
  }) {
    final c = TextEditingController(text: inicial > 0 ? inicial.toStringAsFixed(2) : '0');
    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(texto),
            const SizedBox(height: 10),
            TextField(
              controller: c,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: etiqueta, prefixText: 'S/. '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, double.tryParse(c.text.replaceAll(',', '.')) ?? 0),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  /// El cliente se arrepintió: se le devuelve el adelanto (menos lo que se retenga).
  Future<void> _desistir(Map<String, dynamic> venta) async {
    final adel = double.tryParse('${venta['adelanto']}') ?? 0;
    final retC = TextEditingController(text: '0');
    final motC = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final ret = double.tryParse(retC.text.replaceAll(',', '.')) ?? 0;
          final dev = adel - ret;
          final mal = ret < 0 || ret > adel;
          return AlertDialog(
            title: const Text('El cliente desistió'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adelanto recibido: S/. ${adel.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'No se borra nada de la caja: el adelanto queda registrado y la devolución sale como un egreso de hoy. El bien vuelve a quedar a la venta.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: retC,
                    onChanged: (_) => setD(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto que la empresa retiene',
                      helperText: 'Cochera, cuidado, etc. (0 = devolver todo)',
                      prefixText: 'S/. ',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: motC,
                    decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    mal ? 'El monto retenido no puede ser mayor al adelanto' : 'A devolver al cliente: S/. ${dev.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: mal ? Colors.red : Colors.green[800]),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
              ElevatedButton(
                onPressed: mal ? null : () => Navigator.pop(ctx, true),
                child: const Text('Continuar a firmar'),
              ),
            ],
          );
        },
      ),
    );
    if (res != true || !mounted) return;
    final retener = double.tryParse(retC.text.replaceAll(',', '.')) ?? 0;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ContratoVentaFirmaPage(
          datos: _datosDe(venta, cancelacion: true),
          payloadVenta: const {},
          prestamoCodigo: _codigo,
          ventaIdExistente: (venta['id'] as num).toInt(),
          desistimiento: true,
          retener: retener,
          motivo: motC.text,
          fechaContrato: DateTime.tryParse('${venta['fecha']}')?.toLocal(),
        ),
      ),
    );
    if (ok == true) {
      setState(() => _cargando = true);
      await _cargar();
    }
  }

  Widget _docBotones(Map<String, dynamic> c, String titulo, String nombre) {
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: _abriendo ? null : () => _imprimir('${c['pdf']}', nombre),
          icon: const Icon(Icons.print),
          label: const Text('Imprimir'),
        ),
        OutlinedButton.icon(
          onPressed: _abriendo ? null : () => _verPdf('${c['pdf']}', titulo),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Ver'),
        ),
      ],
    );
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
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ContratoVentaFirmaPage(
          datos: _datosDe(venta),
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
    final constancia = _contratoDe(id, 'CANCELACION');
    final esContrato = v['documento'] == 'CONTRATO_PRIVADO';
    final estadoPago = '${v['estadoPago'] ?? 'TOTAL'}';
    final parcial = estadoPago == 'PARCIAL';
    final cancelado = estadoPago == 'CANCELADO';
    final desistido = estadoPago == 'DESISTIDO';
    final desistimiento = _contratoDe(id, 'DESISTIMIENTO');
    final adel = double.tryParse('${v['adelanto']}');
    final saldo = double.tryParse('${v['saldo']}');
    final limite = DateTime.tryParse('${v['fechaLimite']}');
    final vencidoLimite = parcial &&
        limite != null &&
        DateTime.now().isAfter(DateTime(limite.year, limite.month, limite.day, 23, 59));
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
            if (desistido) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                child: Text(
                  'DESISTIDA · el cliente se arrepintió. Adelanto S/. ${(adel ?? 0).toStringAsFixed(2)} · '
                  'devuelto S/. ${(double.tryParse('${v['montoDevuelto']}') ?? 0).toStringAsFixed(2)}'
                  '${(double.tryParse('${v['montoRetenido']}') ?? 0) > 0 ? ' · retenido S/. ${(double.tryParse('${v['montoRetenido']}') ?? 0).toStringAsFixed(2)}' : ''}'
                  '${'${v['motivoDesistimiento'] ?? ''}'.isNotEmpty && v['motivoDesistimiento'] != null ? '\nMotivo: ${v['motivoDesistimiento']}' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (desistimiento != null) ...[
                const SizedBox(height: 6),
                _docBotones(desistimiento, 'Constancia de desistimiento', 'Desistimiento_venta_$id'),
              ] else ...[
                const SizedBox(height: 6),
                const Text('La devolución está registrada en caja pero falta guardar la constancia firmada.',
                    style: TextStyle(color: Colors.orange)),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => ContratoVentaFirmaPage(
                          datos: _datosDe(v, cancelacion: true),
                          payloadVenta: const {},
                          prestamoCodigo: _codigo,
                          ventaIdExistente: id,
                          desistimiento: true,
                          saldoYaCobrado: true,
                          retener: double.tryParse('${v['montoRetenido']}') ?? 0,
                          motivo: '${v['motivoDesistimiento'] ?? ''}',
                          fechaContrato: DateTime.tryParse('${v['fecha']}')?.toLocal(),
                        ),
                      ),
                    );
                    if (ok == true) {
                      setState(() => _cargando = true);
                      await _cargar();
                    }
                  },
                  icon: const Icon(Icons.draw),
                  label: const Text('Firmar constancia de desistimiento'),
                ),
              ],
            ],
            if (parcial || cancelado) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cancelado ? Colors.green[50] : (vencidoLimite ? Colors.red[50] : Colors.orange[50]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cancelado
                      ? 'PAGO COMPLETO · adelanto S/. ${(adel ?? 0).toStringAsFixed(2)} + saldo cancelado'
                          '${v['fechaCancelacion'] != null ? ' el ${DateFormat('dd/MM/yyyy').format(DateTime.parse('${v['fechaCancelacion']}').toLocal())}' : ''}'
                      : 'PAGO PARCIAL · adelanto S/. ${(adel ?? 0).toStringAsFixed(2)} · falta S/. ${(saldo ?? 0).toStringAsFixed(2)}'
                          '${limite != null ? '\nCancela hasta el ${DateFormat('dd/MM/yyyy').format(limite)}${vencidoLimite ? ' (¡plazo vencido!)' : ''}' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cancelado ? Colors.green[800] : (vencidoLimite ? Colors.red[800] : Colors.orange[900]),
                  ),
                ),
              ),
            ],
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
                _docBotones(contrato, 'Contrato firmado', 'Contrato_venta_$id'),
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
              if (constancia != null) ...[
                const SizedBox(height: 10),
                Row(children: const [
                  Icon(Icons.verified, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Constancia de cancelación y entrega firmada',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 6),
                _docBotones(constancia, 'Constancia de cancelación', 'Constancia_venta_$id'),
              ],
              if (parcial && contrato != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red[700]),
                  onPressed: () => _desistir(v),
                  icon: const Icon(Icons.undo),
                  label: const Text('El cliente desistió (devolver dinero)'),
                ),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                  onPressed: () => _cancelarSaldo(v),
                  icon: const Icon(Icons.price_check),
                  label: const Text('Cancelar saldo y entregar bien'),
                ),
              ],
              if (cancelado && constancia == null) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _cancelarSaldo(v, yaCobrado: true),
                  icon: const Icon(Icons.draw),
                  label: const Text('Firmar constancia de entrega'),
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
