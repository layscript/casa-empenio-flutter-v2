part of '../contract_reports_body_view.dart';

class _ListAumentos extends StatelessWidget {
  const _ListAumentos({
    required this.constraints,
    required this.state,
    required this.reportsBloc,
  });
  final BoxConstraints constraints;
  final ReportsState state;
  final ReportsBloc reportsBloc;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<Preferences>().token;

    return Container(
      //color: Colors.green,
      width: double.infinity,
      height: constraints.maxHeight * 0.30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Aumentos (${state.listIncrease.length})',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            //color: Colors.pink,
            width: double.infinity,
            height: constraints.maxHeight * 0.25,
            child: BlocBuilder<ReportsBloc, ReportsState>(
              builder: (context, state) {
                switch (state.statusIncreases) {
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
                    if (state.listIncrease.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay registros de aumentos',
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.listIncrease.length,
                        itemBuilder: (context, index) {
                          final aumento = state.listIncrease[index];
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
                                      document:
                                          aumento.prestamo?.cliente?.dni ?? '',
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                dense: true,
                                contentPadding:
                                    const EdgeInsets.only(left: 10, right: 0),
                                title: Text(
                                  '${aumento.prestamo?.codigo.toString().padLeft(6, '0')} - S/. ${oCcy.format(double.parse(aumento.monto ?? '0.00'))}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Obs: ${aumento.observaciones}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${aumento.prestamo?.cliente?.nombres} ${aumento.prestamo?.cliente?.apellidos}',
                                    ),
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
                                            return AlertDialog(
                                              title: const Text(
                                                'Eliminar Aumento',
                                              ),
                                              content: const Text(
                                                '¿Está seguro de eliminar este aumento?',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Cancelar'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    reportsBloc.add(
                                                      DeleteIncreaseEvent(
                                                        aumento.id,
                                                        auth?.id,
                                                      ),
                                                    );

                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    'Aceptar',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(
                                        DateTime.parse(
                                          aumento.fecha ?? '',
                                        ),
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
            ),
          ),
        ],
      ),
    );
  }
}
