import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/widgets/buttons/buttons.dart';
import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({
    Key? key,
    required this.message,
    this.onPressed,
    this.iconSuccess,
  }) : super(key: key);
  final String message;
  final String? iconSuccess;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.green,
            size: 50,
          ),
          const SizedBox(height: 10),
          Text(message),
          const SizedBox(height: 15),
          SecondaryButton(
            onPressed: () {
              onPressed?.call();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context,
    String message, {
    String? icon,
    Color? color = AppColors.green,
    VoidCallback? onPressed,
  }) {
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return SuccessDialog(
          message: message,
          onPressed: onPressed,
        );
      },
    );
  }
}
