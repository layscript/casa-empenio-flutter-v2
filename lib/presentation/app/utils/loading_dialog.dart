import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({
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
          const CircularProgressIndicator(),
          const SizedBox(height: 10),
          Text(message),
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
        return LoadingDialog(message: message);
      },
    );
  }
}
