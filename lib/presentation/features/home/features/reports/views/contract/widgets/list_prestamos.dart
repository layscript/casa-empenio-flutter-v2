part of '../contract_reports_body_view.dart';

class _ListPrestamos extends StatelessWidget {
  const _ListPrestamos({
    required this.constraints,
    required this.state,
    required this.reportsBloc,
  });
  final BoxConstraints constraints;
  final ReportsState state;
  final ReportsBloc reportsBloc;

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.yellow,
      width: double.infinity,
      height: constraints.maxHeight * 0.30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Prestamos (${state.listLoans.length})',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            //color: Colors.red,
            height: constraints.maxHeight * 0.25,
            child: BlocBuilder<ReportsBloc, ReportsState>(
              builder: (context, state) {
                switch (state.statusLoans) {
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
                    if (state.listLoans.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay registros de prestamos',
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.listLoans.length,
                        itemBuilder: (context, index) {
                          final prestamo = state.listLoans[index];
                          final fechaCreacion =
                              DateTime.parse(prestamo.fecha ?? '').toLocal();

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
                                      categoriesRepository: context.read(),
                                    ),
                                    child: ReportsDetailView(
                                      document: prestamo?.cliente?.dni ?? '',
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: 5,
                              ),
                              decoration: BoxDecoration(
                                  color: prestamo.estado == 'CANCELADO'
                                      ? Colors.red[50]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10)),
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
                                    Text(
                                      '$fechaFormateada - ${prestamo.estado}',
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${prestamo.cliente?.nombres} ${prestamo.cliente?.apellidos}',
                                    )
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
                                    if (prestamo.estado == 'VIGENTE')
                                      const Icon(
                                        Icons.circle,
                                        color: Colors.green,
                                      ),
                                    if (prestamo.estado == 'VENCIDO')
                                      const Icon(
                                        Icons.circle,
                                        color: Colors.red,
                                      ),
                                    if (prestamo.estado == 'CANCELADO')
                                      const Icon(
                                        Icons.circle,
                                        color: Colors.grey,
                                      ),
                                    if (prestamo.estado == 'PAGADO' ||
                                        prestamo.estado == 'LIQUIDADO')
                                      const Icon(
                                        Icons.circle,
                                        color: Colors.blueGrey,
                                      ),
                                    IconButton(
                                      onPressed: () async {
                                        if (prestamo.estado != 'CANCELADO' &&
                                            prestamo.estado != 'LIQUIDADO' &&
                                            prestamo.estado != 'PAGADO') {
                                          await showDialog<bool?>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) {
                                              return BlocProvider.value(
                                                value: reportsBloc,
                                                child: CancelDialogReportLoan(
                                                  codigo: prestamo.codigo ?? 0,
                                                  idCaja:
                                                      prestamo.caja?.id ?? 1,
                                                ),
                                              );
                                            },
                                          );

                                          /* reportsBloc.add(
                                                                const GetLoadInitialDataContracts(
                                                                  end: null,
                                                                  start: null,
                                                                ),
                                                              ); */
                                        }
                                      },
                                      icon: Icon(
                                        Icons.cancel,
                                        color: prestamo.estado == 'CANCELADO' ||
                                                prestamo.estado == 'PAGADO' ||
                                                prestamo.estado == 'LIQUIDADO'
                                            ? Colors.grey
                                            : Colors.red,
                                      ),
                                    ),
                                    if (prestamo.isRenewed == true)
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
            ),
          ),
        ],
      ),
    );
  }
}
