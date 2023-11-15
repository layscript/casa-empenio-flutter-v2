import 'package:flutter/material.dart';

class ErrorSnackbar extends StatelessWidget {
  const ErrorSnackbar({
    Key? key,
    required this.error,
    this.iconError,
  }) : super(key: key);
  final String error;
  final String? iconError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2).copyWith(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.error,
            color: Colors.white,
          ),
          const SizedBox(width: 17),
          Flexible(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context,
    String error, {
    String? icon,
    Color? color = Colors.red,
  }) {
    final snackbar = SnackBar(
      content: ErrorSnackbar(error: error, iconError: icon),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackbar);
  }
}
