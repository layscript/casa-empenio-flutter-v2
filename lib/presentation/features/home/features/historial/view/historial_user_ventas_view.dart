import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class HistorialUserVentasView extends StatefulWidget {
  const HistorialUserVentasView({
    super.key,
    required this.userId,
  });
  final int userId;

  @override
  State<HistorialUserVentasView> createState() =>
      _HistorialUserVentasViewState();
}

class _HistorialUserVentasViewState extends State<HistorialUserVentasView> {
  @override
  void initState() {
    super.initState();
    callApi();
  }

  void callApi() {
    context.read<HistorialBloc>().add(
          GetHistorialUserVentasEvent(
            userId: widget.userId,
            end: null,
            start: null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HistorialBloc>().state;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: const Text('Ventas del Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Calendario
              const SizedBox(height: 10),
              ListTile(
                dense: true,
                leading: const Icon(
                  Icons.calendar_today,
                ),
                title: FittedBox(
                  child: Text(
                    'Desde: ${DateFormat('dd/MM/yyyy').format(state.startSales)} Hasta: ${DateFormat('dd/MM/yyyy').format(state.endSales)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
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
                      context.read<HistorialBloc>().add(
                            GetHistorialUserVentasEvent(
                              start: result.start,
                              end: result.end,
                              userId: widget.userId,
                            ),
                          );
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 30),
              BlocBuilder<HistorialBloc, HistorialState>(
                builder: (context, state) {
                  switch (state.historialUserVentasStatus) {
                    case HistorialStatus.loading || HistorialStatus.initial:
                      return const ButtonStateLoading();
          
                    case HistorialStatus.error:
                      return ButtonStateError(
                        onPressed: () {
                          callApi();
                        },
                      );
          
                    case HistorialStatus.loaded:
                      final listSales = state.listSales;
                      if (listSales!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay ventas registradas por el usuario',
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'Ventas (${listSales.length})',
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(
                                    height: 10,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: listSales.length,
                                  itemBuilder: (context, index) {
                                    final venta = listSales[index];
                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.only(
                                          left: 0, right: 0),
                                      title: SingleChildScrollView(
                                        child: Column(
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
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'USUARIO: ${venta.usuario?.nombre.toUpperCase()} ${venta.usuario?.apellido.toUpperCase()}',
                                              style: const TextStyle(
                                                color: AppColors.secondaryText,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
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
                                                  venta.boletaVenta?.fecha ??
                                                      ''),
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
                                                url: venta.boletaVenta?.pdf ??
                                                    '',
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
                              ],
                            ),
                          ),
                        );
                      }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
