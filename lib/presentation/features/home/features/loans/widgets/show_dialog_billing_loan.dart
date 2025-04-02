import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShowDialogBillingLoan extends StatefulWidget {
  const ShowDialogBillingLoan({
    super.key,
    required this.nroPrestamo,
    required this.dniCustomer,
  });
  final int? nroPrestamo;
  final String? dniCustomer;

  @override
  State<ShowDialogBillingLoan> createState() => _ShowDialogBillingLoanState();
}

class _ShowDialogBillingLoanState extends State<ShowDialogBillingLoan> {
  bool isValidDni = false;
  final dniCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.nroPrestamo != null && widget.dniCustomer != null) {
      context.read<LoansBloc>().add(GetDetailsLoan(widget.nroPrestamo!));
      context.read<LoansBloc>().add(GetDataSunatByDni(widget.dniCustomer));
      dniCtrl.text = widget.dniCustomer!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.read<Preferences>();

    return GestureDetector(
      onTap: () => Keyboard.unfocus(context),
      child: BlocConsumer<LoansBloc, LoansState>(
        listener: (context, state) {
          // Manejar el error cuando no se encuentra información para el DNI
          if (state.isLoansError && state.loansStatus == LoansStatus.error) {
            // Mostrar mensaje de error sin cerrar el modal
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se encontró información para este documento. Intente nuevamente.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            // Resetear el estado para permitir nuevos intentos sin cerrar el modal
            context.read<LoansBloc>().add(GetLoansInitial());
          }

          if (state.isLoansElectronicTicketSuccess) {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text(
                    'Boleta generada',
                    style: TextStyle(
                      color: Colors.green,
                    ),
                  ),
                  content: const Text('La boleta se ha generado correctamente'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                      child: const Text('Aceptar'),
                    ),
                  ],
                );
              },
            );
          }

          if (state.isLoansElectronicTicketError) {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text(
                    'Ocurrió un error',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  content: const Text('Vuelve a intentarlo de nuevo'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Aceptar'),
                    ),
                  ],
                );
              },
            );
          }
        },
        builder: (context, state) {
          switch (state.loansStatus) {
            case LoansStatus.electronicTicketLoading:
              return const SizedBox(
                width: 300,
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );

            case LoansStatus.error:
            case LoansStatus.loadingDetailsSunat:
            case LoansStatus.loaded:
              final loan = state.loanDetails;
              return AlertDialog(
                insetPadding: EdgeInsets.zero,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                content: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Boleta Electrónica',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Ganancita Total: S/. ${oCcy.format(
                        double.parse(loan?.ganancia ?? '0.00'),
                      )}'),
                      const SizedBox(height: 20),
                      AppTextFormField(
                        maxLength: 8,
                        keyboardType: TextInputType.number,
                        labelText: 'DNI',
                        controller: dniCtrl,
                        //initialValue: state.customerSunat?.dni,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Ingrese un DNI o deje el campo vacío';
                          }
                          if (value.length < 8) {
                            return 'Ingrese un DNI Válido de 8 digitos';
                          }
                          return null;
                        },
                        isValid: (value) => setState(() {
                          isValidDni = value;
                        }),
                        onChanged: (value) {
                          if (value.length == 8) {
                            context.read<LoansBloc>().add(
                                  GetDataSunatByDni(
                                    value,
                                  ),
                                );
                          }
                        },
                      ),
                      if (state.isLoadingDetailsSunat) ...[
                        const SizedBox(height: 15),
                        const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ] else if (state.error != null && state.loansStatus == LoansStatus.loaded && dniCtrl.text.length == 8) ...[
                        // Mostrar mensaje de error cuando no se encuentra información
                        const SizedBox(height: 15),
                        const Text(
                          'No se encontró información para este documento. Intente nuevamente.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else if (state.customerSunat != null &&
                          dniCtrl.text.length == 8) ...[
                        const SizedBox(height: 15),
                        Text(
                          state.fullNamesCustomerSunat(),
                          style: const TextStyle(
                            color: Colors.purple,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: AppColors.red,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: (dniCtrl.text.length == 8 &&
                                    state.customerSunat != null &&
                                    state.error == null) ||
                                (dniCtrl.text.isEmpty &&
                                    double.parse(loan?.ganancia.toString() ??
                                            '0.00') <
                                        700)
                            ? () {
                                if (dniCtrl.text.isEmpty) {
                                  // Crear factura sin nada
                                  context.read<LoansBloc>().add(
                                        CreateInvoiceLoans(
                                          dni: '00000000',
                                          fullName: '---',
                                          direccion: null,
                                          idPrestamo: widget.nroPrestamo ?? 0,
                                          userId: preferences.token?.id
                                                  .toString() ??
                                              '0',
                                        ),
                                      );
                                } else {
                                  // Crear factura con data
                                  context.read<LoansBloc>().add(
                                        CreateInvoiceLoans(
                                          dni: dniCtrl.text,
                                          fullName:
                                              state.fullNamesCustomerSunat(),
                                          direccion: state.customerSunat
                                                  ?.domicilio?.direccion ??
                                              '',
                                          idPrestamo: widget.nroPrestamo ?? 0,
                                          userId: preferences.token?.id
                                                  .toString() ??
                                              '0',
                                        ),
                                      );
                                }
                              }
                            : null,
                        child: const Text(
                          'Generar',
                        ),
                      ),
                    ],
                  )
                ],
              );

            default:
          }

          return const SizedBox(
            width: 300,
            height: 300,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
