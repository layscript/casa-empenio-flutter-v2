import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DeudasReportsView extends StatefulWidget {
  const DeudasReportsView({super.key});

  @override
  State<DeudasReportsView> createState() => _DeudasReportsViewState();
}

class _DeudasReportsViewState extends State<DeudasReportsView> {
  final cantDiasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    //fetchApi();
  }

  void fetchApi() async {
    context.read<ReportsBloc>().add(
          const SearchDeudasByDays(
            dias: '0',
          ),
        );
  }

  String cantDias = '';
  String _dateRange = '';

  void _calculateDateRange() {
    int days = int.tryParse(cantDias) ?? 0;
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(Duration(days: days));
    setState(() {
      _dateRange =
          'entre el ${_formatDate(startDate)} hasta ${_formatDate(endDate)}';
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final reportsBloc = context.read<ReportsBloc>();

    return GestureDetector(
      onTap: () => Keyboard.unfocus(context),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppTextFormField(
                          labelText: 'Cantidad de días',
                          keyboardType: TextInputType.number,
                          initialValue: cantDias,
                          onChanged: (e) {
                            setState(() {
                              cantDias = e;
                            });

                            _calculateDateRange();
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: PrimaryButton(
                          onPressed: () {
                            reportsBloc.add(
                              SearchDeudasByDays(
                                dias: cantDias,
                              ),
                            );
                          },
                          child: const Text('Buscar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Filtro de deudas $_dateRange',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<ReportsBloc, ReportsState>(
              builder: (context, state) {
                switch (state.statusDeudas) {
                  case ReportsStatus.error:
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Text('Ocurrió un error, intentelo de nuevo'),
                      ),
                    );

                  case ReportsStatus.loading:
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                  case ReportsStatus.success:
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == 0) {
                            // Este es el texto adicional
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Prestamos con deuda (${state.listDeudas?.length})',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }

                          // Ajusta el índice para acceder correctamente a la lista
                          final prestamo = state.listDeudas![index - 1];
                          final fechaCreacion =
                              DateTime.parse(prestamo.fecha ?? '').toLocal();
                          final fechaFormateada =
                              DateFormat('dd/MM/yyyy - kk:mm')
                                  .format(fechaCreacion);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 5),
                            decoration: BoxDecoration(
                              color: prestamo.estado == 'CANCELADO'
                                  ? Colors.red[50]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.only(left: 10, right: 0),
                              title: Text(
                                'Cod.: ${prestamo.codigo.toString().padLeft(6, '0')} - S/. ${oCcy.format(double.parse(prestamo.ganancia ?? '0.00') + double.parse(prestamo.monto ?? '0.00'))}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$fechaFormateada - ${prestamo.estado}'),
                                  const SizedBox(height: 3),
                                  Text(
                                      '${prestamo.cliente?.nombres} ${prestamo.cliente?.apellidos}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (_) {
                                          return BlocProvider.value(
                                            value: reportsBloc,
                                            child: ShowDetailsReportLoans(
                                              nroPrestamo: prestamo.codigo,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.remove_red_eye_outlined,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: state.listDeudas!.length +
                            1, // +1 para el texto adicional
                      ),
                    );

                  default:
                    return const SliverToBoxAdapter();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
