import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/contract/contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContractReportsView extends StatefulWidget {
  const ContractReportsView({super.key});

  @override
  State<ContractReportsView> createState() => _ContractReportsViewState();
}

class _ContractReportsViewState extends State<ContractReportsView> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(
          const GetLoadInitialDataContracts(
            end: null,
            start: null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final reportsBloc = context.watch<ReportsBloc>();
    final state = reportsBloc.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          //color: Colors.red,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            children: [
              ContractReportsHeaderView(
                height: constraints.maxHeight * 0.15,
                state: state,
                reportsBloc: reportsBloc,
              ),
              ContractReportsBodyView(
                constraints: constraints,
                reportsBloc: reportsBloc,
                state: state,
              ),
              BottomContract(
                height: constraints.maxHeight * 0.15,
                state: state,
              ),
            ],
          ),
        );
      },
    );
  }
}
