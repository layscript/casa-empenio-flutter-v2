part of '../payment_reports_body_view.dart';

class _ListPrestamosCerrados extends StatelessWidget {
  const _ListPrestamosCerrados({
    super.key,
    required this.state,
    required this.constraints,
  });
  final BoxConstraints constraints;
  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.purple,
      width: double.infinity,
      height: constraints.maxHeight * 0.40,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Prestamos Cerrados (${state.listClosedLoans.length})',
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
                      switch (state.statusClosedLoans) {
                        case ReportsStatus.error:
                          return const Center(
                            child: Text('Ocurrió un error, intentelo de nuevo'),
                          );

                        case ReportsStatus.loading:
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

                        case ReportsStatus.success:
                          if (state.listClosedLoans.isEmpty) {
                            return const Center(
                              child: Text(
                                'No hay registros de prestamos cerrados',
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else {
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: state.listClosedLoans.length,
                              itemBuilder: (_, index) {
                                final prestamo = state.listClosedLoans[index];
                                final fechaCreacion =
                                    DateTime.parse(prestamo.fecha ?? '');
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
                                          ),
                                          child: ReportsDetailView(
                                            document:
                                                prestamo?.cliente?.dni ?? '',
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 5),
                                    decoration: BoxDecoration(
                                      color: prestamo.estado == 'CANCELADO'
                                          ? Colors.red[50]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.only(
                                        left: 10,
                                        right: 0,
                                      ),
                                      title: Text(
                                        'Cod.: ${prestamo.codigo.toString().padLeft(6, '0')} - S/.${oCcy.format(double.parse(prestamo.ganancia ?? '0.00') + double.parse(prestamo.monto ?? '0.00'))}',
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 3),
                                          Text(
                                            '$fechaFormateada- ${prestamo.estado}',
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${prestamo.cliente?.nombres} ${prestamo.cliente?.apellidos}',
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (prestamo.cerrado == true &&
                                              prestamo.estado != 'CANCELADO')
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                if (prestamo.boleta == null) {
                                                  final dniCustomer =
                                                      prestamo.cliente?.dni;

                                                  showDialog<bool>(
                                                    barrierDismissible: false,
                                                    context: context,
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
                                                        ),
                                                        child:
                                                            ShowDialogBillingLoan(
                                                          nroPrestamo:
                                                              prestamo.codigo,
                                                          dniCustomer:
                                                              dniCustomer,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                } else {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return PdfPreviewFacturaPage(
                                                          url: prestamo.boleta
                                                                  ?.pdf ??
                                                              '',
                                                          id: prestamo.codigo ??
                                                              0,
                                                          tipo: 'prestamo',
                                                          notaCredito: prestamo
                                                              .notaCredito,
                                                        );
                                                      },
                                                    ),
                                                  );
                                                }
                                              },
                                              icon: Icon(
                                                Icons.description,
                                                color: prestamo.boleta == null
                                                    ? Colors.blue
                                                    : prestamo.notaCredito!
                                                            .isEmpty
                                                        ? Colors.green
                                                        : Colors.red[400],
                                              ),
                                            ),
                                          if (prestamo.estado == 'LIQUIDADO')
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                final result =
                                                    await showDialog<bool?>(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (_) {
                                                    return BlocProvider.value(
                                                      value: context
                                                          .read<ReportsBloc>(),
                                                      child: AnularDialogReport(
                                                          codigo:
                                                              prestamo.codigo),
                                                    );
                                                  },
                                                );

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
                                              },
                                              icon: const Icon(
                                                Icons.delete_forever,
                                                color: Colors.red,
                                              ),
                                            ),
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
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
