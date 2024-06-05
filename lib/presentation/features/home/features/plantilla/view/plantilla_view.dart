import 'dart:typed_data';
import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class PlantillaView extends StatelessWidget {
  const PlantillaView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlantillaBloc(
        plantillaRepository: context.read(),
      ),
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
  String htmlContent = '';
  Uint8List? pdfData;

  @override
  void initState() {
    super.initState();
    loadTemplate();
  }

  Future<void> loadTemplate() async {
    final templateContent =
        await context.read<PlantillaRepository>().getPlantilla();
    ;
    setState(() {
      htmlContent = templateContent.getOrElse(() => '');
      // Esperar un segundo para que el editor cargue el contenido
      Future.delayed(const Duration(seconds: 2), () {
        controller.setText(htmlContent);
      });
    });
  }

  Future<Uint8List> crearContratoPdf(
      String htmlContent, Map<String, dynamic> data) async {
    // Generar las filas de la tabla de prendas
    StringBuffer tableRows = StringBuffer();
    for (var item in data['prendas']) {
      tableRows.write('<tr>');
      tableRows.write('<td>${item['nombre'] ?? ''}</td>');
      tableRows.write('<td>${item['marca'] ?? ''}</td>');
      tableRows.write('<td>${item['modelo'] ?? ''}</td>');
      tableRows.write('<td>${item['serie'] ?? ''}</td>');
      tableRows.write('<td>${item['color'] ?? ''}</td>');
      tableRows.write('<td>${item['estado'] ?? ''}</td>');
      tableRows.write('</tr>');
    }

    // Insertar las filas generadas en el HTML
    String filledTemplate = htmlContent.replaceFirst(
        '<!-- Aquí se insertarán las filas generadas -->',
        tableRows.toString());

    // Reemplazar los demás marcadores
    data.forEach((key, value) {
      if (value is! List) {
        filledTemplate =
            filledTemplate.replaceAll('{{$key}}', value.toString());
      }
    });

    final pdf = await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: filledTemplate,
    );

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: HtmlEditor(
            controller: controller,
            htmlEditorOptions: HtmlEditorOptions(
              hint: 'Edita tu contrato aquí...',
              initialText: htmlContent,
            ),
            otherOptions: const OtherOptions(
              height: 800,
            ),
          ),
        ),
        ElevatedButton(
            onPressed: () async {
              final data = await controller.getText();

              final result =
                  await context.read<PlantillaRepository>().setPlantilla(data);

              if (result.isRight()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Plantilla guardada correctamente'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Ocurrió un error: ${result.leftMap((a) => a).getOrElse(() => '')}'),
                  ),
                );
              }
            },
            child: const Text('Guardar')),
        ElevatedButton(
          onPressed: () async {
            final editedHtmlContent = await controller.getText();
            final data = {
              'fecha': '10 de Mayo de 2024',
              'nombre': 'Juan Pérez',
              'dni': '12345678',
              'domicilio': 'Av. Siempre Viva 123',
              'prendas': [
                {
                  'nombre': 'Laptop',
                  'marca': 'Dell',
                  'modelo': 'XPS 13',
                  'serie': 'ABC123',
                  'color': 'Negro',
                  'estado': 'Bueno',
                },
                {
                  'nombre': 'Laptop',
                  'marca': 'Dell',
                  'modelo': 'XPS 13',
                  'serie': 'ABC123',
                  'color': 'Negro',
                  'estado': 'Bueno',
                },
                {
                  'nombre': 'Laptop',
                  'marca': 'Dell',
                  'modelo': 'XPS 13',
                  'serie': 'ABC123',
                  'color': 'Negro',
                  'estado': 'Bueno',
                }
              ],
            };
            final pdfData = await crearContratoPdf(editedHtmlContent, data);

            setState(() {
              this.pdfData = pdfData;
            });
          },
          child: const Text('Generar PDF'),
        ),
        pdfData != null
            ? Expanded(
                child: PdfPreview(
                  build: (format) => pdfData!,
                ),
              )
            : Container(),
      ],
    );
  }
}
