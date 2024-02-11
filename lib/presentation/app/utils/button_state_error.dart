import 'package:casa_empenio_pe/presentation/app/widgets/buttons/buttons.dart';
import 'package:flutter/material.dart';

class ButtonStateError extends StatelessWidget {
  const ButtonStateError({
    super.key,
    required this.onPressed,
    this.message,
  });
  final void Function()? onPressed;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? 'Ocurrió un error, vuelva a intentarlo',
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              onPressed: onPressed,
              child: const Text('Cargar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
