import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/views/movements_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CajasView extends StatefulWidget {
  const CajasView({super.key});

  @override
  State<CajasView> createState() => _CajasViewState();
}

class _CajasViewState extends State<CajasView> {
  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat("#,##0.00", "en_US");

    return BlocProvider(
      lazy: false,
      create: (context) => CajasBloc(
        cajaRepository: context.read(),
        expensesRepository: context.read(),
      )..add(GetAllCajas()),
      child: Builder(builder: (context) {
        return BlocBuilder<CajasBloc, CajasState>(
          builder: (context, state) {
            switch (state.cajasStatus) {
              case CajasStatus.initial || CajasStatus.loading:
                return const ButtonStateLoading();

              case CajasStatus.error || CajasStatus.failure:
                return ButtonStateError(
                  onPressed: () {
                    context.read<CajasBloc>().add(GetAllCajas());
                  },
                );

              case CajasStatus.loaded || CajasStatus.success:
                final cajaBloc = context.read<CajasBloc>();
                return SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Lista de Cajas (cerradas)',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (state.listCajas != null)
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: 10,
                            ),
                            shrinkWrap: true,
                            itemCount: state.listCajas!.length,
                            itemBuilder: (context, index) {
                              final caja = state.listCajas![index];

                              final valor = caja == null
                                  ? '0.00'
                                  : double.parse(caja.montoDiferencia!) != 0
                                      ? double.parse(caja.montoDiferencia!) * -1
                                      : 0;

                              return Container(
                                color: valor == 0
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                child: ExpansionTile(
                                  backgroundColor: valor == 0
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  title: Text(
                                    'Caja N°: ${caja?.id}',
                                  ),
                                  subtitle: Text(
                                    //'Fecha: ${DateFormat('dd/MM/yyyy - hh:mm').format(DateTime.parse(caja?.createdAt ?? '').toLocal())}',
                                    'Estado: ${caja?.estado}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  trailing: SizedBox(
                                    width: 150,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Dif.: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'S/.${oCcy.format(valor)}',
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                        )
                                      ],
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ).copyWith(
                                    bottom: 20,
                                  ),
                                  children: [
                                    if (caja?.estado != 'Abierta') ...[
                                      Row(
                                        children: [
                                          const Text(
                                            'Monto de Apertura: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'S/.${caja?.montoApertura}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text(
                                            'Usuario de Apertura: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            caja?.usuarioApertura?.fullName ?? '',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text(
                                            'Usuario de Cierre: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            caja?.usuarioCierre?.fullName ?? '',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text(
                                            'Fecha y Hora de Apertura: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${caja?.fecha} / ${caja?.horaApertura}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text(
                                            'Monto de Cierre Real: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'S/.${caja?.montoCierreReal}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text(
                                            'Monto de Cierre Teórico: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'S/.${caja?.montoCierreTeorico}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text(
                                            'Monto de Cierre Diferencia: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'S/.${oCcy.format(valor)}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Observaciones: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              '${caja?.observaciones}',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text(
                                            'Total Ingresos: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            caja?.totalIngresos ?? '',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Text(
                                            'Total Egresos: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            caja?.totalEgresos ?? '',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    if (caja != null &&
                                        caja.movimientos!.isNotEmpty)
                                      SecondaryButton(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return BlocProvider.value(
                                                  value: cajaBloc,
                                                  child: MovementsView(
                                                    movimientos:
                                                        caja.movimientos ?? [],
                                                    id: caja.id ?? 0,
                                                    isClosed: true,
                                                  ),
                                                );
                                              },
                                            ),
                                          );

                                          if (mounted) {
                                            context.read<CajasBloc>().add(
                                                  GetAllCajas(),
                                                );
                                          }
                                        },
                                        child: Text(
                                          'Ver Movimientos (${caja.movimientos?.length})',
                                        ),
                                      )
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 15),
                      ],
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
