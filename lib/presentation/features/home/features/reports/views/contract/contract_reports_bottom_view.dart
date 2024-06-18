import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';

class BottomContract extends StatelessWidget {
  const BottomContract({
    super.key,
    required this.height,
    required this.state,
  });
  final double? height;
  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.red,
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aumentos Totales:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('S/. ${oCcy.format(state.totalIncreases)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ganancias Real:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('S/. ${oCcy.format(state.realBenefit)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ganancias Teórica:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('S/. ${oCcy.format(state.theoreticalProfit)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prestamos Totales:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'S/. ${oCcy.format(state.totalLoans)}',
              ),
            ],
          )
        ],
      ),
    );
  }
}
