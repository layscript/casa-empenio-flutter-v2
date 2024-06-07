import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/payment/payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentsReportsView extends StatefulWidget {
  const PaymentsReportsView({super.key});

  @override
  State<PaymentsReportsView> createState() => _PaymentsReportsViewState();
}

class _PaymentsReportsViewState extends State<PaymentsReportsView> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(
          const GetLoadInitialDataPayments(
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
              PaymentReportsHeaderView(
                height: constraints.maxHeight * 0.08,
                state: state,
                reportsBloc: reportsBloc,
              ),
              PaymentsReportsBodyView(
                constraints: constraints,
                state: state,
              ),
              PaymentsReportsBottomView(
                height: constraints.maxHeight * 0.08,
                state: state,
              )
            ],
          ),
        );
      },
    );
  }
}
