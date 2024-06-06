import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class HistorialUserDetailsView extends StatefulWidget {
  const HistorialUserDetailsView({
    super.key,
    required this.userId,
  });
  final int userId;

  @override
  State<HistorialUserDetailsView> createState() =>
      _HistorialUserDetailsViewState();
}

class _HistorialUserDetailsViewState extends State<HistorialUserDetailsView> {
  @override
  void initState() {
    super.initState();
    callApi();
  }

  void callApi() {
    context.read<HistorialBloc>().add(
          GetHistorialByDocumentEvent(
            widget.userId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: const Text('Detalle Historial Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: BlocBuilder<HistorialBloc, HistorialState>(
          builder: (context, state) {
            switch (state.historialDetailsStatus) {
              case HistorialStatus.loading || HistorialStatus.initial:
                return const ButtonStateLoading();

              case HistorialStatus.error:
                return ButtonStateError(
                  onPressed: () {
                    callApi();
                  },
                );

              case HistorialStatus.loaded:
                final listHistorial = state.listHistorial;
                if (listHistorial!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay acciones registradas por el usuario',
                    ),
                  );
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => const SizedBox(
                            height: 10,
                          ),
                          shrinkWrap: true,
                          itemCount: listHistorial?.length ?? 0,
                          itemBuilder: (context, index) {
                            final historial = listHistorial?[index];
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  'ACCIÓN: ${historial?.accion ?? ''}',
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Detalle: ${historial?.detalle ?? ''}',
                                    ),
                                    Text(
                                      'Fecha: ${DateFormat('dd/MM/yyyy - hh:mm').format(DateTime.parse(historial?.createdAt ?? '').toLocal())}',
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
            }
          },
        ),
      ),
    );
  }
}
