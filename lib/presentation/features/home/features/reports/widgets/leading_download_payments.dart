import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class LeadingDownloadButtonPaymentsReports extends StatefulWidget {
  const LeadingDownloadButtonPaymentsReports({
    super.key,
    required this.listClosedLoans,
    required this.listPayments,
  });
  final List<LoansEntity> listClosedLoans;
  final List<ReportsPaymentEntity> listPayments;

  @override
  State<LeadingDownloadButtonPaymentsReports> createState() =>
      _LeadingDownloadButtonPaymentsReportsState();
}

class _LeadingDownloadButtonPaymentsReportsState
    extends State<LeadingDownloadButtonPaymentsReports> {
  void downloadClosedLoans() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Reporte');
    excel.insertRowIterables(
      'Reporte',
      [
        'Nro',
        'DNI',
        'Cliente',
        'Fecha Prestamo',
        'Fecha Recojo',
        'Monto Prestado',
        'Ganancia',
        'Estado'
      ],
      0,
    );
    final prestamosCerrados = widget.listClosedLoans;
    for (var i = 0; i < prestamosCerrados.length; i++) {
      excel.insertRowIterables(
        'Reporte',
        [
          i + 1,
          prestamosCerrados[i].cliente?.dni,
          '${prestamosCerrados[i].cliente?.nombres} ${prestamosCerrados[i].cliente?.apellidos}',
          DateFormat('dd/MM/yyyy').format(
            DateTime.parse(prestamosCerrados[i].fecha ?? ''),
          ),
          DateFormat('dd/MM/yyyy').format(
            DateTime.parse(prestamosCerrados[i].fechaPago ?? ''),
          ),
          double.parse(prestamosCerrados[i].monto ?? '0.00'),
          double.parse(prestamosCerrados[i].ganancia ?? '0.00'),
          prestamosCerrados[i].estado,
        ],
        i + 1,
      );
    }

    final bytes = excel.save();
    var directory = await getTemporaryDirectory();
    final path = p.join('${directory.path}/reporte.xlsx');
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);

    await OpenFile.open(path);
  }

  void downloadPayments() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Reporte');
    excel.insertRowIterables(
      'Reporte',
      [
        'Nro',
        'DNI',
        'Cliente',
        'Fecha Prestamo',
        'Codigo Prestamo',
        'Ganancia',
        'Estado',
      ],
      0,
    );
    final prestamosCerrados = widget.listPayments;
    for (var i = 0; i < prestamosCerrados.length; i++) {
      excel.insertRowIterables(
        'Reporte',
        [
          i + 1,
          prestamosCerrados[i].prestamo?.cliente?.dni ?? '',
          '${prestamosCerrados[i].prestamo?.cliente?.nombres ?? ''} ${prestamosCerrados[i].prestamo?.cliente?.apellidos ?? ''}',
          DateFormat('dd/MM/yyyy').format(
            DateTime.parse(prestamosCerrados[i].fecha ?? ''),
          ),
          prestamosCerrados[i].prestamo?.codigo ?? '',
          prestamosCerrados[i].prestamo?.ganancia ?? '',
          prestamosCerrados[i].prestamo?.estado ?? '',
        ],
        i + 1,
      );
    }

    final bytes = excel.save();
    var directory = await getTemporaryDirectory();
    final path = p.join('${directory.path}/reporte.xlsx');
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);

    await OpenFile.open(path);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'one_value',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.download,
              color: Colors.green,
            ),
            title:
                Text('Prestamos Cerrados (${widget.listClosedLoans.length})'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'two_value',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.download,
              color: Colors.green,
            ),
            title: Text('Prestamos (${widget.listPayments.length})'),
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'one_value':
            downloadClosedLoans();
            break;
          case 'two_value':
            downloadPayments();
            break;
        }
      },
    );
  }
}
