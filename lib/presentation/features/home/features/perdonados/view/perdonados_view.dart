import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class PerdonadosView extends StatelessWidget {
  const PerdonadosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => PerdonadosBloc(
        reportsRepository: context.read(),
        preferences: context.read(),
      )..add(
          const GetAllPerdonados(
            fin: null,
            inicio: null,
          ),
        ),
      child: BlocBuilder<PerdonadosBloc, PerdonadosState>(
        builder: (context, state) {
          final perdonadosBloc = context.read<PerdonadosBloc>();

          switch (state.status) {
            case PerdonadosStatus.initial || PerdonadosStatus.loading:
              return const Center(
                child: CircularProgressIndicator(),
              );

            case PerdonadosStatus.error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message ?? 'Ocurrió un error'),
                      const SizedBox(height: 10),
                      SecondaryButton(
                        onPressed: () {
                          perdonadosBloc.add(
                            const GetAllPerdonados(inicio: null, fin: null),
                          );
                        },
                        child: const Text(
                          'Intentar de nuevo',
                        ),
                      ),
                    ],
                  ),
                ),
              );

            case PerdonadosStatus.success:
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 15),
                        const Text(
                          'Lista de Perdonados',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 15),
                        ListTile(
                          dense: true,
                          leading: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.calendar_today),
                          ),
                          contentPadding: EdgeInsets.zero,
                          title: FittedBox(
                            child: Text(
                              'Desde: ${DateFormat('dd/MM/yyyy').format(state.startTimePayments)} Hasta: ${DateFormat('dd/MM/yyyy').format(state.endTimePayments)}',
                            ),
                          ),
                          trailing: IconButton(
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final result = await showDateRangePicker(
                                locale: const Locale('es'),
                                context: context,
                                firstDate: DateTime(2022, 1, 1),
                                lastDate: DateTime(2030, 12, 31),
                                currentDate: DateTime.now(),
                                saveText: 'Done',
                              );
                              if (result != null) {
                                perdonadosBloc.add(
                                  GetAllPerdonados(
                                    inicio: result.start,
                                    fin: result.end,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (state.listPerdonados.isEmpty)
                          const Center(
                            child: Text(
                              'No hay perdonados en la fecha seleccionada',
                            ),
                          ),
                        ListView.separated(
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          shrinkWrap: true,
                          itemCount: state.listPerdonados.length,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final perdonado = state.listPerdonados[index];
                            return ListTile(
                              title: Text(
                                'Cod: ${perdonado.prestamo.codigoFormateado} -  s/.${perdonado.monto}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy - hh:mm').format(
                                        DateTime.parse(
                                                perdonado.createdAt ?? '')
                                            .toLocal()),
                                  ),
                                  Text(
                                    '${perdonado.prestamo.cliente?.nombres ?? ''} ${perdonado.prestamo.cliente?.apellidos ?? ''}',
                                    maxLines: 1,
                                    style: const TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Builder(builder: (context) {
                      double total = 0.0;
                      for (var mov in state.listPerdonados) {
                        total += double.parse(mov.monto);
                      }

                      return Container(
                        decoration: BoxDecoration(
                            color: AppColors.blue,
                            boxShadow: defaultBoxShadow,
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(7),
                        margin: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Text(
                              'Total: ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              's/. ${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  )
                ],
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
