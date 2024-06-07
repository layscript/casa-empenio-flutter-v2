import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ContractReportsHeaderView extends StatelessWidget {
  const ContractReportsHeaderView({
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
      height: height,
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: LeadingDownloadButtonPaymentsContracts(
              listIncrease: state.listIncrease,
              listLoans: state.listLoans,
            ),
            title: FittedBox(
              child: Text(
                'Desde: ${DateFormat('dd/MM/yyyy').format(state.startTimeContracts)} Hasta: ${DateFormat('dd/MM/yyyy').format(state.endTimeContracts)}',
              ),
            ),
            trailing: IconButton(
              constraints: const BoxConstraints(),
              onPressed: () async {
                final result = await showDateRangePicker(
                  locale: const Locale('es'),
                  context: context,
                  firstDate: DateTime(2022, 1, 1),
                  lastDate: DateTime(2030, 12, 31),
                  currentDate: DateTime.now(),
                  saveText: 'Done',
                );

                if (result != null) {
                  reportsBloc.add(
                    GetLoadInitialDataContracts(
                      start: result.start,
                      end: result.end,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.calendar_today),
            ),
          ),
          const Expanded(
            child: ListChoiceChip(),
          ),
        ],
      ),
    );
  }
}
