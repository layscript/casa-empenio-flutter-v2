import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/views/movements_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OpenCajaView extends StatefulWidget {
  const OpenCajaView({super.key});

  @override
  State<OpenCajaView> createState() => _OpenCajaViewState();
}

class _OpenCajaViewState extends State<OpenCajaView> {
  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat("#,##0.00", "en_US");
    return BlocProvider(
      lazy: false,
      create: (context) => CajasBloc(
        cajaRepository: context.read(),
        expensesRepository: context.read(),
        preferences: context.read(),
      )..add(GetCajasOfTheDay()),
      child: Builder(builder: (context) {
        return BlocBuilder<CajasBloc, CajasState>(
          builder: (context, state) {
            switch (state.cajasStatus) {
              case CajasStatus.initial || CajasStatus.loading:
                return const ButtonStateLoading();

              case CajasStatus.error || CajasStatus.failure:
                return ButtonStateError(
                  onPressed: () {
                    context.read<CajasBloc>().add(GetCajasOfTheDay());
                  },
                );

              case CajasStatus.loaded || CajasStatus.success:
                final movimiento = state.movements;
                final cajaBloc = context.read<CajasBloc>();

                return SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 15),
                          if (movimiento != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lock_open, color: Colors.green),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Caja Abierta · Ya puedes registrar '
                                      'préstamos, pagos y gastos. Al terminar '
                                      'el día, ciérrala y cuenta el dinero.',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            Builder(builder: (context) {
                              double ingresos = 0.0;
                              double egresos = 0.0;
                              for (var e in movimiento.movimientos!) {
                                if (esAnulado(e)) continue;
                                if (e.suma == true) {
                                  ingresos += double.parse(e.monto ?? '0.00');
                                } else {
                                  egresos += double.parse(e.monto ?? '0.00');
                                }
                              }
                              final total = efectivoEnMano(movimiento.movimientos!);
                              return Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Efectivo que debe haber en caja',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'S/.${oCcy.format(total)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 32,
                                          ),
                                        ),
                                        const Text(
                                          'Apertura + cobros en efectivo − egresos en efectivo',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _MiniCaja(
                                        icono: Icons.arrow_downward,
                                        titulo: 'Ingresos',
                                        valor: 'S/.${oCcy.format(ingresos)}',
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 10),
                                      _MiniCaja(
                                        icono: Icons.arrow_upward,
                                        titulo: 'Egresos',
                                        valor: 'S/.${oCcy.format(egresos)}',
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  DesgloseMedios(
                                    movimientos: movimiento.movimientos!,
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(height: 15),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Column(
                                children: [
                                  CustomRow(
                                    label: 'Fecha',
                                    value: movimiento.fecha.toString(),
                                  ),
                                  CustomRow(
                                    label: 'Hora de Apertura',
                                    value: setTimeToLocal(
                                      movimiento.horaApertura ?? '',
                                    ),
                                  ),
                                  CustomRow(
                                    label: 'Usuario de Apertura',
                                    value: movimiento.usuarioApertura
                                            ?.fullName ??
                                        '',
                                  ),
                                  CustomRow(
                                    label: 'Monto de Apertura',
                                    value:
                                        "S/. ${oCcy.format(double.parse(movimiento.montoApertura ?? '0.00'))}",
                                  ),
                                  if (movimiento.totalIngresos != null)
                                    CustomRow(
                                      label: 'Total Ingresos',
                                      value: movimiento.totalIngresos.toString(),
                                    ),
                                  if (movimiento.totalEgresos != null)
                                    CustomRow(
                                      label: 'Total Egresos',
                                      value: movimiento.totalEgresos.toString(),
                                    ),
                                  CustomRow(
                                    label: 'Estado',
                                    value: movimiento.estado.toString(),
                                  ),
                                  if ((movimiento.observaciones ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    CustomRow(
                                      label: 'Observaciones',
                                      value: movimiento.observaciones.toString(),
                                    ),
                                ],
                              ),
                            ),
                            if (movimiento.movimientos!.isNotEmpty) ...[
                              const SizedBox(height: 15),
                              ElevatedButton(
                                style: const ButtonStyle(
                                  backgroundColor: MaterialStatePropertyAll(
                                    AppColors.primaryText,
                                  ),
                                ),
                                onPressed: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) {
                                      return BlocProvider.value(
                                        value: context.read<CajasBloc>(),
                                        child: const IncreaseBoxView(),
                                      );
                                    },
                                  );
                                  if (result != null && mounted) {
                                    context
                                        .read<CajasBloc>()
                                        .add(GetCajasOfTheDay());
                                  }
                                },
                                child: const Text(
                                  '➕ Aumentar Monto (meter más dinero a la caja)',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 15),
                              SecondaryButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return BlocProvider.value(
                                          value: cajaBloc,
                                          child: MovementsView(
                                            movimientos:
                                                movimiento.movimientos ?? [],
                                            id: movimiento.id ?? 0,
                                            isClosed: false,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Text(
                                  'Ver Movimientos (${movimiento.movimientos?.length})',
                                ),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStatePropertyAll(
                                    Colors.red[700],
                                  ),
                                ),
                                onPressed: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) {
                                      return BlocProvider.value(
                                        value: context.read<CajasBloc>(),
                                        child: const CloseBoxView(),
                                      );
                                    },
                                  );
                                  if (result != null && mounted) {
                                    context
                                        .read<CajasBloc>()
                                        .add(GetCajasOfTheDay());
                                  }
                                },
                                child: const Text(
                                  '🔒 Cerrar Caja (contar el dinero y terminar el día)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.lock, color: Colors.red, size: 44),
                                  SizedBox(height: 8),
                                  Text(
                                    'Caja Cerrada',
                                    style: TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Para registrar préstamos, pagos o gastos '
                                    'primero debes abrir la caja con el dinero '
                                    'con el que empiezas el día.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStatePropertyAll(
                                  Colors.red[700],
                                ),
                              ),
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) {
                                    return BlocProvider.value(
                                      value: context.read<CajasBloc>(),
                                      child: const OpenBoxView(),
                                    );
                                  },
                                );
                                if (result != null && mounted) {
                                  context
                                      .read<CajasBloc>()
                                      .add(GetCajasOfTheDay());
                                }
                              },
                              child: const Text(
                                '🔓 Abrir Caja',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                );
            }
          },
        );
      }),
    );
  }
}

class CustomRow extends StatelessWidget {
  const CustomRow({
    super.key,
    required this.label,
    required this.value,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCaja extends StatelessWidget {
  const _MiniCaja({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.color,
  });
  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icono, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 12)),
                  Text(
                    valor,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
