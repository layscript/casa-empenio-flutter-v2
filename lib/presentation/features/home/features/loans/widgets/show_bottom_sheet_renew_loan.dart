import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class ShowBottomSheetRenewLoan extends StatelessWidget {
  const ShowBottomSheetRenewLoan._();

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool?>(
      isDismissible: false,
      isScrollControlled: false,
      context: context,
      builder: (context) => const ShowBottomSheetRenewLoan._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Seleccione la opción que desee realizar con la información del préstamo:',
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                false,
              );
            },
            child: const Text('Crear Nuevo'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                true,
              );
            },
            child: const Text('Renovar'),
          ),
        ],
      ),
    );
  }
}
