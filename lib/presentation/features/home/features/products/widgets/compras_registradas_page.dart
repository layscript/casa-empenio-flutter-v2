import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/contrato_compraventa.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Compras de productos ya registradas, con su contrato firmado para ver o imprimir.
class ComprasRegistradasPage extends StatefulWidget {
  const ComprasRegistradasPage({super.key});

  @override
  State<ComprasRegistradasPage> createState() => _ComprasRegistradasPageState();
}

class _ComprasRegistradasPageState extends State<ComprasRegistradasPage> {
  List<Map<String, dynamic>>? _lista;
  bool _abriendo = false;

  @override
  void initState() {
    super.initState();
    final sid = context.read<Preferences>().token?.sucursal?.id ?? 1;
    context.read<SalesRepository>().comprasRegistradas(sid).then((l) {
      if (mounted) setState(() => _lista = l);
    });
  }

  Future<Uint8List?> _bajar(String ruta) async {
    try {
      final r = await Dio().get<List<int>>(
        '$endPointPrincipal/$ruta',
        options: Options(responseType: ResponseType.bytes),
      );
      final b = Uint8List.fromList(r.data ?? <int>[]);
      return b.isEmpty ? null : b;
    } catch (_) {
      return null;
    }
  }

  Future<void> _abrir(Map<String, dynamic> c, {required bool imprimir}) async {
    setState(() => _abriendo = true);
    final b = await _bajar('${c['pdf']}');
    if (!mounted) return;
    setState(() => _abriendo = false);
    if (b == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el contrato')));
      return;
    }
    final nombre = 'Contrato_compra_${c['codigoInventario'] ?? c['id']}';
    if (imprimir) {
      await imprimirPdf(b, nombre);
    } else {
      abrirVistaPdf(context,
          titulo: 'Contrato de compra',
          archivo: '$nombre.pdf',
          build: () async => b);
    }
  }

  String _fecha(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    if (d == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm')
        .format(d.toUtc().subtract(const Duration(hours: 5)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compras registradas')),
      body: _lista == null
          ? const Center(child: CircularProgressIndicator())
          : _lista!.isEmpty
              ? const Center(child: Text('Aún no hay compras registradas.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _lista!.length,
                  itemBuilder: (_, i) {
                    final c = _lista![i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${c['codigoInventario'] ?? ''} · ${c['descripcion']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                                'Vendedor: ${c['vendedorNombre']} (DNI ${c['vendedorDni']})'),
                            Text(
                                'Pagado: S/. ${double.tryParse('${c['precioPagado']}')?.toStringAsFixed(2) ?? c['precioPagado']} · ${_fecha(c['createdAt'])}'),
                            const SizedBox(height: 6),
                            Wrap(spacing: 8, children: [
                              OutlinedButton.icon(
                                onPressed: _abriendo
                                    ? null
                                    : () => _abrir(c, imprimir: false),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Ver contrato'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _abriendo
                                    ? null
                                    : () => _abrir(c, imprimir: true),
                                icon: const Icon(Icons.print),
                                label: const Text('Imprimir'),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
