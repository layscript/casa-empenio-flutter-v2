import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class TabsReports extends StatelessWidget {
  const TabsReports({
    super.key,
    required this.onTap,
    required this.isSelected,
    required this.text,
  });
  final void Function()? onTap;
  final bool isSelected;
  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected ? AppColors.blue : AppColors.blue.withOpacity(0.5),
        ),
        child: FittedBox(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
