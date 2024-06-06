import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelStyle,
    required this.labelText,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final String labelText;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
          ),
        ),
        Flexible(
          child: Text(
            labelText,
            style: labelStyle ??
                const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
          ),
        )
      ],
    );
  }
}
