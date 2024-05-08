import 'dart:developer';

import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RevenueBox extends StatefulWidget {
  const RevenueBox({
    super.key,
    required this.movimientos,
    required this.types,
  });
  final List<MovimientosEntity> movimientos;
  final List<String> types;

  @override
  State<RevenueBox> createState() => _RevenueBoxState();
}

class _RevenueBoxState extends State<RevenueBox> {
  late List<MovimientosEntity> filter;

  @override
  void initState() {
    super.initState();
    filter = widget.movimientos;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        AppDropdownButtonFormField<String?>(
          items: widget.types
              .map(
                (e) => DropdownMenuItem<String?>(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: (e) {
            final result = widget.movimientos
                .where((element) =>
                    element.tipo?.descripcion?.contains(e!) ?? false)
                .toList();

            setState(() {
              filter = result;
            });
          },
          labelText: 'Seleccionar Tipo de Movimiento',
        ),
        if (filter.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              'No se encontraron ingresos',
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filter.length,
              itemBuilder: (context, index) {
                final movimiento = filter[index];
                return ExpansionTile(
                  onExpansionChanged: (value) {
                    log('clicked_movimiento: ${movimiento.toString()}');
                  },
                  title: Text(
                    'Monto: s/ ${movimiento.monto}',
                  ),
                  subtitle: Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy - hh:mm').format(DateTime.parse(movimiento.createdAt ?? '').toLocal())}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryText,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ).copyWith(
                    bottom: 20,
                  ),
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Tipo: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(movimiento?.tipo?.descripcion ?? ''),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Observaciones: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(movimiento?.observaciones ?? ''),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
