import 'dart:developer';

import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/bloc/cajas_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/leading_download_cajas.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MovementsView extends StatelessWidget {
  const MovementsView({
    super.key,
    required this.id,
    required this.movimientos,
    required this.isClosed,
  });

  final int id;
  final List<MovimientosEntity> movimientos;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: const Text('Movimientos de Caja'),
        actions: [
          LeadingDownloadCajas(
            movimientos: movimientos,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: movimientos.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final movimiento = movimientos[index];

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
                    /* if (!isClosed) ...[
                      const SizedBox(height: 15),
                      CupertinoButton(
                        color: AppColors.red,
                        child: Text('Eliminar Movimiento'),
                        onPressed: () {
                          context.read<CajasBloc>().add(
                                DeleteMovement(
                                  id: id,
                                ),
                              );
                          Navigator.pop(context, true);
                        },
                      ),
                    ] */
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: isClosed
          ? null
          : Builder(
              builder: (context) {
                var movimientoDiferencia = 0.0;

                if (movimientos.isNotEmpty) {
                  for (var movimiento in movimientos) {
                    if (movimiento.suma == true) {
                      movimientoDiferencia +=
                          double.parse(movimiento.monto.toString());
                    } else {
                      movimientoDiferencia -=
                          double.parse(movimiento.monto.toString());
                    }
                  }
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: AppColors.blue,
                  child: Row(
                    children: [
                      const Text(
                        'Saldo Teórico: ',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        's/ $movimientoDiferencia',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
