import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/views/movements_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CajasView extends StatefulWidget {
  const CajasView({super.key});

  @override
  State<CajasView> createState() => _CajasViewState();
}

class _CajasViewState extends State<CajasView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => CajasBloc(
        cajaRepository: context.read(),
      )..add(GetAllCajas()),
      child: Builder(builder: (context) {
        return BlocConsumer<CajasBloc, CajasState>(
          listener: (context, state) {
            if (state.isCajasLoading) {
              OverlayLoader.show(context);
            } else {
              OverlayLoader.hide();
              if (state.isCajasError) {
                ErrorSnackbar.show(context, state.error ?? '');
              }
            }
          },
          builder: (context, state) {
            print('sadkljaklsd: ${state.movements}');

            return Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: MediaQuery.of(context).size.height * 0.9,
                    padding: const EdgeInsets.only(
                      bottom: 120,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              'Lista de Cajas',
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
                                return ExpansionTile(
                                  title: Text(
                                    'Caja N°: ${caja.id}',
                                  ),
                                  subtitle: Text(
                                    //'Fecha: ${DateFormat('dd/MM/yyyy - hh:mm').format(DateTime.parse(caja?.createdAt ?? '').toLocal())}',
                                    'Estado: ${caja.estado}',
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
                                    if (caja.estado != 'Abierta') ...[
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
                                            'S/.${caja.montoApertura}',
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
                                            '${caja.fecha} / ${caja.horaApertura}',
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
                                            'S/.${caja.montoApertura}',
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
                                            'S/.${caja.montoCierreTeorico}',
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
                                            'S/.${caja.montoDiferencia}',
                                          ),
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
                                          Text(
                                            '${caja.observaciones}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    if (caja.movimientos!.isNotEmpty)
                                      SecondaryButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return MovementsView(
                                                  movimientos:
                                                      caja.movimientos ?? [],
                                                  id: caja.id ?? 0,
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Ver Movimientos (${caja.movimientos?.length})',
                                        ),
                                      )
                                  ],
                                );
                              },
                            ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    top: null,
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        boxShadow: defaultBoxShadow,
                      ),
                      child: Center(
                        child: PrimaryButton(
                          onPressed: () async {
                            final result = await showDialog<bool?>(
                              barrierDismissible: false,
                              context: context,
                              builder: (_) {
                                return BlocProvider.value(
                                  value: context.read<CajasBloc>(),
                                  child: state.movements == null
                                      ? const OpenBoxView()
                                      : const CloseBoxView(),
                                );
                              },
                            );

                            if (result != null && mounted) {
                              context.read<CajasBloc>()
                                ..add(
                                  GetAllCajas(),
                                )
                                ..add(GetCajasOfTheDay());
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FaIcon(
                                state.movements == null
                                    ? FontAwesomeIcons.circlePlus
                                    : FontAwesomeIcons.xmark,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                state.movements == null
                                    ? 'Abrir Caja'
                                    : 'Cerrar Caja (Nro° ${state.movements?.id})',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
