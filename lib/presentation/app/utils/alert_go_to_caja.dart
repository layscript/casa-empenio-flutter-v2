import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class AlertGoToCaja extends StatelessWidget {
  const AlertGoToCaja({super.key, required this.onPressed});
  final void Function()? onPressed;

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
              /* onPressed: () {
                context.read<HomeBloc>().add(GoToCajas());
                Navigator.pop(context);
              }, */
              onPressed: onPressed,
              child: const Text('Ir a caja'),
            ),
          ],
        ),
      ),
    );
  }
}
