import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentReportsHeaderView extends StatelessWidget {
  const PaymentReportsHeaderView({
    super.key,
    required this.height,
    required this.state,
    required this.reportsBloc,
  });

  final double? height;
  final ReportsState state;
  final ReportsBloc reportsBloc;

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.yellow,
      width: double.infinity,
      //height: constraints.maxHeight * 0.08,
      height: height,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: LeadingDownloadButtonPaymentsReports(
          listClosedLoans: state.listClosedLoans,
          listPayments: state.listPayments,
        ),
        title: FittedBox(
          child: Text(
            'Desde: ${DateFormat('dd/MM/yyyy').format(state.startTimePayments)} Hasta: ${DateFormat('dd/MM/yyyy').format(state.endTimePayments)}',
          ),
        ),
        trailing: IconButton(
          constraints: const BoxConstraints(),
          onPressed: () async {
            final result = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2022, 1, 1),
              lastDate: DateTime(2030, 12, 31),
              currentDate: DateTime.now(),
              saveText: 'Done',
            );

            if (result != null) {
              reportsBloc.add(
                GetLoadInitialDataPayments(
                  start: result.start,
                  end: result.end,
                ),
              );
            }
          },
          icon: const Icon(Icons.calendar_today),
        ),
      ),
    );
  }
}
