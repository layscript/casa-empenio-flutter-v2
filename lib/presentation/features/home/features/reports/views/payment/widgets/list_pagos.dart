part of '../payment_reports_body_view.dart';

class _ListPagos extends StatelessWidget {
  const _ListPagos({
    super.key,
    required this.constraints,
    required this.state,
  });
  final BoxConstraints constraints;
  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.blue,
      width: double.infinity,
      height: constraints.maxHeight * 0.44,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pagos (${state.listPayments.length})',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                  height: constraints.maxHeight * 0.30,
                  child: BlocBuilder<ReportsBloc, ReportsState>(
                    builder: (context, state) {
                      switch (state.statusPayments) {
                        case ReportsStatus.error:
                          return const Center(
                            child: Text(
                              'Ocurrió un error, intentelo de nuevo',
                            ),
                          );

                        case ReportsStatus.loading:
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

                        case ReportsStatus.success:
                          if (state.listPayments.isEmpty) {
                            return const Center(
                              child: Text(
                                'No hay registros de pagos',
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else {
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: state.listPayments.length,
                              itemBuilder: (context, index) {
                                final pago = state.listPayments[index];
                                final fechaCreacion =
                                    DateTime.parse(pago.fecha ?? '').toLocal();
                                final fechaFormateada =
                                    DateFormat('dd/MM/yyyy - kk:mm')
                                        .format(fechaCreacion);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider(
                                          create: (context) => LoansBloc(
                                            customerRepository: context.read(),
                                            loansRepository: context.read(),
                                            cajaRepository: context.read(),
                                            preferences: context.read(),
                                            solicitudRepository: context.read(),
                                            anexoRepository: context.read(),
                                            categoriesRepository:
                                                context.read(),
                                          ),
                                          child: ReportsDetailView(
                                            document:
                                                pago.prestamo?.cliente?.dni ??
                                                    '',
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.only(
                                        left: 10,
                                        right: 0,
                                      ),
                                      title: Text(
                                        'Cod.: ${pago.prestamo?.codigo.toString().padLeft(6, '0')} - S/.${oCcy.format(double.parse(pago.monto ?? '0.00'))}',
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 3),
                                          Text(
                                            fechaFormateada,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${pago.prestamo?.cliente?.nombres} ${pago.prestamo?.cliente?.apellidos}',
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () {},
                                            icon: pago.efectivo == true
                                                ? const Text(
                                                    'S/.',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      fontFamily: 'Roboto',
                                                    ),
                                                  )
                                                : const Text(
                                                    'D',
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        fontFamily: 'Roboto'),
                                                  ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (_) {
                                                  return BlocProvider.value(
                                                    value: context
                                                        .read<ReportsBloc>(),
                                                    child: ShowDetailsReportPay(
                                                      idPago: pago.id,
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
                                          IconButton(
                                            onPressed: () async {
                                              final result =
                                                  await showDialog<bool>(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (_) {
                                                  return BlocProvider(
                                                    create: (context) =>
                                                        LoansBloc(
                                                      customerRepository:
                                                          context.read(),
                                                      loansRepository:
                                                          context.read(),
                                                      cajaRepository:
                                                          context.read(),
                                                      preferences:
                                                          context.read(),
                                                      solicitudRepository:
                                                          context.read(),
                                                      anexoRepository:
                                                          context.read(),
                                                      categoriesRepository:
                                                          context.read(),
                                                    ),
                                                    child: DeleteLoanDialog(
                                                        idLoan: pago.id ?? 0,
                                                        isPayment: true,
                                                        idCaja:
                                                            pago.caja?.id ?? 0),
                                                  );
                                                },
                                              );

                                              if (result != null) {
                                                await Future.delayed(
                                                        const Duration(
                                                            milliseconds: 300))
                                                    .then((value) {
                                                  context
                                                      .read<ReportsBloc>()
                                                      .add(
                                                        const GetLoadInitialDataPayments(
                                                          end: null,
                                                          start: null,
                                                        ),
                                                      );
                                                });
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.remove_circle_rounded,
                                              color: Colors.red,
                                            ),
                                          ),
                                          if (pago.prestamo?.isRenewed == true)
                                            const CircleAvatar(
                                              radius: 10,
                                              backgroundColor: Colors.purple,
                                              child: Text(
                                                'R',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                        default:
                          return const SizedBox();
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
