import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  const DeleteDialog({
    super.key,
    required this.title,
    required this.onPressed,
  });
  final String title;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text('Eliminar $title'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('¿Estas Seguro de Eliminar?'),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onPressed!();
          },
          icon: const Icon(Icons.delete),
          label: const Text('Si'),
        ),
        const SizedBox(height: 15),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close,
            color: AppColors.red,
          ),
          label: const Text(
            'No',
            style: TextStyle(
              color: AppColors.red,
            ),
          ),
        ),
      ],
    );
  }
}
