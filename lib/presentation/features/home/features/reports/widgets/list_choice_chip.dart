import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListChoiceChip extends StatelessWidget {
  const ListChoiceChip({super.key});

  @override
  Widget build(BuildContext context) {
    final reportsBloc = context.watch<ReportsBloc>().state;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            selected: reportsBloc.vigentContracts,
            onSelected: (value) {
              context.read<ReportsBloc>().add(ChangeVigentContracts(value));
              context.read<ReportsBloc>().add(
                    GetLoadInitialDataContracts(
                      start: reportsBloc.startTimeContracts,
                      end: reportsBloc.endTimeContracts,
                    ),
                  );
            },
            selectedColor: Colors.blue[400],
            label: Text(
              'Vigentes',
              style: TextStyle(
                color:
                    reportsBloc.vigentContracts ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 5),
          ChoiceChip(
            selected: reportsBloc.vencidoContracts,
            onSelected: (value) {
              context.read<ReportsBloc>().add(ChangeVencidoContracts(value));
              context.read<ReportsBloc>().add(
                    GetLoadInitialDataContracts(
                      start: reportsBloc.startTimeContracts,
                      end: reportsBloc.endTimeContracts,
                    ),
                  );
            },
            selectedColor: Colors.blue[400],
            label: Text(
              'Vencidos',
              style: TextStyle(
                color:
                    reportsBloc.vencidoContracts ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 5),
          ChoiceChip(
            selected: reportsBloc.pagadoContracts,
            onSelected: (value) {
              context.read<ReportsBloc>().add(ChangePagadoContracts(value));
              context.read<ReportsBloc>().add(
                    GetLoadInitialDataContracts(
                      start: reportsBloc.startTimeContracts,
                      end: reportsBloc.endTimeContracts,
                    ),
                  );
            },
            selectedColor: Colors.blue[400],
            label: Text(
              'Pagados',
              style: TextStyle(
                color:
                    reportsBloc.pagadoContracts ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 5),
          ChoiceChip(
            selected: reportsBloc.ventaContracts,
            onSelected: (value) {
              context.read<ReportsBloc>().add(ChangeVentaContracts(value));
              context.read<ReportsBloc>().add(
                    GetLoadInitialDataContracts(
                      start: reportsBloc.startTimeContracts,
                      end: reportsBloc.endTimeContracts,
                    ),
                  );
            },
            selectedColor: Colors.blue[400],
            label: Text(
              'Ventas',
              style: TextStyle(
                color: reportsBloc.ventaContracts ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 5),
          ChoiceChip(
            selected: reportsBloc.liquidadoContracts,
            onSelected: (value) {
              context.read<ReportsBloc>().add(ChangeLiquidadoContracts(value));
              context.read<ReportsBloc>().add(
                    GetLoadInitialDataContracts(
                      start: reportsBloc.startTimeContracts,
                      end: reportsBloc.endTimeContracts,
                    ),
                  );
            },
            selectedColor: Colors.blue[400],
            label: Text(
              'Liquidados',
              style: TextStyle(
                color: reportsBloc.liquidadoContracts
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 5),
          ChoiceChip(
            selected: reportsBloc.canceladoContracts,
            onSelected: (value) {
              context.read<ReportsBloc>().add(ChangeCanceladoContracts(value));
              context.read<ReportsBloc>().add(
                    GetLoadInitialDataContracts(
                      start: reportsBloc.startTimeContracts,
                      end: reportsBloc.endTimeContracts,
                    ),
                  );
            },
            selectedColor: Colors.blue[400],
            label: Text(
              'Cancelados',
              style: TextStyle(
                color: reportsBloc.canceladoContracts
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}
