import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/historial/view/historial_user_details_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/historial/view/historial_user_ventas_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistorialView extends StatelessWidget {
  const HistorialView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => HistorialBloc(
        userRepository: context.read(),
        historialRepository: context.read(),
        salesRepository: context.read(),
        preferences: context.read(),
      )..add(GetAllHistorialEvent()),
      child: Builder(builder: (context) {
        return BlocBuilder<HistorialBloc, HistorialState>(
          builder: (context, state) {
            switch (state.historialStatus) {
              case HistorialStatus.loading || HistorialStatus.initial:
                return const ButtonStateLoading();

              case HistorialStatus.error:
                return ButtonStateError(
                  onPressed: () {
                    context.read<HistorialBloc>().add(GetAllHistorialEvent());
                  },
                );

              case HistorialStatus.loaded:
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Historial de Usuarios',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (state.listUsers != null) ...[
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: 10,
                            ),
                            shrinkWrap: true,
                            itemCount: state.listUsers!.length,
                            itemBuilder: (context, index) {
                              final user = state.listUsers![index];
                              return ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${user.nombre} ${user.apellido}',
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.normal,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            user.userName,
                                            maxLines: 3,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Icono de reportes
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BlocProvider.value(
                                              value:
                                                  context.read<HistorialBloc>(),
                                              child: HistorialUserVentasView(
                                                userId: user.id,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.sim_card_download_sharp,
                                        color: AppColors.red,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BlocProvider.value(
                                              value:
                                                  context.read<HistorialBloc>(),
                                              child: HistorialUserDetailsView(
                                                userId: user.id,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.search,
                                        color: AppColors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 15),
                        ] else ...[
                          const SizedBox(),
                        ]
                      ],
                    ),
                  ),
                );
            }
          },
        );
      }),
    );
  }
}
