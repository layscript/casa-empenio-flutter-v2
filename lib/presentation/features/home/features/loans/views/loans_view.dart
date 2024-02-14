// ignore_for_file: prefer_is_empty

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/buttons/buttons.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/views/loans_step_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/views/loan_client_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class LoansView extends StatefulWidget {
  const LoansView({super.key});

  @override
  State<LoansView> createState() => _LoansViewState();
}

class _LoansViewState extends State<LoansView> {
  @override
  Widget build(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();

    return BlocProvider(
      lazy: false,
      create: (context) => LoansBloc(
        customerRepository: context.read(),
        loansRepository: context.read(),
        cajaRepository: context.read(),
        preferences: context.read(),
        solicitudRepository: context.read(),
      )..add(GetCashStatus()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<LoansBloc, LoansState>(
              listener: (context, state) {
            if (state.isSolicitudLoading) {
              OverlayLoader.show(context);
            } else {
              OverlayLoader.hide();
              if (state.isSolicitudError) {
                Navigator.pop(context);
                ErrorSnackbar.show(context, state.error ?? '');
              }

              if (state.isSolicitudSuccess) {
                Navigator.pop(context);
                SuccessSnackbar.show(
                    context, 'Solicitud enviada correctamente');
              }
            }
            /*  if (state.isLoansLoading) {
              OverlayLoader.show(context);
            } else {
              OverlayLoader.hide();
              if (state.isLoansError) {
                ErrorSnackbar.show(context, state.error ?? '');
              }
            } */
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
          }, builder: (context, state) {
            switch (state.loansStatus) {
              case LoansStatus.loading || LoansStatus.initial:
                return const ButtonStateLoading();

              case LoansStatus.error:
                print('errrorr 1: ${state.loansStatus}');
                print('errrorr 2: ${state.error}');

                return ButtonStateError(
                  message: state.error,
                  onPressed: () {
                    context.read<LoansBloc>().add(GetCashStatus());
                  },
                );

              case LoansStatus.loaded:
                final loansBloc = context.read<LoansBloc>();
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: MediaQuery.of(context).size.height * 0.9,
                        padding: const EdgeInsets.only(
                          bottom: 120,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              const Center(
                                child: Text(
                                  'Lista de Préstamos',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => context
                                                .read<LoansBloc>()
                                                .add(const ChangeTypeSearch(
                                                    true)),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: state.typeSearch == true
                                                    ? AppColors.blue
                                                    : Colors.grey[300],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Busqueda por DNI',
                                                  style: TextStyle(
                                                    color:
                                                        state.typeSearch == true
                                                            ? AppColors.white
                                                            : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => context
                                                .read<LoansBloc>()
                                                .add(const ChangeTypeSearch(
                                                    false)),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: state.typeSearch == false
                                                    ? AppColors.blue
                                                    : Colors.grey[300],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Busqueda General',
                                                  style: TextStyle(
                                                    color: state.typeSearch ==
                                                            false
                                                        ? AppColors.white
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    if (state.typeSearch == true) ...[
                                      const SizedBox(height: 15),
                                      const SearchLoansClientByDNI(),
                                    ],
                                    if (state.typeSearch == false) ...[
                                      const SizedBox(height: 15),
                                      const SearchLoansClientByGeneral(),
                                    ],
                                    const SizedBox(height: 15),
                                    if (state.customer != null &&
                                        state.customer?.nombres != null)
                                      Row(
                                        children: [
                                          const Text(
                                            'Cliente:',
                                            style: TextStyle(
                                              color: AppColors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              state.fullNames(),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 10),
                                    const Divider(),
                                  ],
                                ),
                              ),
                              if (state.customer?.prestamos != null)
                                /*  ListViewLoansSuccess(
                              customer: state.customer,
                              hiddeOnTap: false,
                              typeSearch: state.typeSearch,
                              searchText: state.searchText,
                              state: state,
                            ), */
                                ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(
                                    height: 10,
                                  ),
                                  shrinkWrap: true,
                                  itemCount:
                                      state.customer?.prestamos?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final oCcy =
                                        NumberFormat("#,##0.00", "en_US");

                                    final prestamo =
                                        state.customer?.prestamos?[index];

                                    final montoFinal = oCcy
                                        .format(double.parse(
                                                prestamo?.ganancia ?? '0.00') +
                                            double.parse(
                                                prestamo?.monto ?? '0.00'))
                                        .toString();

                                    final auth = context.read<AuthBloc>().state
                                        as Authenticated;

                                    return GestureDetector(
                                      onTap: () {
                                        if (state.typeSearch == false) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BlocProvider.value(
                                                value: loansBloc,
                                                child: LoanClientView(
                                                  document:
                                                      prestamo?.cliente?.dni ??
                                                          '',
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: prestamo?.estado == 'CANCELADO'
                                              ? Colors.red[50]
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                                        color: AppColors
                                                            .secondaryText,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${prestamo?.estado}',
                                                      maxLines: 3,
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .secondaryText,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    if (prestamo.isRenewed !=
                                                            null &&
                                                        prestamo.isRenewed ==
                                                            true)
                                                      const Text(
                                                        'RENOVADO',
                                                        style: TextStyle(
                                                          color: Colors.purple,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    if (state.typeSearch ==
                                                        false)
                                                      Text(
                                                        '${prestamo.cliente?.nombres ?? ''} - ${prestamo.cliente?.apellidos ?? ''}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .secondaryText,
                                                          fontWeight:
                                                              FontWeight.normal,
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
                                                        return BlocProvider
                                                            .value(
                                                          value: loansBloc,
                                                          child:
                                                              ShowInfoClientLoans(
                                                            nroPrestamo:
                                                                prestamo
                                                                    ?.codigo,
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
                                              ),
                                              if (auth.user.role?.id != 2)
                                                //Editar
                                                SizedBox(
                                                  height: 38,
                                                  width: 38,
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () async {
                                                      if (prestamo?.cerrado ==
                                                          false) {
                                                        print(
                                                            'sadjklsadjklsdakjsad 1');
                                                        // TODAVIA NO ESTÁ CERRADO PUEDO EDITAR
                                                        final result =
                                                            await showModalBottomSheet<
                                                                bool?>(
                                                          isDismissible: false,
                                                          context: context,
                                                          builder: (_) {
                                                            return BlocProvider
                                                                .value(
                                                              value: context.read<
                                                                  LoansBloc>(),
                                                              child: Padding(
                                                                padding: MediaQuery.of(
                                                                        context)
                                                                    .viewInsets,
                                                                child:
                                                                    EditLoanBottomSheet(
                                                                  idPrestamo:
                                                                      prestamo?.codigo ??
                                                                          0,
                                                                  isNuevo:
                                                                      false,
                                                                  isRenew: null,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );

                                                        if (result != null &&
                                                            mounted) {
                                                          //TODO :: Cargar todo
                                                          await Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300))
                                                              .then((value) {
                                                            context
                                                                .read<
                                                                    LoansBloc>()
                                                                .add(
                                                                  GetLoansByDni(
                                                                    value: state
                                                                        .searchText,
                                                                  ),
                                                                );
                                                          });
                                                        }
                                                      } else {
                                                        print(
                                                            'sadjklsadjklsdakjsad 2');
                                                        // YA ESTÁ CERRADO Y PUEDO CREAR UNO NUEVO/RENOVAR CON SU MISMA DATA :V
                                                        final optionBottomSheet =
                                                            await ShowBottomSheetRenewLoan
                                                                .show(
                                                          context,
                                                        );
                                                        if (optionBottomSheet !=
                                                                null &&
                                                            mounted) {
                                                          final result =
                                                              await showModalBottomSheet<
                                                                  bool?>(
                                                            isDismissible:
                                                                false,
                                                            isScrollControlled:
                                                                false,
                                                            context: context,
                                                            builder: (_) {
                                                              return BlocProvider
                                                                  .value(
                                                                value: context.read<
                                                                    LoansBloc>(),
                                                                child: Padding(
                                                                  padding: MediaQuery.of(
                                                                          context)
                                                                      .viewInsets,
                                                                  child:
                                                                      EditLoanBottomSheet(
                                                                    idPrestamo:
                                                                        prestamo?.codigo ??
                                                                            0,
                                                                    isNuevo:
                                                                        true,
                                                                    isRenew:
                                                                        optionBottomSheet,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          );

                                                          if (result != null &&
                                                              mounted) {
                                                            //TODO :: Cargar todo
                                                            await Future.delayed(
                                                                    const Duration(
                                                                        milliseconds:
                                                                            300))
                                                                .then((value) {
                                                              context
                                                                  .read<
                                                                      LoansBloc>()
                                                                  .add(
                                                                    GetLoansByDni(
                                                                      value: state
                                                                          .searchText,
                                                                    ),
                                                                  );
                                                            });
                                                          }
                                                        }
                                                      }
                                                    },
                                                    icon: Icon(
                                                      prestamo?.cerrado == false
                                                          ? Icons.edit
                                                          : Icons.new_label,
                                                      color:
                                                          prestamo?.cerrado ==
                                                                  false
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
                                                      print(
                                                          'debugggg renovar usuario');
                                                      final optionBottomSheet =
                                                          await ShowBottomSheetRenewLoan
                                                              .show(
                                                        context,
                                                      );

                                                      if (optionBottomSheet !=
                                                              null &&
                                                          mounted) {
                                                        final result =
                                                            await showModalBottomSheet<
                                                                bool?>(
                                                          isDismissible: false,
                                                          isScrollControlled:
                                                              false,
                                                          context: context,
                                                          builder: (_) {
                                                            return BlocProvider
                                                                .value(
                                                              value: context.read<
                                                                  LoansBloc>(),
                                                              child: Padding(
                                                                padding: MediaQuery.of(
                                                                        context)
                                                                    .viewInsets,
                                                                child:
                                                                    EditLoanBottomSheet(
                                                                  idPrestamo:
                                                                      prestamo?.codigo ??
                                                                          0,
                                                                  isNuevo: true,
                                                                  isRenew:
                                                                      optionBottomSheet,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );

                                                        if (result != null &&
                                                            mounted) {
                                                          //TODO :: Cargar todo
                                                          await Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300))
                                                              .then((value) {
                                                            context
                                                                .read<
                                                                    LoansBloc>()
                                                                .add(
                                                                  GetLoansByDni(
                                                                    value: state
                                                                        .searchText,
                                                                  ),
                                                                );
                                                          });
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
                                                      final result =
                                                          await showDialog<
                                                              bool>(
                                                        barrierDismissible:
                                                            false,
                                                        context: context,
                                                        builder: (_) {
                                                          return BlocProvider
                                                              .value(
                                                            value: context.read<
                                                                LoansBloc>(),
                                                            child:
                                                                PaymentLoanDialogClient(
                                                              nroPrestamo:
                                                                  prestamo
                                                                      ?.codigo,
                                                            ),
                                                          );
                                                        },
                                                      );
                                                      print(
                                                          'resuuult: ${result}');
                                                      if (result != null &&
                                                          mounted) {
                                                        //TODO :: Cargar todo
                                                        loansBloc.add(
                                                          GetLoansByDni(
                                                            value: state
                                                                .searchText,
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
                                                      final result =
                                                          await showDialog<
                                                              bool>(
                                                        barrierDismissible:
                                                            false,
                                                        context: context,
                                                        builder: (_) {
                                                          return BlocProvider
                                                              .value(
                                                            value: context.read<
                                                                LoansBloc>(),
                                                            child:
                                                                AddAmountLoanDialogClient(
                                                              nroPrestamo:
                                                                  prestamo
                                                                      ?.codigo,
                                                            ),
                                                          );
                                                        },
                                                      );

                                                      print(
                                                          'resuuult: ${result}');
                                                      if (result != null &&
                                                          mounted) {
                                                        //TODO :: Cargar todo
                                                        loansBloc.add(
                                                          GetLoansByDni(
                                                            value: state
                                                                .searchText,
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
                                                  prestamo?.estado !=
                                                      'CANCELADO')
                                                SizedBox(
                                                  height: 38,
                                                  width: 38,
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () async {
                                                      if (prestamo?.boleta ==
                                                          null) {
                                                        final dniCustomer =
                                                            state.customer?.dni;
                                                        final result =
                                                            await showDialog<
                                                                bool>(
                                                          barrierDismissible:
                                                              false,
                                                          context: context,
                                                          builder: (_) {
                                                            return BlocProvider
                                                                .value(
                                                              value: context.read<
                                                                  LoansBloc>(),
                                                              child:
                                                                  ShowDialogBillingLoan(
                                                                nroPrestamo:
                                                                    prestamo
                                                                        ?.codigo,
                                                                dniCustomer:
                                                                    dniCustomer,
                                                              ),
                                                            );
                                                          },
                                                        );

                                                        print(
                                                            'resuuult: ${result}');
                                                        if (result != null &&
                                                            mounted) {
                                                          context
                                                              .read<LoansBloc>()
                                                              .add(
                                                                GetLoansByDni(
                                                                  value: state
                                                                      .searchText,
                                                                ),
                                                              );
                                                        }
                                                      } else {
                                                        // Abrir excel - verde
                                                        Navigator.push(context,
                                                            MaterialPageRoute(
                                                          builder: (context) {
                                                            return PdfPreviewFacturaPage(
                                                              url: prestamo
                                                                      ?.boleta
                                                                      ?.pdf ??
                                                                  '',
                                                              id: prestamo
                                                                      ?.codigo ??
                                                                  0,
                                                              tipo: 'prestamo',
                                                              notaCredito: prestamo
                                                                  ?.notaCredito,
                                                            );
                                                          },
                                                        ));
                                                      }
                                                    },
                                                    icon: Icon(
                                                      Icons.description,
                                                      color: prestamo?.boleta ==
                                                              null
                                                          ? Colors.blue
                                                          : prestamo?.notaCredito
                                                                      ?.length ==
                                                                  0
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
                                                      final user = context
                                                          .read<Preferences>()
                                                          .token;

                                                      final result = await context
                                                          .read<
                                                              SolicitudRepository>()
                                                          .getSolicitudByIdPrestamo(
                                                            idPrestamo: prestamo
                                                                    ?.codigo ??
                                                                0,
                                                          );

                                                      if (user?.role?.nombre ==
                                                              'Usuario' &&
                                                          result &&
                                                          mounted) {
                                                        await showDialog(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder: (_) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                'Solicitar Permiso',
                                                              ),
                                                              content:
                                                                  const Text(
                                                                'No tiene permisos para realizar esta acción. ¿Desea solicitar permiso al administrador?',
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    loansBloc
                                                                        .add(
                                                                      CreateSolicitud(
                                                                        prestamoId:
                                                                            prestamo?.codigo.toString() ??
                                                                                '',
                                                                        estado:
                                                                            'PENDIENTE',
                                                                        usuarioId:
                                                                            user?.id ??
                                                                                0,
                                                                      ),
                                                                    );
                                                                  },
                                                                  child:
                                                                      const Text(
                                                                    'Si, Enviar',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .blue,
                                                                    ),
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          context),
                                                                  child:
                                                                      const Text(
                                                                    'No, Salir',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .red,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      } else if (mounted) {
                                                        final result =
                                                            await showDialog(
                                                          barrierDismissible:
                                                              false,
                                                          context: context,
                                                          builder: (_) =>
                                                              BlocProvider
                                                                  .value(
                                                            value: loansBloc,
                                                            child:
                                                                DeleteLoanDialog(
                                                              idLoan: prestamo
                                                                      ?.codigo ??
                                                                  0,
                                                            ),
                                                          ),
                                                        );

                                                        if (result != null &&
                                                            mounted) {
                                                          loansBloc.add(
                                                            GetLoansByDni(
                                                              value: state
                                                                  .searchText,
                                                            ),
                                                          );
                                                        }
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
                                                      final result =
                                                          await showDialog(
                                                        barrierDismissible:
                                                            false,
                                                        context: context,
                                                        builder: (_) =>
                                                            BlocProvider.value(
                                                          value: context.read<
                                                              LoansBloc>(),
                                                          child:
                                                              UpdateStatusLoanDialog(
                                                            idLoan: prestamo
                                                                    ?.codigo ??
                                                                0,
                                                          ),
                                                        ),
                                                      );

                                                      if (result != null &&
                                                          mounted) {
                                                        loansBloc.add(
                                                          GetLoansByDni(
                                                            value: state
                                                                .searchText,
                                                          ),
                                                        );
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
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        top: null,
                        child: Container(
                          height: 100,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: defaultBoxShadow,
                          ),
                          child: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                PrimaryButton(
                                  onPressed: () async {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      LoansStepView.route,
                                    );

                                    if (mounted) {
                                      loansBloc.add(
                                        GetLoansByDni(
                                          value: state.searchText,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      FaIcon(FontAwesomeIcons.circlePlus),
                                      SizedBox(width: 10),
                                      Text('Agregar Préstamo'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );

              default:
            }

            return const SizedBox();
          });
        },
      ),
    );
  }
}
