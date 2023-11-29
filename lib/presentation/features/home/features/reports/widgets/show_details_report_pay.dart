import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/show_details_report_loans.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ShowDetailsReportPay extends StatefulWidget {
  const ShowDetailsReportPay({
    super.key,
    required this.idPago,
  });
  final int? idPago;

  @override
  State<ShowDetailsReportPay> createState() => _ShowDetailsReportPayState();
}

class _ShowDetailsReportPayState extends State<ShowDetailsReportPay> {
  @override
  void initState() {
    super.initState();
    if (widget.idPago != null) {
      context.read<ReportsBloc>().add(GetDetailsReportPay(widget.idPago!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        if (state.isReportsDetailsLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state.isReportsDetailsError) {
          return const Center(
            child: Text('Ocurrió un error, intentelo de nuevo'),
          );
        } else if (state.isReportsDetailsSuccess) {
          final pago = state.paymentDetails;
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Prestamo: #${pago?.prestamo?.codigo.toString().padLeft(6, '0')}'),
                IconButton(
                  onPressed: () {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (_) {
                        return BlocProvider.value(
                          value: context.read<ReportsBloc>(),
                          child: ShowDetailsReportLoans(
                            nroPrestamo: pago?.prestamo?.codigo,
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_circle_right,
                    color: Colors.blue,
                  ),
                )
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width - 20,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${pago?.prestamo?.cliente?.nombres} ${pago?.prestamo?.cliente?.apellidos}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('DNI: ${pago?.prestamo?.cliente?.dni}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Telf: ${pago?.prestamo?.cliente?.celular}',
                        ),
                        IconButton(
                          onPressed: () async {
                            await customLaunchUrl(
                              Uri(
                                scheme: 'tel',
                                path: pago?.prestamo?.cliente?.celular,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.call,
                            color: Colors.green,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fecha de Pago',
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(
                              DateTime.parse(pago?.fecha ?? '').toLocal()),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Monto Pagado',
                        ),
                        Text(
                            'S/. ${oCcy.format(double.parse(pago?.monto ?? '0.00'))}')
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 20, color: Colors.black),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cobrado por: ',
                        ),
                        if (pago?.usuario == null)
                          const Text('Sin registro')
                        else
                          Text(
                              '${pago?.usuario?.nombre} ${pago?.usuario?.apellido}')
                      ],
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Aceptar',
                ),
              ),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }
}
