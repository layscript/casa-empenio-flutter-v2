import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MovementsView extends StatelessWidget {
  const MovementsView({
    super.key,
    required this.id,
    required this.movimientos,
  });

  final int id;
  final List<MovimientosEntity> movimientos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: Text('Movimientos de Caja ($id)'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: movimientos.length,
              itemBuilder: (context, index) {
                final movimiento = movimientos[index];
                return ExpansionTile(
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
                          'Observaciones: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(movimiento?.observaciones ?? ''),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
