// ignore_for_file: depend_on_referenced_packages
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ReportsDetailView extends StatefulWidget {
  const ReportsDetailView({
    super.key,
    required this.document,
  });
  final String document;

  @override
  State<ReportsDetailView> createState() => _ReportsDetailViewState();
}

class _ReportsDetailViewState extends State<ReportsDetailView> {
  @override
  void initState() {
    super.initState();
    callApi();
  }

  void callApi() {
    context.read<LoansBloc>().add(
          GetLoansSearchByDni(
            value: widget.document,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: const Text('Detalle Cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: BlocBuilder<LoansBloc, LoansState>(
          builder: (context, state) {
            if (state.isLoansSearchClientLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.isLoansSearchClientError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Ocurrió un problema, inténtelo de nuevo',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        callApi();
                      },
                      child: const Text('Actualizar'),
                    ),
                  ],
                ),
              );
            }

            if (state.isLoansSearchClientSuccess) {
              final customer = state.searchCustomer;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Cliente: ${customer?.nombres} ${customer?.apellidos}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 10,
                      ),
                      shrinkWrap: true,
                      itemCount: state.searchCustomer?.prestamos?.length ?? 0,
                      itemBuilder: (context, index) {
                        final oCcy = NumberFormat("#,##0.00", "en_US");

                        final prestamo =
                            state.searchCustomer?.prestamos?[index];

                        final montoFinal = oCcy
                            .format(double.parse(prestamo?.ganancia ?? '0.00') +
                                double.parse(prestamo?.monto ?? '0.00'))
                            .toString();

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: prestamo?.estado == 'CANCELADO'
                                ? Colors.red[50]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              'Cod:. ${prestamo?.codigo.toString().padLeft(6, '0')} - s/.$montoFinal',
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            subtitle: prestamo?.fecha != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.formattedDate(
                                          prestamo!.fecha!,
                                        ),
                                        maxLines: 3,
                                        style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Estado:${prestamo.estado}',
                                        maxLines: 3,
                                        style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 38,
                                  width: 38,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (_) {
                                          return BlocProvider.value(
                                            value: context.read<LoansBloc>(),
                                            child: ShowInfoClientLoans(
                                              nroPrestamo: prestamo?.codigo,
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
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
