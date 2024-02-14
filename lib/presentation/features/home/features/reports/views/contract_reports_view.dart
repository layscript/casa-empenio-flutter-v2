import 'dart:io';

import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/reports_detail_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/widgets.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ContractReportsView extends StatefulWidget {
  const ContractReportsView({super.key});

  @override
  State<ContractReportsView> createState() => _ContractReportsViewState();
}

class _ContractReportsViewState extends State<ContractReportsView> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(
          const GetLoadInitialDataContracts(
            end: null,
            start: null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final reportsBloc = context.watch<ReportsBloc>().state;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          //color: Colors.red,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            children: [
              Container(
                //color: Colors.yellow,
                width: double.infinity,
                height: constraints.maxHeight * 0.15,
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: LeadingDownloadButtonPaymentsContracts(
                        listIncrease: reportsBloc.listIncrease,
                        listLoans: reportsBloc.listLoans,
                      ),
                      title: FittedBox(
                        child: Text(
                          'Desde: ${DateFormat('dd/MM/yyyy').format(reportsBloc.startTimeContracts)} Hasta: ${DateFormat('dd/MM/yyyy').format(reportsBloc.endTimeContracts)}',
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

                          if (result != null && mounted) {
                            context.read<ReportsBloc>().add(
                                  GetLoadInitialDataContracts(
                                    start: result.start,
                                    end: result.end,
                                  ),
                                );
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ),
                    const Expanded(
                      child: ListChoiceChip(),
                    ),
                  ],
                ),
              ),
              Container(
                //color: Colors.purple,
                width: double.infinity,
                height: constraints.maxHeight * 0.70,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        //color: Colors.green,
                        width: double.infinity,
                        height: constraints.maxHeight * 0.30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Aumentos (${reportsBloc.listIncrease.length})',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              //color: Colors.pink,
                              width: double.infinity,
                              height: constraints.maxHeight * 0.25,
                              child: BlocBuilder<ReportsBloc, ReportsState>(
                                builder: (context, state) {
                                  switch (state.statusIncreases) {
                                    case ReportsStatus.error:
                                      return const Center(
                                        child: Text(
                                          'Ocurrió un error, intentelo de nuevo',
                                        ),
                                      );

                                    case ReportsStatus.loading:
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );

                                    case ReportsStatus.success:
                                      if (state.listIncrease.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No hay registros de aumentos',
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      } else {
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          itemCount:
                                              reportsBloc.listIncrease.length,
                                          itemBuilder: (context, index) {
                                            final aumento =
                                                reportsBloc.listIncrease[index];
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        BlocProvider(
                                                      create: (context) =>
                                                          LoansBloc(
                                                        customerRepository:
                                                            context.read(),
                                                        loansRepository:
                                                            context.read(),
                                                        cajaRepository:
                                                            context.read(),
                                                        preferences:
                                                            context.read(),
                                                        solicitudRepository:
                                                            context.read(),
                                                      ),
                                                      child: ReportsDetailView(
                                                        document: aumento
                                                                .prestamo
                                                                ?.cliente
                                                                ?.dni ??
                                                            '',
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 5),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                child: ListTile(
                                                  dense: true,
                                                  contentPadding:
                                                      const EdgeInsets.only(
                                                          left: 10, right: 0),
                                                  title: Text(
                                                    '${aumento.prestamo?.codigo.toString().padLeft(6, '0')} - S/. ${oCcy.format(double.parse(aumento.monto ?? '0.00'))}',
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Obs: ${aumento.observaciones}',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        '${aumento.prestamo?.cliente?.nombres} ${aumento.prestamo?.cliente?.apellidos}',
                                                      ),
                                                    ],
                                                  ),
                                                  trailing: Text(
                                                    DateFormat('dd/MM/yyyy')
                                                        .format(
                                                      DateTime.parse(
                                                        aumento.fecha ?? '',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    default:
                                      return const SizedBox();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        //color: Colors.yellow,
                        width: double.infinity,
                        height: constraints.maxHeight * 0.40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Prestamos (${reportsBloc.listLoans.length})',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              //color: Colors.red,
                              height: constraints.maxHeight * 0.35,
                              child: BlocBuilder<ReportsBloc, ReportsState>(
                                builder: (context, state) {
                                  switch (state.statusLoans) {
                                    case ReportsStatus.error:
                                      return const Center(
                                        child: Text(
                                          'Ocurrió un error, intentelo de nuevo',
                                        ),
                                      );

                                    case ReportsStatus.loading:
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );

                                    case ReportsStatus.success:
                                      if (state.listLoans.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'No hay registros de prestamos',
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      } else {
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          itemCount:
                                              reportsBloc.listLoans.length,
                                          itemBuilder: (context, index) {
                                            final prestamo =
                                                reportsBloc.listLoans[index];
                                            final fechaCreacion =
                                                DateTime.parse(
                                                        prestamo.fecha ?? '')
                                                    .toLocal();

                                            final fechaFormateada =
                                                DateFormat('dd/MM/yyyy - kk:mm')
                                                    .format(fechaCreacion);

                                            print(
                                                'prestamooo: ${prestamo.isRenewed}');

                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        BlocProvider(
                                                      create: (context) =>
                                                          LoansBloc(
                                                        customerRepository:
                                                            context.read(),
                                                        loansRepository:
                                                            context.read(),
                                                        cajaRepository:
                                                            context.read(),
                                                        preferences:
                                                            context.read(),
                                                        solicitudRepository:
                                                            context.read(),
                                                      ),
                                                      child: ReportsDetailView(
                                                        document: prestamo
                                                                ?.cliente
                                                                ?.dni ??
                                                            '',
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                    color: prestamo.estado ==
                                                            'CANCELADO'
                                                        ? Colors.red[50]
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                child: ListTile(
                                                  dense: true,
                                                  contentPadding:
                                                      const EdgeInsets.only(
                                                          left: 10, right: 0),
                                                  title: Text(
                                                    'Cod.: ${prestamo.codigo.toString().padLeft(6, '0')} - S/. ${oCcy.format(double.parse(prestamo.ganancia ?? '0.00') + double.parse(prestamo.monto ?? '0.00'))}',
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '$fechaFormateada - ${prestamo.estado}',
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        '${prestamo.cliente?.nombres} ${prestamo.cliente?.apellidos}',
                                                      )
                                                    ],
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          showDialog(
                                                            barrierDismissible:
                                                                false,
                                                            context: context,
                                                            builder: (_) {
                                                              return BlocProvider
                                                                  .value(
                                                                value: context.read<
                                                                    ReportsBloc>(),
                                                                child:
                                                                    ShowDetailsReportLoans(
                                                                  nroPrestamo:
                                                                      prestamo
                                                                          .codigo,
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons
                                                              .remove_red_eye_outlined,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                      if (prestamo.estado ==
                                                          'VIGENTE')
                                                        const Icon(
                                                          Icons.circle,
                                                          color: Colors.green,
                                                        ),
                                                      if (prestamo.estado ==
                                                          'VENCIDO')
                                                        const Icon(
                                                          Icons.circle,
                                                          color: Colors.red,
                                                        ),
                                                      if (prestamo.estado ==
                                                          'CANCELADO')
                                                        const Icon(
                                                          Icons.circle,
                                                          color: Colors.grey,
                                                        ),
                                                      if (prestamo.estado ==
                                                              'PAGADO' ||
                                                          prestamo.estado ==
                                                              'LIQUIDADO')
                                                        const Icon(
                                                          Icons.circle,
                                                          color:
                                                              Colors.blueGrey,
                                                        ),
                                                      IconButton(
                                                        onPressed: () async {
                                                          if (prestamo.estado != 'CANCELADO' &&
                                                              prestamo.estado !=
                                                                  'LIQUIDADO' &&
                                                              prestamo.estado !=
                                                                  'PAGADO') {
                                                            final result =
                                                                await showDialog<
                                                                    bool?>(
                                                              context: context,
                                                              barrierDismissible:
                                                                  false,
                                                              builder: (_) {
                                                                return BlocProvider
                                                                    .value(
                                                                  value: context
                                                                      .read<
                                                                          ReportsBloc>(),
                                                                  child:
                                                                      CancelDialogReportLoan(
                                                                    codigo:
                                                                        prestamo.codigo ??
                                                                            0,
                                                                  ),
                                                                );
                                                              },
                                                            );

                                                            if (result !=
                                                                    null &&
                                                                mounted) {
                                                              // Volver a cargar la data
                                                              context
                                                                  .read<
                                                                      ReportsBloc>()
                                                                  .add(
                                                                    const GetLoadInitialDataContracts(
                                                                      end: null,
                                                                      start:
                                                                          null,
                                                                    ),
                                                                  );
                                                            }
                                                          }
                                                        },
                                                        icon: Icon(
                                                          Icons.cancel,
                                                          color: prestamo
                                                                          .estado ==
                                                                      'CANCELADO' ||
                                                                  prestamo.estado ==
                                                                      'PAGADO' ||
                                                                  prestamo.estado ==
                                                                      'LIQUIDADO'
                                                              ? Colors.grey
                                                              : Colors.red,
                                                        ),
                                                      ),
                                                      if (prestamo.isRenewed ==
                                                          true)
                                                        const CircleAvatar(
                                                          radius: 10,
                                                          backgroundColor:
                                                              Colors.purple,
                                                          child: Text(
                                                            'R',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }

                                    default:
                                      return const SizedBox();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Container(
                //color: Colors.red,
                width: double.infinity,
                height: constraints.maxHeight * 0.15,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Aumentos Totales:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('S/. ${oCcy.format(reportsBloc.totalIncreases)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ganancias Totales:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('S/. ${oCcy.format(reportsBloc.totalProfits)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prestamos Totales:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'S/. ${oCcy.format(reportsBloc.totalLoans)}',
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
