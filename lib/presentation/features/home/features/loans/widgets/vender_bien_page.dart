import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/contrato_compraventa.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/contrato_venta_firma_page.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/payment_loan_dialog_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Resultado de la pantalla: 'RECOJO' (el cliente recoge su bien),
/// 'VENDIDO' (se registró la venta) o null (se canceló).
class VenderBienPage extends StatefulWidget {
  const VenderBienPage({super.key, required this.prestamo});

  final LoansEntity prestamo;

  @override
  State<VenderBienPage> createState() => _VenderBienPageState();
}

enum _Doc { contrato, proforma, boleta }

class _VenderBienPageState extends State<VenderBienPage> {
  bool _venta = false;
  _Doc _doc = _Doc.contrato;
  bool _buscando = false;
  bool _guardando = false;
  String? _error;

  final _dni = TextEditingController();
  final _nombre = TextEditingController();
  final _domicilio = TextEditingController();
  late final TextEditingController _precio;

  List<WarrantyEntity> get _bienes => widget.prestamo.bienesGarantia ?? [];

  bool get _yaVencio {
    final f = DateTime.tryParse(widget.prestamo.fechaPago ?? '');
    if (f == null) return true;
    return !f.toLocal().isAfter(DateTime.now());
  }

  Future<void> _pedirVenta() async {
    if (!_yaVencio || _diasVencido < 60) {
      final texto = !_yaVencio
          ? 'Aún no venció este préstamo.\n\n¿Está seguro que desea vender el bien?'
          : 'Este préstamo lleva solo $_diasVencido días vencido (menos de 60).\n\n¿Está seguro que desea vender el bien?';
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¿Vender antes de tiempo?'),
          content: Text(texto),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No, volver')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí, vender')),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (mounted) setState(() => _venta = true);
  }

  int get _diasVencido {
    final f = DateTime.tryParse(widget.prestamo.fechaPago ?? '');
    if (f == null) return 0;
    final d = DateTime.now().difference(f.toLocal()).inDays;
    return d < 0 ? 0 : d;
  }

  @override
  void initState() {
    super.initState();
    final val = _bienes.fold<int>(0, (a, b) => a + (b.valorizacion ?? 0));
    final deuda = (double.tryParse(widget.prestamo.monto ?? '') ?? 0) +
        (double.tryParse(widget.prestamo.ganancia ?? '') ?? 0);
    final sugerido = val > 0 ? val.toDouble() : deuda;
    _precio = TextEditingController(
        text: sugerido > 0 ? sugerido.toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _dni.dispose();
    _nombre.dispose();
    _domicilio.dispose();
    _precio.dispose();
    super.dispose();
  }

  Future<void> _buscarDni() async {
    final dni = _dni.text.trim();
    if (dni.length < 8) {
      setState(() => _error = 'Escriba el DNI (8 dígitos) o RUC (11)');
      return;
    }
    setState(() {
      _buscando = true;
      _error = null;
    });
    final r = await context
        .read<CustomerRepository>()
        .getCustomerSunatByDni(dni: dni);
    if (!mounted) return;
    r.fold(
      (l) => setState(() {
        _buscando = false;
        _error = 'No se encontró. Escriba el nombre y domicilio a mano.';
      }),
      (c) => setState(() {
        _buscando = false;
        _nombre.text = c.customerFullName.trim();
        _domicilio.text = c.domicilio?.direccion ?? '';
      }),
    );
  }

  DatosContrato _datos(double precio) {
    final b = _bienes.isNotEmpty ? _bienes.first : null;
    final vehiculo = (b?.motor ?? '').isNotEmpty || (b?.placa ?? '').isNotEmpty;
    final desc = _bienes.map((e) => e.description ?? '').where((e) => e.isNotEmpty).join(' + ');
    return DatosContrato(
      empresaCompra: false,
      esVehiculo: vehiculo,
      nombre: _nombre.text,
      dni: _dni.text,
      domicilio: _domicilio.text,
      descripcion: desc,
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
      precio: precio,
      ciudad: 'Atalaya',
      fecha: DateTime.now(),
    );
  }

  Future<void> _vender() async {
    final precio = double.tryParse(_precio.text.replaceAll(',', '.'));
    if (_dni.text.trim().isEmpty || _nombre.text.trim().isEmpty) {
      setState(() => _error = 'Escriba el DNI y el nombre de quien compra');
      return;
    }
    if (precio == null || precio <= 0) {
      setState(() => _error = 'Escriba el precio de venta');
      return;
    }
    final datos = _datos(precio);

    // La proforma es solo una cotización: no cierra la venta ni mueve caja.
    if (_doc == _Doc.proforma) {
      abrirVistaPdf(
        context,
        titulo: 'Proforma',
        archivo: 'Proforma_${_nombre.text.trim().replaceAll(' ', '_')}.pdf',
        build: () => crearProformaPdf(datos),
      );
      return;
    }

    if (_bienes.isEmpty) {
      setState(() => _error = 'Este préstamo no tiene bienes registrados');
      return;
    }

    final auth = context.read<AuthBloc>().state as Authenticated;
    final prefs = context.read<Preferences>();
    final repo = context.read<SalesRepository>();

    setState(() {
      _guardando = true;
      _error = null;
    });

    // Reparte el precio entre los bienes (el resto va al primero).
    final n = _bienes.length;
    final parte = (precio / n * 100).floorToDouble() / 100;
    final primero = double.parse((precio - parte * (n - 1)).toStringAsFixed(2));
    final detalles = <Map<String, dynamic>>[
      for (var i = 0; i < n; i++)
        {
          'cantidad': 1,
          'precio': i == 0 ? primero : parte,
          'bienGarantiaId': _bienes[i].id,
          'bienTemporal': null,
          'gastoAdicional': 0,
          'observaciones':
              'Préstamo N° ${widget.prestamo.codigoFormateado ?? widget.prestamo.codigo}',
        }
    ];

    final partes = _nombre.text.trim().split(RegExp(r'\s+'));
    final nombres = partes.first;
    final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '-';

    final payloadVenta = <String, dynamic>{
      'detalleVentaDto': detalles,
      'total': precio,
      'nombres': nombres,
      'apellidos': apellidos,
      'direccion': _domicilio.text.trim().isEmpty ? '-' : _domicilio.text.trim(),
      'dni': _dni.text.trim(),
      'usuarioId': auth.user?.id ?? 1,
      'sucursalId': prefs.token?.sucursal?.id ?? 1,
      'documento': _doc == _Doc.contrato ? 'CONTRATO_PRIVADO' : 'BOLETA',
      'prestamoCodigo': widget.prestamo.codigo,
    };

    // Contrato privado: la venta se concreta con firma + huella del comprador.
    if (_doc == _Doc.contrato) {
      setState(() => _guardando = false);
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(
          builder: (_) => ContratoVentaFirmaPage(
            datos: datos,
            payloadVenta: payloadVenta,
            prestamoCodigo: widget.prestamo.codigo,
          ),
        ),
      );
      if (ok == true && mounted) Navigator.pop(context, 'VENDIDO');
      return;
    }

    final ventaId = await repo.registrarVenta(payloadVenta);

    if (!mounted) return;
    if (ventaId == null) {
      setState(() {
        _guardando = false;
        _error = 'No se pudo registrar la venta. Revise que la caja esté abierta e intente de nuevo.';
      });
      return;
    }

    var aviso = 'Venta registrada y enlazada a ${_nombre.text.trim()}';
    if (_doc == _Doc.boleta) {
      final ok = await repo.emitirBoleta(ventaId);
      aviso = ok
          ? 'Venta registrada y boleta emitida'
          : 'Venta registrada, pero la boleta no se pudo emitir. Reintente desde Ventas';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));

    setState(() {
      _guardando = false;
      _vendido = true;
    });
    Navigator.pop(context, 'VENDIDO');
  }

  bool _vendido = false;

  Widget _resumen() {
    final p = widget.prestamo;
    final cli = p.cliente;
    final venc = DateTime.tryParse(p.fechaPago ?? '');
    final deuda = (double.tryParse(p.monto ?? '') ?? 0) +
        (double.tryParse(p.ganancia ?? '') ?? 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Préstamo N° ${p.codigoFormateado ?? p.codigo}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            if (cli != null) Text('Cliente: ${cli.nombres ?? ''} ${cli.apellidos ?? ''}'),
            for (final b in _bienes)
              Text('• ${b.description ?? ''}${(b.serie ?? '').isNotEmpty ? ' · Serie ${b.serie}' : ''}'),
            const SizedBox(height: 4),
            Text(
              venc == null
                  ? 'Vencido'
                  : !_yaVencio
                      ? 'Vence el ${DateFormat('dd/MM/yyyy').format(venc.toLocal())} (aún vigente)'
                      : 'Venció el ${DateFormat('dd/MM/yyyy').format(venc.toLocal())} · hace $_diasVencido días',
              style: TextStyle(
                color: !_yaVencio ? Colors.blue[800] : _diasVencido >= 60 ? Colors.red[700] : Colors.orange[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text('Deuda total: S/. ${deuda.toStringAsFixed(2)}'),
            if (_yaVencio && _diasVencido < 60)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Aún no pasan 60 días de vencido. Se le pedirá confirmar.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _eleccion() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('¿Qué se hace con este bien?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white),
            onPressed: _pedirVenta,
            icon: const Icon(Icons.sell),
            label: const Text('VENTA  (se lo vendemos a alguien)',
                style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18)),
            onPressed: () => Navigator.pop(context, 'RECOJO'),
            icon: const Icon(Icons.handshake),
            label: const Text('RECOJO  (el cliente lo recoge y paga)',
                style: TextStyle(fontSize: 15)),
          ),
        ],
      );

  Widget _formVenta() {
    const docs = {
      _Doc.contrato: ('Contrato privado', Icons.description),
      _Doc.proforma: ('Proforma', Icons.request_quote),
      _Doc.boleta: ('Boleta', Icons.receipt_long),
    };
    final guardaVenta = _doc != _Doc.proforma;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. ¿Qué documento?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final e in docs.entries)
              ChoiceChip(
                avatar: Icon(e.value.$2, size: 18),
                label: Text(e.value.$1),
                selected: _doc == e.key,
                onSelected: (_) => setState(() => _doc = e.key),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          switch (_doc) {
            _Doc.contrato => 'Contrato digital: el comprador firma y pone su huella, la empresa firma, y el contrato queda guardado en el expediente del préstamo. La venta se registra al concretar.',
            _Doc.proforma => 'Solo una cotización para el cliente. No registra la venta ni mueve la caja.',
            _Doc.boleta => 'Registra la venta y emite la boleta electrónica.',
          },
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        const Text('2. ¿Quién compra?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _dni,
                keyboardType: TextInputType.number,
                maxLength: 11,
                decoration: const InputDecoration(
                    labelText: 'DNI o RUC',
                    border: OutlineInputBorder(),
                    isDense: true,
                    counterText: ''),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _buscando ? null : _buscarDni,
              child: _buscando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Buscar'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Nombre completo',
              border: OutlineInputBorder(),
              isDense: true),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _domicilio,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Domicilio',
              border: OutlineInputBorder(),
              isDense: true),
        ),
        const SizedBox(height: 16),
        const Text('3. Precio de venta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _precio,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              prefixText: 'S/. ',
              border: OutlineInputBorder(),
              isDense: true),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 18),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _guardando ? null : _vender,
          icon: Icon(guardaVenta ? Icons.check_circle : Icons.picture_as_pdf),
          label: Text(guardaVenta
              ? (_doc == _Doc.contrato ? 'Continuar a firmar el contrato' : 'Vender y emitir boleta')
              : 'Ver proforma'),
        ),
        TextButton(
          onPressed: _guardando ? null : () => setState(() => _venta = false),
          child: const Text('Volver'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si ya se vendió con contrato, al volver del PDF se cierra la pantalla.
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _vendido ? 'VENDIDO' : null);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Vender o recoger')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            _resumen(),
            const SizedBox(height: 16),
            if (_venta)
              _formVenta()
            else
              _eleccion(),
          ],
        ),
      ),
    );
  }
}

/// Punto de entrada: pregunta Venta o Recojo para un préstamo vencido.
/// Devuelve true si algo cambió (hay que refrescar la lista).
Future<bool> abrirVenderBien(
  BuildContext context,
  LoansEntity prestamo,
  LoansBloc bloc,
) async {
  final r = await Navigator.push<String>(
    context,
    MaterialPageRoute<String>(
      builder: (_) => VenderBienPage(prestamo: prestamo),
    ),
  );
  if (r == 'VENDIDO') return true;
  if (r == 'RECOJO' && context.mounted) {
    final pagado = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: PaymentLoanDialogClient(nroPrestamo: prestamo.codigo),
      ),
    );
    return pagado ?? true;
  }
  return false;
}
