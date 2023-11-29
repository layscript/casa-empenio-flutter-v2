import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepThreeView extends StatelessWidget {
  const LoansStepThreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoansStepBloc, LoansStepState>(
      builder: (context, loansState) {
        if (loansState.listWarranty != null && !loansState.addListWarranty) {
          return ShowListWarranty(loansState: loansState);
        } else {
          if (loansState.idWarranty == null) {
            return const AddFormWarranty();
          } else {
            return const EditFormWarranty();
          }
        }
      },
    );
  }
}
