import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/services/create_contracts_product_pdft.dart';
import 'package:casa_empenio_pe/presentation/app/services/services.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PdfPreviewPage extends StatelessWidget {
  final ContratoEntity contrato;
  final String? templateState;
  const PdfPreviewPage({
    Key? key,
    required this.contrato,
    this.templateState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Contrato'),
      ),
      body: PdfPreview(
        pdfFileName:
            'Contrato${contrato.numero.toString().padLeft(6, '0')}.pdf',
        initialPageFormat: PdfPageFormat.a4,
        pageFormats: const <String, PdfPageFormat>{
          'A4': PdfPageFormat.a4,
        },
        canChangeOrientation: false,
        build: (_) => CreateContractPdf.crearContratoPdf(
          contrato,
          context,
          templateState: templateState,
        ),
        canDebug: false,
      ),
    );
  }
}

class PdfPreviewVehiculoPage extends StatelessWidget {
  final Map<String, dynamic> vehiculo;
  final Map<String, dynamic> cliente;
  final int type;
  const PdfPreviewVehiculoPage({
    Key? key,
    required this.vehiculo,
    required this.type,
    required this.cliente,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrato'),
      ),
      body: PdfPreview(
        pdfFileName: 'Contrato.pdf',
        initialPageFormat: PdfPageFormat.a4,
        pageFormats: const <String, PdfPageFormat>{
          'A4': PdfPageFormat.a4,
        },
        canChangeOrientation: false,
        build: (context) => CreateContractsProductPdf.crearContratoVehiculoPdf(
            vehiculo, type, cliente),
        canDebug: false,
      ),
    );
  }
}

class PdfPreviewFacturaPage extends StatelessWidget {
  final String url;
  final int id;
  final String tipo;
  //final dynamic notaCredito;
  final List<CreditNoteEntity>? notaCredito;
  const PdfPreviewFacturaPage({
    Key? key,
    required this.url,
    required this.id,
    required this.tipo,
    required this.notaCredito,
  }) : super(key: key);

  createNotaCredito(BuildContext context) async {
    //TODO:: Acá falta si o si hacer!!

    final dynamic rr;
    if (tipo == 'venta') {
      final response = await context
          .read<LoansRepository>()
          .createSalesNote(id: id.toString());
      //rr = await productosProvider.createNotaVenta(id.toString());
    } else {
      //rr = await buscarProvider.createNotaPrestamo(id.toString());
      final response = await context
          .read<LoansRepository>()
          .createLoanNote(id: id.toString());
    }

    /* if (rr != null) {
      final String url = rr['pdf'];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewNotaPage(
            url: url.split('=')[1],
          ),
        ),
      );
    } */
  }

  @override
  Widget build(BuildContext context) {
    final currentContext = context;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprobante Electronico'),
        actions: [
          //notaCredito!.isNotEmpty
          notaCredito != null
              ? notaCredito?.length != 0
                  ? IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PdfPreviewNotaPage(
                              url: notaCredito![0].pdf!,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.document_scanner,
                        color: Colors.red,
                      ),
                    )
                  : IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Anular Comprobante'),
                            content: const Text(
                                '¿Esta seguro que desea anular el comprobante?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  createNotaCredito(currentContext);
                                  // Navigator.pop(context);
                                },
                                child: const Text('Aceptar'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.do_not_touch_rounded,
                        color: Colors.red,
                      ),
                    )
              : const SizedBox(),
        ],
      ),
      body: PdfPreview(
        pdfFileName: url,
        initialPageFormat: PdfPageFormat.a4,
        pageFormats: const <String, PdfPageFormat>{
          'A4': PdfPageFormat.a4,
        },
        canChangeOrientation: false,
        //build: (context) => nuevoProvider.createFacturaPdf(url),
        build: (_) => context.read<LoansRepository>().createInvoicePdf(
              url: url,
            ),
        canDebug: false,
      ),
    );
  }
}

class PdfPreviewNotaPage extends StatelessWidget {
  final String url;
  const PdfPreviewNotaPage({
    Key? key,
    required this.url,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nota de Credito'),
      ),
      body: PdfPreview(
        pdfFileName: url,
        initialPageFormat: PdfPageFormat.a4,
        pageFormats: const <String, PdfPageFormat>{
          'A4': PdfPageFormat.a4,
        },
        canChangeOrientation: false,
        //build: (context) => nuevoProvider.createFacturaPdf(url)
        build: (_) => context.read<LoansRepository>().createInvoicePdf(
              url: url,
            ),
        canDebug: false,
      ),
    );
  }
}

class PdfPreviewScreenShotPage extends StatelessWidget {
  final Uint8List cabecera;
  final Uint8List body;
  const PdfPreviewScreenShotPage({
    Key? key,
    required this.cabecera,
    required this.body,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Comprobante Electronico'),
      ),
      body: PdfPreview(
        pdfFileName: 'ScreenShot.pdf',
        initialPageFormat: PdfPageFormat.a4,
        pageFormats: const <String, PdfPageFormat>{
          'A4': PdfPageFormat.a4,
        },
        canChangeOrientation: false,
        build: (context) =>
            GenerateDocumentPdf.generarDocumento(cabecera, body),
        canDebug: false,
      ),
    );
  }
}
