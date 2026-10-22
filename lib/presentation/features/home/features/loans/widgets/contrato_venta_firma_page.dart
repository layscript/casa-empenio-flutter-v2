import 'dart:convert';
import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/contrato_compraventa.dart';
import 'package:casa_empenio_pe/presentation/app/utils/expediente_page.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Concreta la venta con contrato privado DIGITAL:
/// firma del comprador + huella del comprador + firma de la empresa.
/// Solo cuando las tres están listas se registra la venta y se guarda el
/// contrato (PDF sellado) enlazado al expediente del préstamo.
class ContratoVentaFirmaPage extends StatefulWidget {
  const ContratoVentaFirmaPage({
    super.key,
    required this.datos,
    required this.payloadVenta,
    this.prestamoCodigo,
    this.ventaIdExistente,
    this.cancelacion = false,
    this.fechaContrato,
    this.saldoYaCobrado = false,
  });

  final DatosContrato datos;

  /// Datos para registrar la venta (se envía recién al concretar).
  final Map<String, dynamic> payloadVenta;
  final int? prestamoCodigo;

  /// Si la venta ya estaba registrada y solo falta el contrato firmado.
  final int? ventaIdExistente;

  /// true = el cliente vuelve a cancelar el saldo: se firma la constancia de
  /// cancelación y entrega (con firma y huella nuevas).
  final bool cancelacion;

  /// Fecha del contrato original (para la constancia).
  final DateTime? fechaContrato;

  /// El saldo ya se cobró antes y solo falta firmar la constancia.
  final bool saldoYaCobrado;

  @override
  State<ContratoVentaFirmaPage> createState() => _ContratoVentaFirmaPageState();
}

class _ContratoVentaFirmaPageState extends State<ContratoVentaFirmaPage> {
  FirmaCapturada? _firmaComprador;
  HuellaCapturada? _huella;
  Uint8List? _firmaEmpresa;
  bool _trabajando = false;
  String? _error;
  int? _ventaId;
  bool _terminado = false;
  bool _saldoCancelado = false;
  Uint8List? _pdfFinal;

  @override
  void initState() {
    super.initState();
    _ventaId = widget.ventaIdExistente;
    _saldoCancelado = widget.saldoYaCobrado;
  }

  bool get _listo =>
      _firmaComprador != null && _huella != null && _firmaEmpresa != null;

  Future<void> _firmarComprador() async {
    final r = await capturarFirmaDigital(
      context,
      titulo: 'Firma del comprador',
      nombreInicial: widget.datos.nombre,
      dniInicial: widget.datos.dni,
    );
    if (r != null) setState(() => _firmaComprador = r);
  }

  Future<void> _tomarHuella() async {
    final r = await capturarHuellaDigital(context, titulo: 'Huella del comprador');
    if (r != null) setState(() => _huella = r);
  }

  Future<void> _firmarEmpresa() async {
    final r = await obtenerFirmaEmpresa(context);
    if (r != null) setState(() => _firmaEmpresa = r);
  }

  void _verBorrador() {
    abrirVistaPdf(
      context,
      titulo: 'Contrato (borrador)',
      archivo: 'Contrato_borrador.pdf',
      build: () => crearContratoCompraVentaPdf(
        widget.datos,
        firmaPersona: _firmaComprador?.png,
        firmaEmpresa: _firmaEmpresa,
        huellaPersona: _huella?.imagenPng,
      ),
    );
  }

  Future<void> _concretar() async {
    if (!_listo || _trabajando) return;
    final repo = context.read<SalesRepository>();
    final prefs = context.read<Preferences>();
    setState(() {
      _trabajando = true;
      _error = null;
    });

    final cancel = widget.cancelacion;

    // 1) Registrar la venta, o cancelar el saldo (solo una vez, aunque se reintente)
    if (cancel) {
      _ventaId = widget.ventaIdExistente;
      if (!_saldoCancelado) {
        final user = context.read<AuthBloc>().state as Authenticated;
        final e = await repo.cancelarSaldoVenta(
          ventaId: _ventaId!,
          usuarioId: user.user?.id ?? 1,
          sucursalId: prefs.token?.sucursal?.id ?? 1,
        );
        if (!mounted) return;
        if (e != null) {
          setState(() {
            _trabajando = false;
            _error = e;
          });
          return;
        }
        _saldoCancelado = true;
      }
    } else {
      _ventaId ??= await repo.registrarVenta(widget.payloadVenta);
      if (_ventaId == null) {
        if (!mounted) return;
        setState(() {
          _trabajando = false;
          _error =
              'No se pudo registrar la venta. Revise que la caja esté abierta e intente de nuevo.';
        });
        return;
      }
    }

    // 2) PDF final con firmas, huella y sello de fecha
    final ahora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final sello =
        '${cancel ? 'Constancia firmada' : 'Contrato firmado'} digitalmente el $ahora · Venta N° $_ventaId'
        '${widget.prestamoCodigo != null ? ' · Préstamo N° ${widget.prestamoCodigo}' : ''}'
        ' · Firma y huella del comprador registradas.';
    final pdf = cancel
        ? await crearConstanciaCancelacionPdf(
            widget.datos,
            fechaContrato: widget.fechaContrato ?? DateTime.now(),
            firmaPersona: _firmaComprador!.png,
            firmaEmpresa: _firmaEmpresa,
            huellaPersona: _huella!.imagenPng,
            selloDigital: sello,
          )
        : await crearContratoCompraVentaPdf(
            widget.datos,
            firmaPersona: _firmaComprador!.png,
            firmaEmpresa: _firmaEmpresa,
            huellaPersona: _huella!.imagenPng,
            selloDigital: sello,
          );

    // 3) Guardar el documento en el expediente
    final err = await repo.guardarContratoVenta({
      'ventaId': _ventaId,
      'tipo': cancel ? 'CANCELACION' : 'VENTA',
      if (widget.prestamoCodigo != null) 'prestamoCodigo': widget.prestamoCodigo,
      'compradorNombre': widget.datos.nombre.trim(),
      'compradorDni': widget.datos.dni.trim(),
      'precio': widget.datos.precio,
      if (widget.datos.parcial) 'adelanto': widget.datos.adelanto,
      if (widget.datos.parcial && cancel) 'saldo': widget.datos.saldo,
      'pdfBase64': base64Encode(pdf),
      'firmaCompradorBase64': base64Encode(_firmaComprador!.png),
      'firmaEmpresaBase64': base64Encode(_firmaEmpresa!),
      'huellaTemplateBase64': _huella!.template,
      'huellaTemplateType': _huella!.templateType,
      'huellaImagenBase64': base64Encode(_huella!.imagenPng),
      'huellaQuality': _huella!.quality,
      'usuarioId': prefs.token?.id,
    });
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _trabajando = false;
        _error =
            '$err\n${cancel ? 'El saldo ya quedó cobrado' : 'La venta ya quedó registrada (N° $_ventaId)'}. Toque "Concretar" otra vez para guardar el documento.';
      });
      return;
    }

    setState(() {
      _trabajando = false;
      _terminado = true;
      _pdfFinal = pdf;
    });
  }

  Future<void> _imprimirCopia() async {
    final pdf = _pdfFinal;
    if (pdf == null) return;
    await imprimirPdf(
      pdf,
      '${widget.cancelacion ? 'Constancia' : 'Contrato'}_${widget.datos.nombre.trim().replaceAll(' ', '_')}',
    );
  }

  void _verFinal() {
    final pdf = _pdfFinal;
    if (pdf == null) return;
    abrirVistaPdf(
      context,
      titulo: 'Contrato firmado',
      archivo: 'Contrato_${widget.datos.nombre.trim().replaceAll(' ', '_')}.pdf',
      build: () async => pdf,
    );
  }

  Widget _paso(
    int n,
    String titulo,
    String detalle,
    bool hecho,
    VoidCallback onTap,
    String boton,
    IconData icono,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hecho ? Colors.green : Colors.grey[400],
          child: hecho
              ? const Icon(Icons.check, color: Colors.white)
              : Text('$n', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(detalle),
        trailing: ElevatedButton.icon(
          onPressed: _trabajando ? null : onTap,
          icon: Icon(icono, size: 18),
          label: Text(hecho ? 'Repetir' : boton),
        ),
      ),
    );
  }

  Widget _exito() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 72),
            const SizedBox(height: 12),
            Text(widget.cancelacion ? 'Saldo cancelado y bien entregado' : 'Venta concretada',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Venta N° $_ventaId a ${widget.datos.nombre.trim()}.\n'
              '${widget.datos.parcial && !widget.cancelacion ? 'Adelanto recibido: S/. ${widget.datos.adelanto!.toStringAsFixed(2)} · Saldo S/. ${widget.datos.saldo.toStringAsFixed(2)} hasta el ${DateFormat('dd/MM/yyyy').format(widget.datos.fechaLimite!)}.\n' : ''}'
              'El documento firmado quedó guardado en el expediente'
              '${widget.prestamoCodigo != null ? ' del préstamo N° ${widget.prestamoCodigo}' : ''}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white),
              onPressed: _imprimirCopia,
              icon: const Icon(Icons.print),
              label: const Text('Imprimir copia para el cliente'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _verFinal,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Ver / compartir PDF'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Terminar'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.datos;
    return WillPopScope(
      onWillPop: () async {
        if (_terminado) {
          Navigator.pop(context, true);
          return false;
        }
        return !_trabajando;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.cancelacion ? 'Cancelar saldo y entregar' : 'Firmar contrato de venta')),
        body: _terminado ? _exito() : ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comprador: ${d.nombre.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('DNI: ${d.dni}'),
                    Text('Bien: ${d.descripcion}'),
                    Text('Precio: S/. ${d.precio.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (d.parcial && !widget.cancelacion) ...[
                      Text('Adelanto hoy: S/. ${d.adelanto!.toStringAsFixed(2)}'),
                      Text('Saldo: S/. ${d.saldo.toStringAsFixed(2)} hasta el ${DateFormat('dd/MM/yyyy').format(d.fechaLimite!)}'),
                    ],
                    if (widget.cancelacion)
                      Text(
                        widget.saldoYaCobrado
                            ? 'El saldo de S/. ${d.saldo.toStringAsFixed(2)} ya fue cobrado.'
                            : 'Saldo a cobrar ahora: S/. ${d.saldo.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para concretar la venta se necesitan las tres firmas. '
              'Hasta entonces no se registra nada.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            _paso(1, 'Firma del comprador', 'Que firme con el dedo en la pantalla',
                _firmaComprador != null, _firmarComprador, 'Firmar', Icons.draw),
            _paso(2, 'Huella del comprador', 'Con el lector de huellas',
                _huella != null, _tomarHuella, 'Tomar huella', Icons.fingerprint),
            _paso(3, 'Firma de la empresa', 'Quien atiende (se guarda su firma)',
                _firmaEmpresa != null, _firmarEmpresa, 'Firmar', Icons.business),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _trabajando ? null : _verBorrador,
              icon: const Icon(Icons.visibility),
              label: const Text('Ver el contrato'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white),
              onPressed: _listo && !_trabajando ? _concretar : null,
              icon: _trabajando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified),
              label: Text(_trabajando
                  ? 'Guardando…'
                  : widget.cancelacion
                      ? 'Cobrar saldo y entregar'
                      : 'Concretar venta'),
            ),
          ],
        ),
      ),
    );
  }
}
