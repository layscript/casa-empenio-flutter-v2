import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/button_state_error.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/button_state_loading.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/notify/bloc/notify_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotifyView extends StatelessWidget {
  const NotifyView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => NotifyBloc(
        solicitudRepository: context.read(),
      )..add(GetSolicitudesNotify()),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.blue,
            title: const Text('Solicitudes'),
            centerTitle: true,
          ),
          body: BlocBuilder<NotifyBloc, NotifyState>(
            builder: (context, state) {
              switch (state.notifyStatus) {
                case NotifyStatus.initial || NotifyStatus.loading:
                  return const Center(child: ButtonStateLoading());

                case NotifyStatus.error:
                  return Center(
                    child: ButtonStateError(
                      onPressed: () {
                        context.read<NotifyBloc>().add(GetSolicitudesNotify());
                      },
                    ),
                  );

                case NotifyStatus.loaded:
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Usuarios que solicitan anular un prestamo:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        if (state.listSolicitud!.isEmpty)
                          const Text('No hay solicitudes de usuarios'),
                        if (state.listSolicitud!.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: state.listSolicitud!.length,
                            itemBuilder: (context, index) {
                              final solicitud = state.listSolicitud![index];
                              return ListTile(
                                title: Text(
                                    '${solicitud.usuario?.nombre ?? ''} ${solicitud.usuario?.apellido ?? ''}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cod. Prestamo: ${solicitud.prestamoId}',
                                      style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    Text(
                                      'Estado: ${solicitud.estado}',
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: solicitud.estado == 'ACEPTADO'
                                    ? GestureDetector(
                                        onTap: () {
                                          context.read<NotifyBloc>().add(
                                                ChangeStatusSolicitudesNotify(
                                                  solicitudId: solicitud.id,
                                                  prestamoId:
                                                      solicitud.prestamoId,
                                                  estado: 'ANULADO',
                                                  usuarioId:
                                                      solicitud.usuario?.id ??
                                                          0,
                                                ),
                                              );
                                        },
                                        child: const Chip(
                                          backgroundColor: Colors.purple,
                                          label: Text(
                                            'Anular',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        width: 170,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  context
                                                      .read<NotifyBloc>()
                                                      .add(
                                                        ChangeStatusSolicitudesNotify(
                                                          solicitudId:
                                                              solicitud.id,
                                                          prestamoId: solicitud
                                                              .prestamoId,
                                                          estado: 'ACEPTADO',
                                                          usuarioId: solicitud
                                                                  .usuario
                                                                  ?.id ??
                                                              0,
                                                        ),
                                                      );
                                                },
                                                child: const Chip(
                                                  backgroundColor: Colors.green,
                                                  label: Text(
                                                    'Aceptar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  context
                                                      .read<NotifyBloc>()
                                                      .add(
                                                        ChangeStatusSolicitudesNotify(
                                                          solicitudId:
                                                              solicitud.id,
                                                          prestamoId: solicitud
                                                              .prestamoId,
                                                          estado: 'RECHAZADO',
                                                          usuarioId: solicitud
                                                                  .usuario
                                                                  ?.id ??
                                                              0,
                                                        ),
                                                      );
                                                },
                                                child: const Chip(
                                                  backgroundColor: Colors.red,
                                                  label: Text(
                                                    'Rechazar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
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
            },
          ),
        );
      }),
    );
  }
}
