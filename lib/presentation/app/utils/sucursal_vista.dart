import 'dart:convert';

import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Sucursal que el administrador está mirando en los reportes.
/// null = su propia sucursal (la de su sesión).
class SucursalVista {
  static int? id;
  static int actual(int? propia) => id ?? propia ?? 1;
}

Future<List<Map<String, dynamic>>> cargarSucursales() async {
  final r = await Dio(BaseOptions(
    baseUrl: endPointPrincipal,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  )).get<dynamic>('/sucursal');
  final data = r.data;
  final map = (data is String ? json.decode(data) : data) as Map;
  return (map['body'] as List? ?? [])
      .map((e) => (e as Map).cast<String, dynamic>())
      .toList();
}

/// Barra "Sucursal: [Principal] [Otra]" para el administrador.
class SelectorSucursal extends StatefulWidget {
  const SelectorSucursal({super.key, required this.propia, required this.onCambio});
  final int propia;
  final VoidCallback onCambio;

  @override
  State<SelectorSucursal> createState() => _SelectorSucursalState();
}

class _SelectorSucursalState extends State<SelectorSucursal> {
  List<Map<String, dynamic>> _lista = [];

  @override
  void initState() {
    super.initState();
    cargarSucursales().then((l) {
      if (mounted) setState(() => _lista = l);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_lista.length < 2) return const SizedBox.shrink();
    final sel = SucursalVista.actual(widget.propia);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.store, size: 18, color: Colors.indigo),
        const SizedBox(width: 6),
        const Text('Sucursal: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final s in _lista)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('${s['nombre']}'),
                    selected: sel == (s['id'] as num).toInt(),
                    onSelected: (_) {
                      SucursalVista.id = (s['id'] as num).toInt();
                      widget.onCambio();
                    },
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
