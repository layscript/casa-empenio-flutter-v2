import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShowPlantillasDialog extends StatefulWidget {
  const ShowPlantillasDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ShowPlantillasDialog(),
    );
  }

  @override
  State<ShowPlantillasDialog> createState() => _ShowPlantillasDialogState();
}

class _ShowPlantillasDialogState extends State<ShowPlantillasDialog> {
  @override
  void initState() {
    super.initState();
    context.read<PlantillaBloc>().add(GetPlantillas());
  }

  @override
  Widget build(BuildContext context) {
    final plantillaBloc = context.read<PlantillaBloc>();

    return AlertDialog(
      title: const Text('Lista de Plantillas'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context)
            .size
            .height, // Fijar la altura del contenedor
        child: BlocBuilder<PlantillaBloc, PlantillaState>(
          builder: (context, state) {
            switch (state.dialogStatus) {
              case PlantillaStatus.initial:
              case PlantillaStatus.loading:
              case PlantillaStatus.navigate:
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );

              case PlantillaStatus.failure:
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: Text('${state.error}')),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      onPressed: () => plantillaBloc.add(GetPlantillas()),
                      child: const Text('Volver a intentarlo'),
                    )
                  ],
                );

              case PlantillaStatus.success:
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.plantillas.length,
                  itemBuilder: (context, index) {
                    final plantilla = state.plantillas[index];
                    return ListTile(
                      title: Text('Plantilla Nro° ${plantilla.id}'),
                      subtitle: Text(
                        'F. Creación: ${setDateTimeToLocal(plantilla.createdAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          plantillaBloc.add(
                            SelectedPlantillaByText(plantilla.html),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_circle_right_outlined,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }
}
