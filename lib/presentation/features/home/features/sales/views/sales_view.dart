// ignore_for_file: prefer_is_empty

import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/bloc/sales_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/views/add_sales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => SalesBloc(
        salesRepository: context.read(),
        customerRepository: context.read(),
        productRepository: context.read(),
        cajaRepository: context.read(),
      )
        ..add(
          const GetListSales(
            start: null,
            end: null,
          ),
        )
        ..add(
          GetCashSalesStatus(),
        ),
      child: Builder(builder: (context) {
        return BlocConsumer<SalesBloc, SalesState>(
          listener: (context, state) {
            //if (false) {
            if (state.openBox) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (_) {
                  return AlertGoToCaja(
                    onPressed: () {
                      context.read<HomeBloc>().add(GoToOpenCaja());
                      Navigator.pop(context);
                    },
                  );
                },
              );
            }
          },
          builder: (context, state) {
            switch (state.status) {
              case SalesStatus.loading:
                return const Center(
                  child: CircularProgressIndicator(),
                );

              case SalesStatus.error:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ocurrió un error, vuelva a intentarlo',
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () => context
                              .read<SalesBloc>()
                              .add(const GetListSales(start: null, end: null)),
                          child: const Text('Cargar'),
                        ),
                      ],
                    ),
                  ),
                );

              case SalesStatus.success:
                return Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy').format(
                              state.startTimeSales,
                            ),
                          ),
                          const Icon(Icons.arrow_forward, size: 20),
                          Text(
                            DateFormat('dd/MM/yyyy').format(
                              state.endTimeSales,
                            ),
                          ),
                          const SizedBox(width: 30),
                          IconButton(
                            onPressed: () async {
                              final result = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2022, 1, 1),
                                  lastDate: DateTime(2030, 12, 31),
                                  currentDate: DateTime.now(),
                                  saveText: 'Done');

                              if (result != null && mounted) {
                                context.read<SalesBloc>().add(
                                      GetListSales(
                                        start: result.start,
                                        end: result.end,
                                      ),
                                    );
                              }
                            },
                            icon: const FaIcon(
                              FontAwesomeIcons.calendar,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 3),
                          IconButton(
                            onPressed: () async {
                              final result = await Navigator.push<bool?>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) {
                                    return BlocProvider.value(
                                      value: context.read<SalesBloc>(),
                                      child: const AddFormSales(),
                                    );
                                  },
                                ),
                              );

                              if (result != null && mounted) {
                                context.read<SalesBloc>().add(
                                      const GetListSales(
                                        start: null,
                                        end: null,
                                      ),
                                    );
                              }
                            },
                            icon: const FaIcon(
                              FontAwesomeIcons.circlePlus,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ventas (${state.listSales.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Expanded
                      Expanded(
                        child: state.listSales.isEmpty
                            ? const Center(
                                child: Text('No hay registros'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 10),
                                itemCount: state.listSales.length,
                                itemBuilder: (context, index) {
                                  final venta = state.listSales[index];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.only(
                                        left: 0, right: 0),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${venta.cod}'),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${venta.cliente?.nombres?.toUpperCase()} ${venta.cliente?.apellidos?.toUpperCase()}',
                                          style: const TextStyle(
                                            color: AppColors.secondaryText,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        )
                                      ],
                                    ),
                                    subtitle: Row(
                                      children: [
                                        const Text('Monto Total: '),
                                        Text(
                                          'S/. ${venta.total}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                          ),
                                        ),
                                        const Text(' - '),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(
                                            DateTime.parse(
                                                venta.boletaVenta?.fecha ?? ''),
                                          ),
                                          style: const TextStyle(
                                              color: Colors.blue),
                                        )
                                      ],
                                    ),
                                    trailing: IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PdfPreviewFacturaPage(
                                              url: venta.boletaVenta?.pdf ?? '',
                                              id: venta.id,
                                              tipo: 'venta',
                                              notaCredito: venta.notaCredito,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: FaIcon(
                                        FontAwesomeIcons.fileInvoice,
                                        color: venta.notaCredito?.length == 0
                                            ? Colors.purple
                                            : Colors.red[400],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ventas Totales:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'S/. ${oCcy.format(state.totalSales)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                );

              default:
                return const SizedBox();
            }
          },
        );
      }),
    );
  }
}
