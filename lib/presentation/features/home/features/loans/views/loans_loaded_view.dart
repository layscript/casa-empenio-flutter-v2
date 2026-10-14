import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/utils/expediente_page.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/anexos/widgets/add_anexo_dialog.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/views/loans_step_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/views/loan_client_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoansLoadedView extends StatefulWidget {
  const LoansLoadedView({
    super.key,
    required this.loansBloc,
    required this.state,
  });
  final LoansBloc loansBloc;
  final LoansState state;

  @override
  State<LoansLoadedView> createState() => _LoansLoadedViewState();
}

class _LoansLoadedViewState extends State<LoansLoadedView> {
  final _scrollController = ScrollController();
  bool _isLoading = false;
  int _offset = 0;
  String? searchCriterio;
  String? searchCategoria;
  String? searchDocument;
  List<LoansEntity> loans = [];
  CustomerEntity? customer;

  bool? typeSearch;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (typeSearch == true) return;

    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading) {
        setState(() {
          _isLoading = true;
          _offset += 10;
        });
        _loadData();
      }
    }
  }

  void _loadData() async {
    final loansRepository = context.read<LoansRepository>();
    final authPreferences = context.read<Preferences>().token;
    final getLoans = await loansRepository.getLoans(
      criterio: searchCriterio,
      userId: authPreferences?.id ?? 1,
      sucursal: authPreferences?.sucursal?.id ?? 1,
      offset: _offset,
      categoria: searchCategoria,
    );

    getLoans.fold(
      (error) => null,
      (success) {
        if (_offset == 0) {
          loans.clear();
        }

        loans.addAll(success);
      },
    );
    setState(() {
      _isLoading = false;
    });
  }

  void _handleSearchByGeneral(String? criterio, String? categoria) {
    setState(() {
      searchCriterio = criterio;
      searchCategoria = categoria;
      _offset = 0;
      _isLoading = true;

      loans.clear();
    });
    _loadData();
  }

  void _handleSearchByDni(String? dni) async {
    setState(() {
      _offset = 0;
      _isLoading = true;
      searchDocument = dni;
      loans.clear();
    });
    final customerRepository = context.read<CustomerRepository>();
    final authPreferences = context.read<Preferences>().token;
    final getLoans = await customerRepository.getCustomerByDni(
      userId: authPreferences?.id ?? 1,
      sucursal: authPreferences?.sucursal?.id ?? 1,
      dni: dni ?? '',
    );

    getLoans.fold(
      (error) => null,
      (success) {
        customer = success;
        loans.addAll(success.prestamos ?? []);
      },
    );

    _isLoading = false;

    setState(() {});
  }

  void _handleTypeSearch(bool value) {
    setState(() {
      typeSearch = value;
      customer = null;

      loans = [];
      loans.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isLoading,
      child: Container(
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
              child: ListView(
                controller: _scrollController,
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
                                /*  onTap: () => widget.loansBloc
                                      .add(const ChangeTypeSearch(true)), */
                                onTap: () {
                                  _handleTypeSearch(true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: typeSearch == true
                                        ? AppColors.blue
                                        : Colors.grey[300],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Busqueda por DNI',
                                      style: TextStyle(
                                        color: typeSearch == true
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
                                /* onTap: () => widget.loansBloc
                                      .add(const ChangeTypeSearch(false)), */
                                onTap: () {
                                  _handleTypeSearch(false);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: typeSearch == false
                                        ? AppColors.blue
                                        : Colors.grey[300],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Busqueda General',
                                      style: TextStyle(
                                        color: typeSearch == false
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
                        if (typeSearch == true) ...[
                          const SizedBox(height: 15),
                          SearchLoansClientByDNI(
                            onPressed: (dni) {
                              _handleSearchByDni(dni);
                            },
                          ),
                        ],
                        if (typeSearch == false) ...[
                          const SizedBox(height: 15),
                          SearchLoansClientByGeneral(
                            categories: widget.state.listCategories ?? [],
                            onPressed: (dto) {
                              _handleSearchByGeneral(dto.text, dto.category);
                            },
                          ),
                        ],
                        const SizedBox(height: 15),
                        if (customer != null && customer?.nombres != null)
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
                                  customer?.customerFullName ?? '',
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
                  //if (widget.state.customer?.prestamos != null)
                  if (loans.isNotEmpty)
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 10,
                      ),
                      shrinkWrap: true,
                      //itemCount: widget.state.customer!.prestamos!.length + 1,
                      itemCount: loans.length + 1,
                      itemBuilder: (context, index) {
                        if (index < loans.length) {
                          /* final prestamo =
                                widget.state.customer?.prestamos?[index] */

                          final prestamo = loans[index];

                          final montoFinal = oCcy
                              .format(
                                  double.parse(prestamo?.ganancia ?? '0.00') +
                                      double.parse(prestamo?.monto ?? '0.00'))
                              .toString();

                          final auth =
                              context.read<AuthBloc>().state as Authenticated;
                          return GestureDetector(
                            onTap: () {
                              if (typeSearch == false) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: widget.loansBloc,
                                      child: LoanClientView(
                                        document: prestamo?.cliente?.dni ?? '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Dismissible(
                              key: ValueKey(prestamo),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                color: Colors.green,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: const Text(
                                  'Visualizar Visitas',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: const Text(
                                  'Agregar Visita',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  await showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (_) {
                                      return AddAnexoDialog(
                                        idPrestamo: prestamo?.codigo,
                                        onPressed: (anexo) {
                                          widget.loansBloc.add(
                                            SaveAnexoLoan(
                                              description: anexo.description,
                                              imagenes: anexo.imagenes,
                                              prestamoId: anexo.prestamoId,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                } else if (direction ==
                                    DismissDirection.startToEnd) {
                                  await showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (_) {
                                      return BlocProvider.value(
                                        value: widget.loansBloc,
                                        child: ListAnexosByLoan(
                                          prestamoId: prestamo?.codigo ?? 0,
                                          onPressed: () {},
                                        ),
                                      );
                                    },
                                  );
                                }

                                return false; //
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
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
                                              widget.state.formattedDate(
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
                                              '${prestamo?.estado}',
                                              maxLines: 3,
                                              style: const TextStyle(
                                                color: AppColors.secondaryText,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (prestamo.isRenewed != null &&
                                                prestamo.isRenewed == true)
                                              const Text(
                                                'RENOVADO',
                                                style: TextStyle(
                                                  color: Colors.purple,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            if (typeSearch == false)
                                              Text(
                                                '${prestamo.cliente?.nombres ?? ''} - ${prestamo.cliente?.apellidos ?? ''}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.secondaryText,
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
                                      //Expediente digital (firma)
                                      SizedBox(
                                        height: 38,
                                        width: 38,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          tooltip: 'Expediente digital',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ExpedientePage(
                                                  prestamoCodigo:
                                                      prestamo?.codigo ?? 0,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const FaIcon(
                                            FontAwesomeIcons.fileSignature,
                                            size: 18,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                      //Visualizar
                                      SizedBox(
                                        height: 38,
                                        width: 38,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () async {
                                            await showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (_) {
                                                return BlocProvider.value(
                                                  value: widget.loansBloc,
                                                  child: ShowInfoClientLoans(
                                                    nroPrestamo:
                                                        prestamo.codigo,
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
                                      //if (auth.user.role?.id != 2)
                                      //if (auth.user?.isAdmin == true)
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
                                                  await showModalBottomSheet<
                                                      bool?>(
                                                isDismissible: false,
                                                context: context,
                                                builder: (_) {
                                                  return BlocProvider.value(
                                                    value: widget.loansBloc,
                                                    child: Padding(
                                                      padding:
                                                          MediaQuery.of(context)
                                                              .viewInsets,
                                                      child:
                                                          EditLoanBottomSheet(
                                                        idPrestamo:
                                                            prestamo?.codigo ??
                                                                0,
                                                        isNuevo: false,
                                                        isRenew: null,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );

                                              if (result != null) {
                                                await Future.delayed(
                                                        const Duration(
                                                            milliseconds: 300))
                                                    .then((value) {
                                                  if (typeSearch == true) {
                                                    _handleSearchByDni(
                                                      searchDocument,
                                                    );
                                                  } else {
                                                    _handleSearchByGeneral(
                                                      searchCriterio,
                                                      searchCategoria,
                                                    );
                                                  }
                                                });
                                              }
                                            } else {
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
                                                  isScrollControlled: false,
                                                  context: context,
                                                  builder: (_) {
                                                    return BlocProvider.value(
                                                      value: widget.loansBloc,
                                                      child: Padding(
                                                        padding: MediaQuery.of(
                                                                context)
                                                            .viewInsets,
                                                        child:
                                                            EditLoanBottomSheet(
                                                          idPrestamo: prestamo
                                                                  ?.codigo ??
                                                              0,
                                                          isNuevo: true,
                                                          isRenew:
                                                              optionBottomSheet,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );

                                                if (result != null) {
                                                  await Future.delayed(
                                                          const Duration(
                                                              milliseconds:
                                                                  300))
                                                      .then((value) {
                                                    if (typeSearch == true) {
                                                      _handleSearchByDni(
                                                        searchDocument,
                                                      );
                                                    } else {
                                                      _handleSearchByGeneral(
                                                        searchCriterio,
                                                        searchCategoria,
                                                      );
                                                    }
                                                  });
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
                                      //if (auth.user.role?.id == 2 &&
                                      /*   if (auth.user.isAdmin == true &&
                                                      prestamo?.cerrado == true)
                                                    SizedBox(
                                                      height: 38,
                                                      width: 38,
                                                      child: IconButton(
                                                        padding: EdgeInsets.zero,
                                                        onPressed: () async {
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
                                                                  value: loansBloc,
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
                                        
                                                            if (result != null) {
                                                              //TODO :: Cargar todo
                                                              await Future.delayed(
                                                                      const Duration(
                                                                          milliseconds:
                                                                              300))
                                                                  .then((value) {
                                                                loansBloc.add(
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
                                                          color: Colors.yellow,
                                                        ),
                                                      ),
                                                    ),
                                                 */
                                      if (prestamo?.cerrado == false)
                                        // Pagar prestamo
                                        SizedBox(
                                          height: 38,
                                          width: 38,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () async {
                                              await showDialog<bool>(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (_) {
                                                  return BlocProvider.value(
                                                    value: widget.loansBloc,
                                                    child:
                                                        PaymentLoanDialogClient(
                                                      nroPrestamo:
                                                          prestamo?.codigo,
                                                    ),
                                                  );
                                                },
                                              );

                                              print('typeee 1: ${typeSearch}');
                                              print(
                                                  'typeee 2: ${searchDocument}');
                                              print(
                                                  'typeee 3: ${searchCriterio}');

                                              if (typeSearch == true) {
                                                _handleSearchByDni(
                                                  searchDocument,
                                                );
                                              } else {
                                                _handleSearchByGeneral(
                                                  searchCriterio,
                                                  searchCategoria,
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
                                              await showDialog<bool>(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (_) {
                                                  return BlocProvider.value(
                                                    value: widget.loansBloc,
                                                    child:
                                                        AddAmountLoanDialogClient(
                                                      nroPrestamo:
                                                          prestamo?.codigo,
                                                    ),
                                                  );
                                                },
                                              );

                                              if (typeSearch == true) {
                                                _handleSearchByDni(
                                                  searchDocument,
                                                );
                                              } else {
                                                _handleSearchByGeneral(
                                                  searchCriterio,
                                                  searchCategoria,
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
                                                await showDialog<bool>(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (_) {
                                                    return BlocProvider.value(
                                                      value: widget.loansBloc,
                                                      child:
                                                          ShowDialogBillingLoan(
                                                        nroPrestamo:
                                                            prestamo.codigo,
                                                        dniCustomer:
                                                            customer?.dni,
                                                      ),
                                                    );
                                                  },
                                                );

                                                if (typeSearch == true) {
                                                  _handleSearchByDni(
                                                    searchDocument,
                                                  );
                                                } else {
                                                  _handleSearchByGeneral(
                                                    searchCriterio,
                                                    searchCategoria,
                                                  );
                                                }
                                              } else {
                                                // Abrir excel - verde
                                                Navigator.push(context,
                                                    MaterialPageRoute(
                                                  builder: (context) {
                                                    return PdfPreviewFacturaPage(
                                                      url: prestamo
                                                              ?.boleta?.pdf ??
                                                          '',
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
                                                  .read<SolicitudRepository>()
                                                  .getSolicitudByIdPrestamo(
                                                    idPrestamo:
                                                        prestamo?.codigo ?? 0,
                                                  );

                                              if (user?.role?.nombre ==
                                                      'Usuario' &&
                                                  result &&
                                                  mounted) {
                                                await showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder: (_) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                        'Solicitar Permiso',
                                                      ),
                                                      content: const Text(
                                                        'No tiene permisos para realizar esta acción. ¿Desea solicitar permiso al administrador?',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            widget.loansBloc
                                                                .add(
                                                              CreateSolicitud(
                                                                prestamoId: prestamo
                                                                        ?.codigo
                                                                        .toString() ??
                                                                    '',
                                                                estado:
                                                                    'PENDIENTE',
                                                                usuarioId:
                                                                    user?.id ??
                                                                        0,
                                                              ),
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Si, Enviar',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: const Text(
                                                            'No, Salir',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              } else if (mounted) {
                                                final result = await showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (_) =>
                                                      BlocProvider.value(
                                                    value: widget.loansBloc,
                                                    child: DeleteLoanDialog(
                                                      idLoan:
                                                          prestamo?.codigo ?? 0,
                                                      idCaja:
                                                          prestamo?.caja?.id ??
                                                              0,
                                                    ),
                                                  ),
                                                );

                                                if (result != null) {
                                                  if (typeSearch == true) {
                                                    _handleSearchByDni(
                                                      searchDocument,
                                                    );
                                                  } else {
                                                    _handleSearchByGeneral(
                                                      searchCriterio,
                                                      searchCategoria,
                                                    );
                                                  }
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
                                              await showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (_) =>
                                                    BlocProvider.value(
                                                  value: widget.loansBloc,
                                                  child: UpdateStatusLoanDialog(
                                                    idLoan:
                                                        prestamo?.codigo ?? 0,
                                                  ),
                                                ),
                                              );

                                              if (typeSearch == true) {
                                                _handleSearchByDni(
                                                  searchDocument,
                                                );
                                              } else {
                                                _handleSearchByGeneral(
                                                  searchCriterio,
                                                  searchCategoria,
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
                            ),
                          );
                        } else {
                          /* return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ); */
                          return const SizedBox();
                        }
                      },
                    ),

                  if (customer == null && typeSearch == true)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: const Text(
                        'No hay prestamos registrados',
                      ),
                    ),
                  const SizedBox(height: 15),
                ],
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

                          if (result != null) {
                            _handleSearchByDni(
                              result as String,
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
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
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: AppColors.black.withOpacity(0.15),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
