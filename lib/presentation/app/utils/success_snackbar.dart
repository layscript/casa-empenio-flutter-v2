import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class SuccessSnackbar extends StatelessWidget {
  const SuccessSnackbar({
    Key? key,
    required this.message,
    this.iconSuccess,
  }) : super(key: key);
  final String message;
  final String? iconSuccess;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2).copyWith(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.done,
            color: Colors.white,
          ),
          const SizedBox(width: 17),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.white,
              ),
            ),
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
    final snackbar = SnackBar(
      content: SuccessSnackbar(message: message, iconSuccess: icon),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }
}
