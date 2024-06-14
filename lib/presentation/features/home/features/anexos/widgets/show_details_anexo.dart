import 'package:casa_empenio_pe/domain/anexo/anexo_entity.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/views/open_caja_view.dart';
import 'package:flutter/material.dart';

class ShowDetailsAnexo extends StatelessWidget {
  const ShowDetailsAnexo._({
    required this.anexo,
  });
  final AnexoEntity anexo;
  static void show(
    BuildContext context, {
    required AnexoEntity anexo,
  }) {
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return ShowDetailsAnexo._(
          anexo: anexo,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Visita: ${anexo.id}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Salir',
          ),
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomRow(
            label: 'Descripción',
            value: anexo.descripcion,
          ),
          CustomRow(
            label: 'Tipo',
            value: anexo.tipo,
          ),
          CustomRow(
            label: 'Fecha',
            value: setDateTimeToLocal(anexo.createdAt),
          ),
          CustomRow(
            label: 'Préstamo',
            value: anexo.prestamo?.codigo.toString() ?? '',
          ),
          CustomRow(
            label: 'Monto',
            value:
                'S/.${oCcy.format(double.parse(anexo.prestamo?.monto ?? '0.00'))}',
          ),
          CustomRow(
            label: 'Observaciones',
            value: anexo.prestamo?.observaciones ?? '',
          ),
          const CustomRow(
            label: 'Imagen Anexo',
            value: '',
          ),
          const SizedBox(height: 10),
          CustomImageApp(
            urlImg: anexo.url,
            width: 100,
            height: 100,
          ),
        ],
      ),
    );
  }
}
