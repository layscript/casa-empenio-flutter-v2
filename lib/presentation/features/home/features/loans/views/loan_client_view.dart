import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class LoanClientView extends StatefulWidget {
  const LoanClientView({
    super.key,
    required this.document,
  });
  final String document;

  @override
  State<LoanClientView> createState() => _LoanClientViewState();
}

class _LoanClientViewState extends State<LoanClientView> {
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

                        final auth =
                            context.read<AuthBloc>().state as Authenticated;

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
                                        '${prestamo.estado}',
                                        maxLines: 3,
                                        style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (state.typeSearch == false)
                                        Text(
                                          '${prestamo.cliente?.nombres ?? ''} ${prestamo.cliente?.apellidos ?? ''}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                //Visualizar
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
                                ),
                                if (auth.user.role?.id != 2)
                                  //Editar
                                  SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        if (prestamo?.cerrado == false) {
                                          // TODAVIA NO ESTÁ CERRADO PUEDO EDITAR
                                          final result =
                                              await showModalBottomSheet<bool?>(
                                            isDismissible: false,
                                            context: context,
                                            builder: (_) {
                                              return BlocProvider.value(
                                                value:
                                                    context.read<LoansBloc>(),
                                                child: Padding(
                                                  padding:
                                                      MediaQuery.of(context)
                                                          .viewInsets,
                                                  child: EditLoanBottomSheet(
                                                    idPrestamo:
                                                        prestamo?.codigo ?? 0,
                                                    isNuevo: false,
                                                    isRenew: null,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                          if (result != null && mounted) {
                                            context.read<LoansBloc>().add(
                                                  GetLoansByDni(
                                                    value: state.searchText,
                                                  ),
                                                );
                                          }
                                        } else {
                                          // YA ESTÁ CERRADO asi que renuevo
                                          final optionBottomSheet =
                                              await ShowBottomSheetRenewLoan
                                                  .show(
                                            context,
                                          );

                                          if (optionBottomSheet != null &&
                                              mounted) {
                                            final result =
                                                await showModalBottomSheet<
                                                    bool?>(
                                              isDismissible: false,
                                              context: context,
                                              builder: (_) {
                                                return BlocProvider.value(
                                                  value:
                                                      context.read<LoansBloc>(),
                                                  child: Padding(
                                                    padding:
                                                        MediaQuery.of(context)
                                                            .viewInsets,
                                                    child: EditLoanBottomSheet(
                                                      idPrestamo:
                                                          prestamo?.codigo ?? 0,
                                                      isNuevo: true,
                                                      isRenew:
                                                          optionBottomSheet,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );

                                            if (result != null && mounted) {
                                              context.read<LoansBloc>().add(
                                                    GetLoansByDni(
                                                      value: state.searchText,
                                                    ),
                                                  );
                                            }
                                          }
                                        }
                                      },
                                      icon: Icon(
                                        prestamo?.cerrado == false
                                            ? Icons.edit
                                            : Icons.new_label,
                                        color: prestamo?.cerrado == false
                                            ? Colors.blue
                                            : Colors.purple,
                                      ),
                                    ),
                                  ),
                                if (auth.user.role?.id == 2 &&
                                    prestamo?.cerrado == true)
                                  SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        // YA ESTÁ CERRADO asi que renuevo
                                        final optionBottomSheet =
                                            await ShowBottomSheetRenewLoan.show(
                                          context,
                                        );

                                        if (optionBottomSheet != null &&
                                            mounted) {
                                          final result =
                                              await showModalBottomSheet<bool?>(
                                            isDismissible: false,
                                            context: context,
                                            builder: (_) {
                                              return BlocProvider.value(
                                                value:
                                                    context.read<LoansBloc>(),
                                                child: Padding(
                                                  padding:
                                                      MediaQuery.of(context)
                                                          .viewInsets,
                                                  child: EditLoanBottomSheet(
                                                    idPrestamo:
                                                        prestamo?.codigo ?? 0,
                                                    isNuevo: true,
                                                    isRenew: optionBottomSheet,
                                                  ),
                                                ),
                                              );
                                            },
                                          );

                                          if (result != null && mounted) {
                                            context.read<LoansBloc>().add(
                                                  GetLoansByDni(
                                                    value: state.searchText,
                                                  ),
                                                );
                                          }
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.new_label,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                if (prestamo?.cerrado == false)
                                  // Pagar prestamo
                                  SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        final result = await showDialog<bool>(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (_) {
                                            return BlocProvider.value(
                                              value: context.read<LoansBloc>(),
                                              child: PaymentLoanDialogClient(
                                                nroPrestamo: prestamo?.codigo,
                                              ),
                                            );
                                          },
                                        );
                                        if (result != null && mounted) {
                                          //TODO :: Cargar todo
                                          context.read<LoansBloc>().add(
                                                GetLoansByDni(
                                                  value: state.searchText,
                                                ),
                                              );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.payments_outlined,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                if (prestamo?.cerrado == false)
                                  // Agregar monto
                                  SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        final result = await showDialog<bool>(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (_) {
                                            return BlocProvider.value(
                                              value: context.read<LoansBloc>(),
                                              child: AddAmountLoanDialogClient(
                                                nroPrestamo: prestamo?.codigo,
                                              ),
                                            );
                                          },
                                        );

                                        if (result != null && mounted) {
                                          //TODO :: Cargar todo
                                          context.read<LoansBloc>().add(
                                                GetLoansByDni(
                                                  value: state.searchText,
                                                ),
                                              );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.add_card,
                                        color: Colors.red[400],
                                      ),
                                    ),
                                  ),
                                if (prestamo?.cerrado == true &&
                                    prestamo?.estado != 'CANCELADO')
                                  SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        if (prestamo?.boleta == null) {
                                          final dniCustomer =
                                              state.customer?.dni;
                                          final result = await showDialog<bool>(
                                            barrierDismissible: false,
                                            context: context,
                                            builder: (_) {
                                              return BlocProvider.value(
                                                value:
                                                    context.read<LoansBloc>(),
                                                child: ShowDialogBillingLoan(
                                                  nroPrestamo: prestamo?.codigo,
                                                  dniCustomer: dniCustomer,
                                                ),
                                              );
                                            },
                                          );

                                          if (result != null && mounted) {
                                            context.read<LoansBloc>().add(
                                                  GetLoansByDni(
                                                    value: state.searchText,
                                                  ),
                                                );
                                          }
                                        } else {
                                          // Abrir excel - verde
                                          Navigator.push(context,
                                              MaterialPageRoute(
                                            builder: (context) {
                                              return PdfPreviewFacturaPage(
                                                url:
                                                    prestamo?.boleta?.pdf ?? '',
                                                id: prestamo?.codigo ?? 0,
                                                tipo: 'prestamo',
                                                notaCredito:
                                                    prestamo?.notaCredito,
                                              );
                                            },
                                          ));
                                        }
                                      },
                                      icon: Icon(
                                        Icons.description,
                                        color: prestamo?.boleta == null
                                            ? Colors.blue
                                            : prestamo?.notaCredito?.length == 0
                                                ? Colors.green
                                                : Colors.red[400],
                                      ),
                                    ),
                                  ),

                                if (prestamo?.estado != 'VENCIDO')
                                  SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        final result = await showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (_) => BlocProvider.value(
                                            value: context.read<LoansBloc>(),
                                            child: DeleteLoanDialog(
                                              idLoan: prestamo?.codigo ?? 0,
                                            ),
                                          ),
                                        );

                                        if (result != null && mounted) {
                                          await Future.delayed(const Duration(
                                                  milliseconds: 300))
                                              .then((value) {
                                            context.read<LoansBloc>().add(
                                                  GetLoansSearchByDni(
                                                    value: widget.document,
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
                                  ),

                                if (prestamo?.estado == 'VENCIDO')
                                  SizedBox(
                                    height: 38,
                                    width: 38,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        print(
                                            'kljasdkljasd: ${prestamo?.codigo}');
                                        final result = await showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (_) => BlocProvider.value(
                                            value: context.read<LoansBloc>(),
                                            child: UpdateStatusLoanDialog(
                                              idLoan: prestamo?.codigo ?? 0,
                                            ),
                                          ),
                                        );

                                        if (result != null && mounted) {
                                          await Future.delayed(const Duration(
                                                  milliseconds: 300))
                                              .then((value) {
                                            context.read<LoansBloc>().add(
                                                  GetLoansSearchByDni(
                                                    value: widget.document,
                                                  ),
                                                );
                                          });
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.update,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
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
