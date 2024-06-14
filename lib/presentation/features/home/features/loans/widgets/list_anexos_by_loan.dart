import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ListAnexosByLoan extends StatefulWidget {
  const ListAnexosByLoan({
    super.key,
    required this.prestamoId,
    this.onPressed,
  });
  final int prestamoId;
  final void Function()? onPressed;

  @override
  State<ListAnexosByLoan> createState() => _ListAnexosByLoanState();
}

class _ListAnexosByLoanState extends State<ListAnexosByLoan> {
  @override
  void initState() {
    super.initState();
    context.read<LoansBloc>().add(GetAnexosLoan(widget.prestamoId.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Visitas del Prestamo: ${widget.prestamoId}',
          ),
        ],
      ),
      content: Builder(builder: (context) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          //height: double.infinity,
          //height: MediaQuery.of(context).size.height,
          child: CustomScrollView(
            slivers: [
              BlocBuilder<LoansBloc, LoansState>(
                builder: (context, state) {
                  switch (state.listAnexosStatus) {
                    case AnexosLoanStatus.initial || AnexosLoanStatus.loading:
                      return const SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 30),
                            CircularProgressIndicator(),
                          ],
                        ),
                      );

                    case AnexosLoanStatus.error:
                      return const SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 30),
                            Text(
                              'Ocurrió un problema, inténtelo de nuevo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );

                    case AnexosLoanStatus.success:
                      final anexos = state.listAnexos;
                      if (anexos.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 30),
                              Text(
                                'No se encontraron anexos registrados',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return SliverList.separated(
                          separatorBuilder: (context, index) => const Divider(
                            height: 10,
                          ),
                          itemCount: anexos.length,
                          itemBuilder: (context, index) {
                            final anexo = state.listAnexos[index];

                            return ListTile(
                              trailing: CustomImageApp(
                                urlImg: anexo.url,
                              ),
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Descripción: ${anexo.descripcion}',
                                maxLines: 3,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Tipo: ${anexo.tipo}',
                                  ),
                                  Text(
                                    'Fecha: ${setDateTimeToLocal(anexo.createdAt)}',
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                  }
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
