import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class AlertGoToCaja extends StatelessWidget {
  const AlertGoToCaja({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text('Alerta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para continuar con el registro necesita abrir caja',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ir a caja'),
            ),
          ],
        ),
      ),
    );
  }
}
