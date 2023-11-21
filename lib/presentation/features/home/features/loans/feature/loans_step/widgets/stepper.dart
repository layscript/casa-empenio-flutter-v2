import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

class AppStepper extends StatelessWidget {
  const AppStepper({
    Key? key,
    required this.selectedIndex,
    this.padding,
  }) : super(key: key);

  final int selectedIndex;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 28),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 15, left: 30, right: 30),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Divider(
                      color: selectedIndex >= 0
                          ? AppColors.blue
                          : AppColors.disabledButton,
                      height: 3,
                      thickness: 3,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Divider(
                      color: selectedIndex > 0
                          ? AppColors.blue
                          : AppColors.disabledButton,
                      height: 3,
                      thickness: 3,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Divider(
                      color: selectedIndex > 0
                          ? AppColors.blue
                          : AppColors.disabledButton,
                      height: 3,
                      thickness: 3,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Divider(
                      color: selectedIndex > 1
                          ? AppColors.blue
                          : AppColors.disabledButton,
                      height: 3,
                      thickness: 3,
                    ),
                  ),
                ],
              ),
            ),
            Opacity(
              opacity: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['CLIENTE', 'PRESTAMO', 'GARANTIA']
                    .asMap()
                    .map(
                      (i, element) {
                        final isSelected = i == selectedIndex;
                        final surpassSelected = i < selectedIndex;
                        return MapEntry(
                          i,
                          SizedBox(
                            width: 90,
                            child: Column(
                              crossAxisAlignment: i == 0
                                  ? CrossAxisAlignment.start
                                  : i == 1
                                      ? CrossAxisAlignment.center
                                      : CrossAxisAlignment.end,
                              children: [
                                Center(
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      // border: Border.all(
                                      //   color: isSelected
                                      //       ? Colors.transparent
                                      //       : AppColors.disabledButton,
                                      // ),
                                      color: isSelected || surpassSelected
                                          ? AppColors.blue
                                          : AppColors.disabledButton,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        surpassSelected ? '✓' : '${i + 1}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : surpassSelected
                                                  ? Colors.white
                                                  : Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                    .values
                    .toList(),
              ),
            ),
          ],
        ));
  }
}
