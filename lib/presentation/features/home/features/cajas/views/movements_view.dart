import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/leading_download_cajas.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/widgets.dart';
import 'package:flutter/material.dart';

final list = [
  'Venta',
  'Préstamo',
  'Pago personal',
  'Pago Otros',
  'Pago',
  'Gasto',
  'Cierre de caja',
  'Aumento de préstamo',
  'Apertura de caja',
];

class MovementsView extends StatefulWidget {
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
  State<MovementsView> createState() => _MovementsViewState();
}

class _MovementsViewState extends State<MovementsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingresos = widget.movimientos.where((e) => e.suma == true).toList();
    final egresos = widget.movimientos.where((e) => e.suma != true).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: const Text('Movimientos de Caja'),
        actions: [
          LeadingDownloadCajas(
            movimientos: widget.movimientos,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(
                  25.0,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    25.0,
                  ),
                  color: Colors.green,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                tabs: const [
                  Tab(
                    text: 'Ingresos',
                  ),
                  Tab(
                    text: 'Egresos',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  RevenueBox(
                    movimientos: ingresos,
                    types: list,
                  ),
                  CajaEgresos(
                    movimientos: egresos,
                    types: list,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      /*   bottomNavigationBar: isClosed
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
    */
    );
  }
}

class CustomChip extends StatelessWidget {
  const CustomChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final Function(bool)? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Colors.blue[400],
    );
  }
}
