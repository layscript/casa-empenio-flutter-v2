import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/views/movements_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/close_box.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/open_box.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OpenCajaView extends StatefulWidget {
  const OpenCajaView({super.key});

  @override
  State<OpenCajaView> createState() => _OpenCajaViewState();
}

class _OpenCajaViewState extends State<OpenCajaView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => CajasBloc(
        cajaRepository: context.read(),
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
                print('asdjkasd: ${movimiento?.movimientos}');

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
                            const Text(
                              'Caja Abierta',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 15),
                            CustomRow(
                              label: 'Fecha',
                              value: movimiento.fecha.toString(),
                            ),
                            CustomRow(
                              label: 'Hora de Apertura',
                              value: movimiento.horaApertura.toString(),
                            ),
                            CustomRow(
                              label: 'Usuario de Apertura',
                              value: movimiento.usuarioApertura.toString(),
                            ),
                            CustomRow(
                              label: 'Monto de Apertura',
                              value: movimiento.montoApertura.toString(),
                            ),
                            CustomRow(
                              label: 'Total Ingresos',
                              value: movimiento.totalIngresos.toString(),
                            ),
                            CustomRow(
                              label: 'Total Egresos',
                              value: movimiento.totalEgresos.toString(),
                            ),
                            CustomRow(
                              label: 'Estado',
                              value: movimiento.estado.toString(),
                            ),
                            CustomRow(
                              label: 'Observaciones',
                              value: movimiento.observaciones.toString(),
                            ),
                            if (movimiento.movimientos!.isNotEmpty) ...[
                              const SizedBox(height: 15),
                              SecondaryButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return MovementsView(
                                          movimientos:
                                              movimiento.movimientos ?? [],
                                          id: movimiento.id ?? 0,
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
                                  'Cerrar Caja',
                                ),
                              ),
                            ],
                          ] else ...[
                            const Text(
                              'Caja Cerrada',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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
                                'Abrir Caja',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
