import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:flutter/material.dart';

class PaymentsReportsBottomView extends StatelessWidget {
  const PaymentsReportsBottomView({
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          /* Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Utilidades de Pagos Parciales',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('S/. ${oCcy.format(state.partialUtilityPayment)}')
            ],
          ), */
          /* Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Utilidades de Pagos Completos',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'S/. ${oCcy.format(state.fullPaymentUtility)}',
              )
            ],
          ), */
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pagos Totales ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('S/. ${oCcy.format(state.totalPayments)}')
            ],
          ),
        ],
      ),
    );
  }
}
