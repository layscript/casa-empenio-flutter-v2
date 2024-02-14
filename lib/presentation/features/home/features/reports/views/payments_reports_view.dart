import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/reports_detail_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class PaymentsReportsView extends StatefulWidget {
  const PaymentsReportsView({super.key});

  @override
  State<PaymentsReportsView> createState() => _PaymentsReportsViewState();
}

class _PaymentsReportsViewState extends State<PaymentsReportsView> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(
          const GetLoadInitialDataPayments(
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
                height: constraints.maxHeight * 0.08,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: LeadingDownloadButtonPaymentsReports(
                    listClosedLoans: reportsBloc.listClosedLoans,
                    listPayments: reportsBloc.listPayments,
                  ),
                  title: FittedBox(
                    child: Text(
                      'Desde: ${DateFormat('dd/MM/yyyy').format(reportsBloc.startTimePayments)} Hasta: ${DateFormat('dd/MM/yyyy').format(reportsBloc.endTimePayments)}',
                    ),
                  ),
                  trailing: IconButton(
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final result = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2022, 1, 1),
                        lastDate: DateTime(2030, 12, 31),
                        currentDate: DateTime.now(),
                        saveText: 'Done',
                      );

                      if (result != null && mounted) {
                        context.read<ReportsBloc>().add(
                              GetLoadInitialDataPayments(
                                start: result.start,
                                end: result.end,
                              ),
                            );
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                  ),
                ),
              ),
              Container(
                //color: Colors.purple,
                width: double.infinity,
                height: constraints.maxHeight * 0.40,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Prestamos Cerrados (${reportsBloc.listClosedLoans.length})',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                            height: constraints.maxHeight * 0.30,
                            child: BlocBuilder<ReportsBloc, ReportsState>(
                              builder: (context, state) {
                                switch (state.statusClosedLoans) {
                                  case ReportsStatus.error:
                                    return const Center(
                                      child: Text(
                                          'Ocurrió un error, intentelo de nuevo'),
                                    );

                                  case ReportsStatus.loading:
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );

                                  case ReportsStatus.success:
                                    if (state.listClosedLoans.isEmpty) {
                                      return const Center(
                                        child: Text(
                                          'No hay registros de prestamos cerrados',
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    } else {
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        itemCount:
                                            reportsBloc.listClosedLoans.length,
                                        itemBuilder: (_, index) {
                                          final prestamo = reportsBloc
                                              .listClosedLoans[index];
                                          final fechaCreacion = DateTime.parse(
                                              prestamo.fecha ?? '');
                                          final fechaFormateada =
                                              DateFormat('dd/MM/yyyy - kk:mm')
                                                  .format(fechaCreacion);

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => BlocProvider(
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
                                                              ?.cliente?.dni ??
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
                                                color: prestamo.estado ==
                                                        'CANCELADO'
                                                    ? Colors.red[50]
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: ListTile(
                                                dense: true,
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                  left: 10,
                                                  right: 0,
                                                ),
                                                title: Text(
                                                  'Cod.: ${prestamo.codigo.toString().padLeft(6, '0')} - S/.${oCcy.format(double.parse(prestamo.ganancia ?? '0.00') + double.parse(prestamo.monto ?? '0.00'))}',
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      '$fechaFormateada- ${prestamo.estado}',
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      '${prestamo.cliente?.nombres} ${prestamo.cliente?.apellidos}',
                                                    ),
                                                  ],
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (prestamo.cerrado ==
                                                            true &&
                                                        prestamo.estado !=
                                                            'CANCELADO')
                                                      IconButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () {
                                                          if (prestamo.boleta ==
                                                              null) {
                                                            final dniCustomer =
                                                                prestamo.cliente
                                                                    ?.dni;

                                                            showDialog<bool>(
                                                              barrierDismissible:
                                                                  false,
                                                              context: context,
                                                              builder: (_) {
                                                                return BlocProvider(
                                                                  create: (context) =>
                                                                      LoansBloc(
                                                                    customerRepository:
                                                                        context
                                                                            .read(),
                                                                    loansRepository:
                                                                        context
                                                                            .read(),
                                                                    cajaRepository:
                                                                        context
                                                                            .read(),
                                                                    preferences:
                                                                        context
                                                                            .read(),
                                                                    solicitudRepository:
                                                                        context
                                                                            .read(),
                                                                  ),
                                                                  child:
                                                                      ShowDialogBillingLoan(
                                                                    nroPrestamo:
                                                                        prestamo
                                                                            .codigo,
                                                                    dniCustomer:
                                                                        dniCustomer,
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          } else {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) {
                                                                  return PdfPreviewFacturaPage(
                                                                    url: prestamo
                                                                            .boleta
                                                                            ?.pdf ??
                                                                        '',
                                                                    id: prestamo
                                                                            .codigo ??
                                                                        0,
                                                                    tipo:
                                                                        'prestamo',
                                                                    notaCredito:
                                                                        prestamo
                                                                            .notaCredito,
                                                                  );
                                                                },
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        icon: Icon(
                                                          Icons.description,
                                                          color: prestamo
                                                                      .boleta ==
                                                                  null
                                                              ? Colors.blue
                                                              : prestamo
                                                                      .notaCredito!
                                                                      .isEmpty
                                                                  ? Colors.green
                                                                  : Colors
                                                                      .red[400],
                                                        ),
                                                      ),
                                                    if (prestamo.estado ==
                                                        'LIQUIDADO')
                                                      IconButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () async {
                                                          final result =
                                                              await showDialog<
                                                                  bool?>(
                                                            barrierDismissible:
                                                                false,
                                                            context: context,
                                                            builder: (_) {
                                                              return BlocProvider
                                                                  .value(
                                                                value: context.read<
                                                                    ReportsBloc>(),
                                                                child: AnularDialogReport(
                                                                    codigo: prestamo
                                                                        .codigo),
                                                              );
                                                            },
                                                          );

                                                          if (result != null &&
                                                              mounted) {
                                                            await Future.delayed(
                                                                    const Duration(
                                                                        milliseconds:
                                                                            300))
                                                                .then((value) {
                                                              context
                                                                  .read<
                                                                      ReportsBloc>()
                                                                  .add(
                                                                    const GetLoadInitialDataPayments(
                                                                      end: null,
                                                                      start:
                                                                          null,
                                                                    ),
                                                                  );
                                                            });
                                                          }
                                                        },
                                                        icon: const Icon(
                                                          Icons.delete_forever,
                                                          color: Colors.red,
                                                        ),
                                                      ),
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
                            ))
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                //color: Colors.blue,
                width: double.infinity,
                height: constraints.maxHeight * 0.44,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prestamos (${reportsBloc.listPayments.length})',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                            height: constraints.maxHeight * 0.30,
                            child: BlocBuilder<ReportsBloc, ReportsState>(
                              builder: (context, state) {
                                switch (state.statusPayments) {
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
                                    if (state.listPayments.isEmpty) {
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
                                            reportsBloc.listPayments.length,
                                        itemBuilder: (context, index) {
                                          final pago =
                                              reportsBloc.listPayments[index];
                                          final fechaCreacion =
                                              DateTime.parse(pago.fecha ?? '')
                                                  .toLocal();
                                          final fechaFormateada =
                                              DateFormat('dd/MM/yyyy - kk:mm')
                                                  .format(fechaCreacion);

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => BlocProvider(
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
                                                      document: pago.prestamo
                                                              ?.cliente?.dni ??
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
                                                    BorderRadius.circular(10),
                                              ),
                                              child: ListTile(
                                                dense: true,
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                  left: 10,
                                                  right: 0,
                                                ),
                                                title: Text(
                                                  'Cod.: ${pago.prestamo?.codigo.toString().padLeft(6, '0')} - S/.${oCcy.format(double.parse(pago.monto ?? '0.00'))}',
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      fechaFormateada,
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      '${pago.prestamo?.cliente?.nombres} ${pago.prestamo?.cliente?.apellidos}',
                                                    ),
                                                  ],
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder: (_) {
                                                            return BlocProvider
                                                                .value(
                                                              value: context.read<
                                                                  ReportsBloc>(),
                                                              child:
                                                                  ShowDetailsReportPay(
                                                                idPago: pago.id,
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
                                                    if (pago.prestamo
                                                            ?.isRenewed ==
                                                        true)
                                                      const CircleAvatar(
                                                        radius: 10,
                                                        backgroundColor:
                                                            Colors.purple,
                                                        child: Text(
                                                          'R',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                //color: Colors.red,
                width: double.infinity,
                height: constraints.maxHeight * 0.08,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pagos Totales ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('S/. ${oCcy.format(reportsBloc.totalPayments)}')
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
