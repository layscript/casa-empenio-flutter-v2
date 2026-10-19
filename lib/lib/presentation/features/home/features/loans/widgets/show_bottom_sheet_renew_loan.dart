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
            '¿Qué deseas hacer con los datos de este préstamo?',
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
            child: const Text('🆕 Crear nuevo (el cliente vuelve a dejar su prenda)'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Copia los datos como un préstamo independiente.',
              style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                true,
              );
            },
            child: const Text('🔁 Renovar (continúa el préstamo anterior)'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'El sistema enlaza el nuevo préstamo con el anterior y cuenta '
              'las renovaciones (N° 1, 2, 3...).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
