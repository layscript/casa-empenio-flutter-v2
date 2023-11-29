import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

abstract class GenerateDocumentPdf {
  static Future<Uint8List> generarDocumento(
      Uint8List cabecera, Uint8List body) async {
    final pdf = pw.Document();
    // necesito agregar una pagina en formato A4 que contenga la imagen en formato Uint8list en posicion horizontal y se repita 3 veces en todo el documento
    final a = pw.MemoryImage(cabecera);
    final b = pw.MemoryImage(body);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // orientation: pw.PageOrientation.landscape,
        build: (context) => [
          pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // pw.SizedBox(height: 10),
                pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(children: [
                        pw.Image(a, width: 150),
                        pw.SizedBox(height: 10),
                        pw.Image(b, width: 150),
                      ]),
                      // pw.SizedBox(width: 20),
                      pw.Column(children: [
                        pw.Image(a, width: 150),
                        pw.SizedBox(height: 10),
                        pw.Image(b, width: 150),
                      ]),
                      // pw.SizedBox(width: 20),
                      pw.Column(children: [
                        pw.Image(a, width: 150),
                        pw.SizedBox(height: 10),
                        pw.Image(b, width: 150),
                      ]),
                    ]),
              ]),
        ],
      ),
    );

    return await pdf.save();
  }
}
