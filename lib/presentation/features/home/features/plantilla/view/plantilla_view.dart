import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html_editor_enhanced/html_editor.dart';

final data = {
  "numero": 4312,
  "nombre": "GUISELA GEORGINA GUZMAN SALAZAR",
  "dni": "47103117",
  "domicilio": "CALLE LAS PALMERAS MZ. G LT. 9",
  "fechaVencimiento": "2024-05-07 04:59:59.000Z",
  "monto": "50.0",
  "montoPagar": "60.0",
  "prendas": [
    {
      "nombre": "Balon de gas Limagas",
      "marca": "Limagas",
      "modelo": "GAS",
      "serie": "",
      "color": "Azul",
      "estado": "regular"
    }
  ],
  "nombreAval": "",
  "dniAval": "",
  "interes": "20.0",
  "fecha": "4 de Junio del 2024"
};

class PlantillaView extends StatefulWidget {
  const PlantillaView({super.key});

  @override
  State<PlantillaView> createState() => _PlantillaViewState();
}

class _PlantillaViewState extends State<PlantillaView> {
  HtmlEditorController controller = HtmlEditorController();
  String? htmlContent;
  @override
  void initState() {
    super.initState();
    getLastTemplate();
  }

  void getLastTemplate() async {
    context.read<PlantillaBloc>().add(GetLastPlantilla());
    await Future.delayed(const Duration(seconds: 1), () {});
    loadTemplate(null);
  }

  void loadTemplate(String? url) async {
    if (url != null) {
      controller.setText(url);
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        final plantillaState = context.read<PlantillaBloc>().state;
        controller.setText(plantillaState.htmlContent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantillaBloc = context.read<PlantillaBloc>();

    return BlocConsumer<PlantillaBloc, PlantillaState>(
      listener: (context, state) async {
        if (state.plantillaSelected != '') {
          loadTemplate(state.plantillaSelected);
        }

        if (state.status == PlantillaStatus.failure) {
          ErrorSnackbar.show(
            context,
            state.error ?? 'Algo salió mal.',
          );
        }

        if (state.status == PlantillaStatus.navigate) {
          if (!mounted) return;

          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PdfPreviewPage(
                contrato: ContratoEntity.fromJson(data),
              ),
            ),
          );

          getLastTemplate();
        }
      },
      builder: (context, state) {
        if (state.status == PlantillaStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.status == PlantillaStatus.success) {
          return Column(
            children: [
              Expanded(
                child: HtmlEditor(
                  controller: controller,
                  htmlEditorOptions: HtmlEditorOptions(
                    hint: 'Edita tu contrato aquí...',
                    initialText: state.htmlContent,
                  ),
                  otherOptions: const OtherOptions(
                    height: 800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: state.plantillaSelected != null &&
                        state.plantillaSelected != ''
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return alertSave(context, plantillaBloc);
                                  },
                                );
                              },
                              child: const Text('Guardar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final template = await controller.getText();
                                if (!mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PdfPreviewPage(
                                      contrato: ContratoEntity.fromJson(data),
                                      templateState: template,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Previsualizar'),
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return alertSave(context, plantillaBloc);
                            },
                          );
                        },
                        child: const Text('Guardar y Previsualizar'),
                      ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  AlertDialog alertSave(BuildContext context, PlantillaBloc plantillaBloc) {
    return AlertDialog(
      title: const Text(
        '¿Estás seguro que deseas guardar?',
      ),
      content: const Text(
        'Se creará una plantilla adicional.',
        style: TextStyle(
          color: AppColors.secondaryText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: () async {
            final data = await controller.getText();
            plantillaBloc.add(
              GeneratePlantilla(data),
            );

            if (mounted) Navigator.pop(context);
          },
          child: const Text('Si, guardar'),
        ),
      ],
    );
  }
}
