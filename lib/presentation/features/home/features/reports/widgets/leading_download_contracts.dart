import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class LeadingDownloadButtonPaymentsContracts extends StatefulWidget {
  const LeadingDownloadButtonPaymentsContracts({
    super.key,
    required this.listIncrease,
    required this.listLoans,
  });
  final List<ReportsContractsEntity> listIncrease;
  final List<LoansEntity> listLoans;

  @override
  State<LeadingDownloadButtonPaymentsContracts> createState() =>
      _LeadingDownloadButtonPaymentsContractsState();
}

class _LeadingDownloadButtonPaymentsContractsState
    extends State<LeadingDownloadButtonPaymentsContracts> {
  void downloadIncreases() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Reporte');
    excel.insertRowIterables(
      'Reporte',
      [
        'Nro',
        'Fecha',
        'Monto',
        'Observaciones',
        'Codigo Prestamo',
        'Monto Prestamo',
        'Ganancia Prestamo',
        'Estado Prestamo'
      ],
      0,
    );
    final increases = widget.listIncrease;
    for (var i = 0; i < increases.length; i++) {
      excel.insertRowIterables(
        'Reporte',
        [
          i + 1,
          DateFormat('dd/MM/yyyy').format(
            DateTime.parse(increases[i].fecha ?? ''),
          ),
          double.parse(increases[i].monto ?? '0.00'),
          increases[i].observaciones ?? '',
          increases[i].prestamo?.codigo ?? '',
          increases[i].prestamo?.monto ?? '',
          increases[i].prestamo?.ganancia ?? '',
          increases[i].prestamo?.estado ?? '',
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

  void downloadLoans() async {
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
    final loans = widget.listLoans;
    for (var i = 0; i < loans.length; i++) {
      excel.insertRowIterables(
        'Reporte',
        [
          i + 1,
          loans[i].cliente?.dni ?? '',
          '${loans[i].cliente?.nombres ?? ''} ${loans[i].cliente?.apellidos ?? ''}',
          DateFormat('dd/MM/yyyy').format(
            DateTime.parse(loans[i].fecha ?? ''),
          ),
          DateFormat('dd/MM/yyyy').format(
            DateTime.parse(loans[i].fechaPago ?? ''),
          ),
          double.parse(loans[i].monto ?? '0.00'),
          double.parse(loans[i].ganancia ?? '0.00'),
          loans[i].estado,
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
            title: Text('Aumentos (${widget.listIncrease.length})'),
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
            title: Text('Prestamos (${widget.listLoans.length})'),
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'one_value':
            downloadIncreases();
            break;
          case 'two_value':
            downloadLoans();
            break;
        }
      },
    );
  }
}
