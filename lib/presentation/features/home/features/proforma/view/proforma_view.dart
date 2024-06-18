// ignore_for_file: prefer_is_empty

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/proforma/bloc/proforma_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/proforma/view/add_proforma.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ProformaView extends StatefulWidget {
  const ProformaView({super.key});

  @override
  State<ProformaView> createState() => _ProformaViewState();
}

class _ProformaViewState extends State<ProformaView> {
  @override
  Widget build(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();
    final preferences = context.read<Preferences>();

    return BlocProvider(
      lazy: false,
      create: (context) => ProformaBloc(
        proformaRepository: context.read(),
        customerRepository: context.read(),
        productRepository: context.read(),
        cajaRepository: context.read(),
        preferences: context.read(),
      )
        ..add(
          GetListProformas(
            start: null,
            end: null,
            sucursalId: preferences.token?.sucursal?.id ?? 1,
          ),
        )
        ..add(
          GetCashProformasStatus(),
        ),
      child: Builder(builder: (context) {
        return BlocConsumer<ProformaBloc, ProformaState>(
          listener: (context, state) {
            //if (false) {
            if (state.openBox == true) {
              //if (false) {
              showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return const AlertGoToCaja();
                },
              ).then((value) {
                homeBloc.add(GoToOpenCaja());
              });
            }
          },
          builder: (context, state) {
            final proformaBloc = context.read<ProformaBloc>();
            switch (state.status) {
              case ProformaStatus.loading:
                return const Center(
                  child: CircularProgressIndicator(),
                );

              case ProformaStatus.error:
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
                          onPressed: () => proformaBloc.add(
                            GetListProformas(
                              start: null,
                              end: null,
                              sucursalId: preferences.token?.sucursal?.id ?? 1,
                            ),
                          ),
                          child: const Text('Cargar'),
                        ),
                      ],
                    ),
                  ),
                );

              case ProformaStatus.success:
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
                                proformaBloc.add(
                                  GetListProformas(
                                    start: result.start,
                                    end: result.end,
                                    sucursalId:
                                        preferences.token?.sucursal?.id ?? 1,
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
                                      value: proformaBloc,
                                      child: const AddFormProforma(),
                                    );
                                  },
                                ),
                              );

                              if (result != null) {
                                proformaBloc.add(
                                  GetListProformas(
                                    start: null,
                                    end: null,
                                    sucursalId:
                                        preferences.token?.sucursal?.id ?? 1,
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
                        'Proformas (${state.listSales.length})',
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
                                          '${venta.cliente?.customerFullName}',
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
                                            DateTime.parse(venta.fecha ?? ''),
                                          ),
                                          style: const TextStyle(
                                              color: Colors.blue),
                                        )
                                      ],
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
                            'Proformas Totales:',
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
