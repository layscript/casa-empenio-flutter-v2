import 'dart:convert';
import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/contrato_compraventa.dart';
import 'package:casa_empenio_pe/presentation/app/utils/custom_image_picker.dart';
import 'package:casa_empenio_pe/presentation/app/utils/expediente_page.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/selector_medio_pago.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// Registrar la COMPRA de un producto a una persona, paso a paso:
/// 1) a quién le compras  2) qué compras  3) cuánto pagas  4) firmas y huella.
/// Al concretar: el producto entra al almacén con su código, el dinero sale de
/// caja y el contrato de compra queda firmado y listo para imprimir.
class RegistrarCompraPage extends StatefulWidget {
  const RegistrarCompraPage({super.key, required this.categories});
  final List<CategoriesEntity> categories;

  @override
  State<RegistrarCompraPage> createState() => _RegistrarCompraPageState();
}

class _RegistrarCompraPageState extends State<RegistrarCompraPage> {
  // vendedor
  final _dni = TextEditingController();
  final _nombre = TextEditingController();
  final _domicilio = TextEditingController();
  // producto
  CategoriesEntity? _cat;
  final _desc = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _color = TextEditingController();
  final _serie = TextEditingController();
  final _placa = TextEditingController();
  final _motor = TextEditingController();
  final _carroceria = TextEditingController();
  final _anio = TextEditingController();
  final _obs = TextEditingController();
  int _cantidad = 1;
  List<XFile> _fotos = [];
  // pago
  final _precio = TextEditingController();
  final _venta = TextEditingController();
  String _medio = 'EFECTIVO';
  String? _banco;
  bool _medioOk = true;

  bool _buscando = false;
  bool _trabajando = false;
  String? _error;

  // firmas
  FirmaCapturada? _firmaV;
  HuellaCapturada? _huella;
  Uint8List? _firmaE;
  bool _firmando = false;

  // resultado
  bool _terminado = false;
  Uint8List? _pdfFinal;
  Map<String, dynamic>? _resultado;
  bool _compraHecha = false;

  @override
  void dispose() {
    for (final c in [
      _dni, _nombre, _domicilio, _desc, _marca, _modelo, _color, _serie,
      _placa, _motor, _carroceria, _anio, _obs, _precio, _venta
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _esVehiculo {
    final t = ((_cat?.plantilla ?? '') + ' ' + (_cat?.descripcion ?? ''))
        .toLowerCase();
    return t.contains('vehic') ||
        t.contains('vehíc') ||
        t.contains('moto') ||
        t.contains('auto') ||
        t.contains('camion');
  }

  Future<void> _buscarDni() async {
    final dni = _dni.text.trim();
    if (dni.length < 8) {
      setState(() => _error = 'Escribe el DNI (8 dígitos) o RUC (11)');
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
        _error = 'No se encontró. Escribe el nombre y domicilio a mano.';
      }),
      (c) => setState(() {
        _buscando = false;
        _nombre.text = c.customerFullName.trim();
        _domicilio.text = c.domicilio?.direccion ?? '';
      }),
    );
  }

  double get _precioPagado =>
      double.tryParse(_precio.text.replaceAll(',', '.')) ?? 0;

  DatosContrato _datos() => DatosContrato(
        empresaCompra: true,
        esVehiculo: _esVehiculo,
        nombre: _nombre.text,
        dni: _dni.text,
        domicilio: _domicilio.text,
        descripcion: _desc.text,
        marca: _marca.text,
        modelo: _modelo.text,
        color: _color.text,
        serie: _serie.text,
        placa: _placa.text,
        motor: _motor.text,
        carroceria: _carroceria.text,
        anio: _anio.text,
        clase: _cat?.descripcion ?? '',
        estado: _obs.text,
        precio: _precioPagado,
        ciudad: 'Atalaya',
        fecha: DateTime.now(),
      );

  String? _validar() {
    if (_dni.text.trim().length < 8 || _nombre.text.trim().isEmpty) {
      return 'Paso 1: escribe el DNI y el nombre de quien vende';
    }
    if (_cat == null) return 'Paso 2: elige la categoría del producto';
    if (_desc.text.trim().isEmpty) return 'Paso 2: describe el producto';
    if (_precioPagado <= 0) return 'Paso 3: escribe cuánto vas a pagar';
    if (!_medioOk) return 'Paso 3: elige el banco del depósito';
    return null;
  }

  Future<void> _ir() async {
    final e = _validar();
    if (e != null) {
      setState(() => _error = e);
      return;
    }
    setState(() {
      _error = null;
      _firmando = true;
    });
  }

  Future<void> _concretar() async {
    if (_firmaV == null || _huella == null || _firmaE == null || _trabajando) {
      return;
    }
    final repo = context.read<SalesRepository>();
    final prefs = context.read<Preferences>();
    final auth = context.read<AuthBloc>().state as Authenticated;
    setState(() {
      _trabajando = true;
      _error = null;
    });

    if (!_compraHecha) {
      final ahora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      final pdf = await crearContratoCompraVentaPdf(
        _datos(),
        firmaPersona: _firmaV!.png,
        firmaEmpresa: _firmaE,
        huellaPersona: _huella!.imagenPng,
        selloDigital:
            'Contrato de compra firmado digitalmente el $ahora · Firma y huella del vendedor registradas.',
      );
      final r = await repo.registrarCompra({
        'descripcion': _desc.text.trim(),
        'categoria': _cat!.descripcion,
        'marca': _marca.text.trim(),
        'modelo': _modelo.text.trim(),
        'color': _color.text.trim(),
        'serie': _serie.text.trim(),
        'placa': _placa.text.trim(),
        'motor': _motor.text.trim(),
        'carroceria': _carroceria.text.trim(),
        if (int.tryParse(_anio.text.trim()) != null)
          'anio': int.parse(_anio.text.trim()),
        'observaciones': _obs.text.trim(),
        'cantidad': _cantidad,
        if (double.tryParse(_venta.text.replaceAll(',', '.')) != null)
          'valorizacion': double.parse(_venta.text.replaceAll(',', '.')),
        'vendedorDni': _dni.text.trim(),
        'vendedorNombre': _nombre.text.trim(),
        'precioPagado': _precioPagado,
        'medioPago': _medio,
        if (_banco != null) 'banco': _banco,
        'sucursalId': prefs.token?.sucursal?.id ?? 1,
        'usuarioId': auth.user?.id ?? 1,
        'pdfBase64': base64Encode(pdf),
        'firmaVendedorBase64': base64Encode(_firmaV!.png),
        'firmaEmpresaBase64': base64Encode(_firmaE!),
        'huellaImagenBase64': base64Encode(_huella!.imagenPng),
        'huellaTemplateBase64': _huella!.template,
        'huellaQuality': _huella!.quality,
      });
      if (!mounted) return;
      if (r['error'] != null) {
        setState(() {
          _trabajando = false;
          _error = r['error'].toString();
        });
        return;
      }
      _compraHecha = true;
      _pdfFinal = pdf;
      _resultado = Map<String, dynamic>.from(r['data'] as Map);
    }

    // fotos (si fallan, la compra ya está hecha: se avisa)
    final bienId = _resultado?['bienId'] as int?;
    String? aviso;
    if (bienId != null && _fotos.isNotEmpty) {
      final ok = await context.read<ProductRepository>().subirFotosProducto(
            id: bienId,
            imagenUno: _fotos[0].path,
            imagenDos: _fotos.length > 1 ? _fotos[1].path : null,
          );
      if (!ok) aviso = 'Las fotos no se pudieron subir; agrégalas luego editando el producto.';
    }
    if (!mounted) return;
    setState(() {
      _trabajando = false;
      _terminado = true;
      _error = aviso;
    });
  }

  Widget _titulo(int n, String t, String sub) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Row(children: [
          CircleAvatar(
              radius: 13,
              backgroundColor: Colors.blue[700],
              child: Text('$n',
                  style: const TextStyle(color: Colors.white, fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(sub,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ]),
      );

  Widget _campo(TextEditingController c, String label,
          {TextInputType? tipo, int lineas = 1, VoidCallback? cambio}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: tipo,
          minLines: lineas,
          maxLines: lineas,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  Widget _formulario() {
    final cats = widget.categories;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
      children: [
        _titulo(1, '¿A quién le compras?', 'Busca por DNI y se llena solo'),
        Row(children: [
          Expanded(child: _campo(_dni, 'DNI o RUC', tipo: TextInputType.number)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.icon(
              onPressed: _buscando ? null : _buscarDni,
              icon: _buscando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
          ),
        ]),
        _campo(_nombre, 'Nombre completo'),
        _campo(_domicilio, 'Domicilio'),
        _titulo(2, '¿Qué compras?', 'Los mismos datos que al registrar un préstamo'),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DropdownButtonFormField<CategoriesEntity>(
            value: _cat,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                isDense: true),
            items: [
              for (final c in cats)
                DropdownMenuItem(
                  value: c,
                  child: Text(
                    (c.padreId != null ? '   ↳ ' : '') + c.descripcion,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _cat = v),
          ),
        ),
        _campo(_desc, 'Descripción (ej: Moto lineal Honda 150)'),
        if (!(_cat?.ocultarBasicos ?? false)) ...[
          Row(children: [
            Expanded(child: _campo(_marca, 'Marca')),
            const SizedBox(width: 8),
            Expanded(child: _campo(_modelo, 'Modelo')),
          ]),
          Row(children: [
            Expanded(child: _campo(_color, 'Color')),
            const SizedBox(width: 8),
            Expanded(child: _campo(_serie, 'Serie / IMEI')),
          ]),
        ],
        if (_esVehiculo) ...[
          Row(children: [
            Expanded(child: _campo(_placa, 'Placa')),
            const SizedBox(width: 8),
            Expanded(child: _campo(_anio, 'Año', tipo: TextInputType.number)),
          ]),
          Row(children: [
            Expanded(child: _campo(_motor, 'N° de motor')),
            const SizedBox(width: 8),
            Expanded(child: _campo(_carroceria, 'Carrocería')),
          ]),
        ],
        _campo(_obs, 'Estado / observaciones', lineas: 2),
        Row(children: [
          const Text('Cantidad:'),
          IconButton(
              onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
              icon: const Icon(Icons.remove_circle_outline)),
          Text('$_cantidad',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
              onPressed: () => setState(() => _cantidad++),
              icon: const Icon(Icons.add_circle_outline)),
        ]),
        const Text('Fotos (hasta 2)',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        CustomImagePicker(
          limit: 2,
          initialSelectedPhotos: _fotos,
          onImagesSelected: (l) => _fotos = l ?? [],
        ),
        _titulo(3, '¿Cuánto pagas?', 'Sale de la caja de hoy'),
        _campo(_precio, 'Precio que le pagas al vendedor (S/.)',
            tipo: const TextInputType.numberWithOptions(decimal: true)),
        _campo(_venta, 'Precio al que piensas venderlo (opcional)',
            tipo: const TextInputType.numberWithOptions(decimal: true)),
        SelectorMedioPago(
          pregunta: '¿Cómo le pagas?',
          ayudaEfectivo: 'Sale dinero de la caja (efectivo).',
          verbo: 'salió',
          alCambiar: (m, b, ok) {
            _medio = m;
            _banco = b;
            _medioOk = ok;
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: _ir,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Siguiente: firmas y contrato'),
        ),
      ],
    );
  }

  Widget _paso(int n, String t, String sub, bool hecho, VoidCallback onTap,
          String boton, IconData icono) =>
      Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: hecho ? Colors.green : Colors.grey[400],
            child: hecho
                ? const Icon(Icons.check, color: Colors.white)
                : Text('$n', style: const TextStyle(color: Colors.white)),
          ),
          title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(sub),
          trailing: ElevatedButton.icon(
            onPressed: _trabajando ? null : onTap,
            icon: Icon(icono, size: 18),
            label: Text(hecho ? 'Repetir' : boton),
          ),
        ),
      );

  Widget _firmas() {
    final d = _datos();
    final listo = _firmaV != null && _huella != null && _firmaE != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
      children: [
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vendedor: ${d.nombre.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('DNI: ${d.dni}'),
                Text('Producto: ${d.descripcion}'),
                Text('Pagas: S/. ${d.precio.toStringAsFixed(2)} ($_medio)',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Para concretar la compra se necesitan las tres firmas. Hasta entonces no se registra nada ni sale dinero de caja.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        _paso(1, 'Firma del vendedor', 'Que firme con el dedo', _firmaV != null,
            () async {
          final r = await capturarFirmaDigital(context,
              titulo: 'Firma del vendedor',
              nombreInicial: d.nombre,
              dniInicial: d.dni);
          if (r != null) setState(() => _firmaV = r);
        }, 'Firmar', Icons.draw),
        _paso(2, 'Huella del vendedor', 'Con el lector de huellas',
            _huella != null, () async {
          final r = await capturarHuellaDigital(context,
              titulo: 'Huella del vendedor');
          if (r != null) setState(() => _huella = r);
        }, 'Tomar huella', Icons.fingerprint),
        _paso(3, 'Firma de la empresa', 'Quien atiende', _firmaE != null,
            () async {
          final r = await obtenerFirmaEmpresa(context);
          if (r != null) setState(() => _firmaE = r);
        }, 'Firmar', Icons.business),
        OutlinedButton.icon(
          onPressed: _trabajando
              ? null
              : () => abrirVistaPdf(
                    context,
                    titulo: 'Contrato de compra (borrador)',
                    archivo: 'Contrato_compra_borrador.pdf',
                    build: () => crearContratoCompraVentaPdf(
                      d,
                      firmaPersona: _firmaV?.png,
                      firmaEmpresa: _firmaE,
                      huellaPersona: _huella?.imagenPng,
                    ),
                  ),
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
          onPressed: listo && !_trabajando ? _concretar : null,
          icon: _trabajando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.verified),
          label: Text(_trabajando ? 'Guardando…' : 'Concretar compra'),
        ),
      ],
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
            const Text('Compra registrada',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Producto ${_resultado?['codigoInventario'] ?? ''} comprado a ${_nombre.text.trim()} por S/. ${_precioPagado.toStringAsFixed(2)}.\n'
              'Ya está en el almacén y listo para vender. El dinero salió de caja y el contrato quedó guardado.',
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.orange)),
            ],
            const SizedBox(height: 22),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white),
              onPressed: () => imprimirPdf(_pdfFinal!,
                  'Contrato_compra_${_nombre.text.trim().replaceAll(' ', '_')}'),
              icon: const Icon(Icons.print),
              label: const Text('Imprimir copia para el vendedor'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => abrirVistaPdf(
                context,
                titulo: 'Contrato de compra',
                archivo: 'Contrato_compra.pdf',
                build: () async => _pdfFinal!,
              ),
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
    return WillPopScope(
      onWillPop: () async {
        if (_terminado) {
          Navigator.pop(context, true);
          return false;
        }
        if (_firmando && !_trabajando) {
          setState(() => _firmando = false);
          return false;
        }
        return !_trabajando;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar compra')),
        body: _terminado ? _exito() : (_firmando ? _firmas() : _formulario()),
      ),
    );
  }
}
