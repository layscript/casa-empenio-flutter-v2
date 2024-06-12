import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/anexos/widgets/add_anexo_dialog.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class AnexosView extends StatelessWidget {
  const AnexosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => AnexosBloc(
        anexoRepository: context.read(),
        preferences: context.read(),
      )..add(const GetAnexos(fin: null, inicio: null)),
      child: Builder(builder: (context) {
        return BlocBuilder<AnexosBloc, AnexosState>(
          builder: (context, state) {
            switch (state.anexosStatus) {
              case AnexosStatus.loading || AnexosStatus.initial:
                return const ButtonStateLoading();

              case AnexosStatus.error:
                return ButtonStateError(
                  message: state.error,
                  onPressed: () {
                    context
                        .read<AnexosBloc>()
                        .add(const GetAnexos(fin: null, inicio: null));
                  },
                );

              case AnexosStatus.loaded || AnexosStatus.success:
                final anexosBloc = context.read<AnexosBloc>();

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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                const Center(
                                  child: Text(
                                    'Lista de Anexos',
                                    style: TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                ListTile(
                                  dense: true,
                                  leading: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.calendar_today),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  title: FittedBox(
                                    child: Text(
                                      'Desde: ${DateFormat('dd/MM/yyyy').format(state.startAnexo)} Hasta: ${DateFormat('dd/MM/yyyy').format(state.endAnexo)}',
                                    ),
                                  ),
                                  trailing: IconButton(
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      final result = await showDateRangePicker(
                                        locale: const Locale('es'),
                                        context: context,
                                        firstDate: DateTime(2022, 1, 1),
                                        lastDate: DateTime(2030, 12, 31),
                                        currentDate: DateTime.now(),
                                        saveText: 'Done',
                                      );
                                      if (result != null) {
                                        anexosBloc.add(
                                          GetAnexos(
                                            inicio: result.start,
                                            fin: result.end,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.calendar_today),
                                  ),
                                ),
                                if (state.listAnexos.isEmpty)
                                  const Center(
                                    child: Text(
                                      'No hay anexos en la fecha seleccionada',
                                    ),
                                  ),
                                ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(
                                    height: 10,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: state.listAnexos.length,
                                  itemBuilder: (context, index) {
                                    final anexo = state.listAnexos[index];
                                    final prestamo = anexo.prestamo;

                                    return ListTile(
                                      title: Text(
                                        'Cod.: ${prestamo?.codigo.toString().padLeft(6, '0')} - S/. ${oCcy.format(double.parse(prestamo?.ganancia ?? '0.00') + double.parse(prestamo?.monto ?? '0.00'))}',
                                        maxLines: 3,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Descripción: ${anexo.descripcion}',
                                          ),
                                          Text(
                                            'Tipo: ${anexo.tipo}',
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () {},
                                            icon: const Icon(
                                              Icons.remove_red_eye_sharp,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: AppColors.red,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (_) {
                                                  return DeleteDialog(
                                                    title: 'Anexos',
                                                    onPressed: () => context
                                                        .read<AnexosBloc>()
                                                        .add(
                                                          DeleteAnexo(
                                                            id: anexo.id,
                                                          ),
                                                        ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 15),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        top: null,
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: defaultBoxShadow,
                          ),
                          child: Center(
                            child: PrimaryButton(
                              onPressed: () {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (_) {
                                    return AddAnexoDialog(
                                      onPressed: (anexo) {
                                        anexosBloc.add(
                                          SaveAnexo(
                                            description: anexo.description,
                                            imagenes: anexo.imagenes,
                                            prestamoId: anexo.prestamoId,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.circlePlus),
                                  SizedBox(width: 10),
                                  Text('Agregar Anexo'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
            }
          },
        );
      }),
    );
  }
}
