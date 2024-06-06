import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class PlantillaView extends StatelessWidget {
  const PlantillaView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => PlantillaBloc(
        plantillaRepository: context.read(),
      )..add(GetPlantilla()),
      child: const PlantillaBody(),
    );
  }
}

class PlantillaBody extends StatefulWidget {
  const PlantillaBody({super.key});

  @override
  State<PlantillaBody> createState() => _PlantillaBodyState();
}

class _PlantillaBodyState extends State<PlantillaBody> {
  HtmlEditorController controller = HtmlEditorController();
  String? htmlContent;
  @override
  void initState() {
    super.initState();
    loadTemplate();
  }

  void loadTemplate() async {
    Future.delayed(const Duration(seconds: 1), () {
      final plantillaState = context.read<PlantillaBloc>().state;
      controller.setText(plantillaState.htmlContent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final plantillaBloc = context.read<PlantillaBloc>();

    return BlocConsumer<PlantillaBloc, PlantillaState>(
      listener: (context, state) {
        if (state.status == PlantillaStatus.loading) {
          OverlayLoader.show(context);
        } else {
          OverlayLoader.hide();

          if (state.status == PlantillaStatus.failure) {
            ErrorSnackbar.show(
              context,
              state.error ?? 'Algo salió mal.',
            );
          }

          if (state.status == PlantillaStatus.navigate) {
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

            if (!mounted) return;

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PdfPreviewPage(
                  contrato: ContratoEntity.fromJson(data),
                ),
              ),
            );
          }
        }
      },
      builder: (context, state) {
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
              child: ElevatedButton(
                onPressed: () async {
                  final data = await controller.getText();
                  plantillaBloc.add(
                    GeneratePlantilla(data),
                  );
                },
                child: const Text('Guardar y Previsualizar'),
              ),
            ),
          ],
        );
      },
    );
  }
}
