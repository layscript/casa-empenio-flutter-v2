import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class LeadingDownloadCajas extends StatefulWidget {
  const LeadingDownloadCajas({
    super.key,
    required this.movimientos,
  });

  final List<MovimientosEntity> movimientos;

  @override
  State<LeadingDownloadCajas> createState() => _LeadingDownloadCajasState();
}

class _LeadingDownloadCajasState extends State<LeadingDownloadCajas> {
  void downloadCajas() async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Reporte');
    excel.insertRowIterables(
      'Reporte',
      ['Id', 'Observaciones', 'Monto', 'Tipo', 'Fecha'],
      0,
    );
    final movimientos = widget.movimientos;
    for (var i = 0; i < movimientos.length; i++) {
      excel.insertRowIterables(
        'Reporte',
        [
          i + 1,
          movimientos[i].observaciones,
          double.parse(movimientos[i].monto ?? '0.00'),
          movimientos[i].tipo?.codigo ?? '',
          fechaCortaPeru(movimientos[i].createdAt),
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
            title: Text('Cajas (${widget.movimientos.length})'),
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'one_value':
            downloadCajas();
            break;
        }
      },
    );
  }
}
