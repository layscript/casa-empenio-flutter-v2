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
          switch (state.status) {
            case PerdonadosStatus.initial:
              return const SizedBox();

            case PerdonadosStatus.error:
              return const SizedBox();

            case PerdonadosStatus.loading:
              return const SizedBox();

            case PerdonadosStatus.success:
              return Container(
                color: Colors.yellow,
                height: 300,
                width: double.infinity,
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today),
                      ),
                      contentPadding: EdgeInsets.zero,
                      title: const FittedBox(
                        child: Text(
                          '123123',
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ),
                    /* ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      /*  leading: LeadingDownloadButtonPaymentsContracts(
                        listIncrease: reportsBloc.listIncrease,
                        listLoans: reportsBloc.listLoans,
                      ), */
                      title: FittedBox(
                        child: Text(
                          //'Desde: ${DateFormat('dd/MM/yyyy').format(reportsBloc.startTimeContracts)} Hasta: ${DateFormat('dd/MM/yyyy').format(reportsBloc.endTimeContracts)}',
                          '',
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

                          /*  if (result != null && mounted) {
                            context.read<ReportsBloc>().add(
                                  GetLoadInitialDataContracts(
                                    start: result.start,
                                    end: result.end,
                                  ),
                                );
                          } */
                        },
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  */
                  ],
                ),
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }
}
