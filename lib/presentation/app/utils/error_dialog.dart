import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/buttons/buttons.dart';
import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    Key? key,
    required this.message,
    this.iconSuccess,
  }) : super(key: key);
  final String message;
  final String? iconSuccess;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error,
            color: AppColors.red,
            size: 50,
          ),
          const SizedBox(height: 10),
          Text(message),
          const SizedBox(height: 15),
          SecondaryButton(
            onPressed: () {
              Navigator.pop(context);
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
  }) {
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return ErrorDialog(message: message);
      },
    );
  }
}
