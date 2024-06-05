import 'dart:typed_data';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:html_editor_enhanced/html_editor.dart';

const html = '''
<!DOCTYPE html>
<html>
  <head>
    <style>
      body {
        font-family: Arial, sans-serif;
        font-size: 12px;
      }
      .title {
        text-align: center;
        /* font-weight: bold; */
        /* font-size: 14px; */
      }
      .right-align {
        text-align: right;
        margin-top: 20px;
        margin-bottom: 20px;
      }
      .bold {
        font-weight: bold;
      }
      .center {
        text-align: center;
      }
      .table {
        width: 100%;
        border-collapse: collapse;
      }
      .table,
      .table th,
      .table td {
        border: 1px solid black;
      }
      .table th,
      .table td {
        padding: 8px;
        text-align: left;
      }
      .signatures {
        display: flex;
        justify-content: space-evenly;
        padding: 20px 0;
        margin-top: 100px;
      }
      .signature {
        text-align: center;
      }
      .interlineado {
        margin: 0;
      }
    </style>
  </head>
  <body>
    <h1 class="title">
      CONTRATO DE MUTUO A TÍTULO ONEROSO CON GARANTÍA PRENDARIA
    </h1>

    <p class="right-align">{{fecha}}</p>

    <p>
      Por el presente documento se hace constar el contrato de MUTUO CON
      GARANTÍA PRENDARIA DE "VEHÍCULOS, ARTEFACTOS Y OTROS", que celebran de una
      parte como el MUTUANTE,
      <span class="bold">NEGOCIOS MÚLTIPLES MAYTA EIRL</span>, identificado con
      RUC N° 20611213221, debidamente representado por su representante legal,
      <span class="bold">MAYTA TORRE JOEL MAYCO</span>, identificado con DNI N°
      46864068, con domicilio fiscal sito en CALLE URUBAMBA MZ 8 LOTE 8 -
      UCAYALI - ATALAYA; y de la otra parte como EL(LA) MUTUATARIO(A), el(la)
      Sr(a) <span class="bold">{{nombre}}</span>, identificado(a) con DNI N°
      <span class="bold">{{dni}}</span>, con domicilio en
      <span class="bold">{{domicilio}}</span>, de acuerdo a los términos y
      condiciones siguientes:
    </p>

    <h2>Tablas de Prendas</h2>
    <table class="table">
      <thead>
        <tr>
          <th>Nombre</th>
          <th>Marca</th>
          <th>Modelo</th>
          <th>Serie</th>
          <th>Color</th>
          <th>Estado</th>
        </tr>
      </thead>
      <tbody>
        <!-- Aquí se insertarán las filas generadas -->
      </tbody>
    </table>

    <div class="signatures">
      <div class="signature">
        <p class="interlineado">________</p>
        <p class="interlineado">FIRMA DEL CLIENTE</p>
        <p class="interlineado">{{nombre}}</p>
        <p class="interlineado">DNI: {{dni}}</p>
      </div>
      <div class="signature">
        <p class="interlineado">___________</p>
        <p class="interlineado">NEGOCIOS MULTIPLES MAYTA E.I.R.L.</p>
        <p class="interlineado">JOEL MAYCO MAYTA TORRE</p>
        <p class="interlineado">RUC: 20611213221</p>
      </div>
    </div>
  </body>
</html>
''';

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
    final templateContent = html;
    setState(() {
      htmlContent = templateContent;
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
