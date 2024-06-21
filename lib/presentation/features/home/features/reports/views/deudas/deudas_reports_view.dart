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
  final diasInicioCtrl = TextEditingController();
  final diasFinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _searchDeudas() {
    final diasInicio = int.tryParse(diasInicioCtrl.text) ?? -1;
    final diasFin = int.tryParse(diasFinCtrl.text) ?? -1;

    /* if (diasInicio < 0 || diasFin < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Por favor ingrese solo números positivos.',
          ),
        ),
      );
      return;
    }

    if (diasInicio > diasFin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content:
              Text('El día de inicio no puede ser mayor que el día de fin.'),
        ),
      );
      return;
    } */
    if (diasInicio <= 0 || diasFin <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Por favor ingrese solo números positivos.',
          ),
        ),
      );
      return;
    }

    if (diasInicio <= diasFin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('El día de inicio debe ser mayor que el día de fin.'),
        ),
      );
      return;
    }

    final reportsBloc = context.read<ReportsBloc>();
    reportsBloc.add(
      SearchDeudasByDays(
        diasFin: diasFinCtrl.text,
        diasInicio: diasInicioCtrl.text,
      ),
    );
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
                          labelText: 'Inicio',
                          keyboardType: TextInputType.number,
                          controller: diasInicioCtrl,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 2,
                        child: AppTextFormField(
                          labelText: 'Fin',
                          keyboardType: TextInputType.number,
                          controller: diasFinCtrl,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 3,
                        child: PrimaryButton(
                          onPressed: _searchDeudas,
                          child: const Text('Buscar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Deudas vencidas en un rango de (Días de Fin) a (Días de Inicio)',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
              ),
            ),
            BlocBuilder<ReportsBloc, ReportsState>(
              builder: (context, state) {
                switch (state.statusDeudas) {
                  case ReportsStatus.error:
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Text('Ocurrió un error, inténtelo de nuevo'),
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
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Préstamos con deuda (${state.listDeudas?.length})',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }

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
