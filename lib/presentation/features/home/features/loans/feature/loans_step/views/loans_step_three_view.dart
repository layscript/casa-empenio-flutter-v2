import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/feature/loans_step/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepThreeView extends StatelessWidget {
  const LoansStepThreeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoansStepBloc, LoansStepState>(
      builder: (context, loansState) {
        final preferences = context.read<Preferences>();
        final stateLocalWarranty =
            preferences.getLoansPreferences?.warrantyPreferences;

        if (!loansState.addListWarranty && stateLocalWarranty != null) {
          return ShowListWarranty(
            listWarranty: stateLocalWarranty,
          );
        } else {
          if (loansState.idWarranty == null) {
            return const AddFormWarranty();
          } else {
            return EditFormWarranty(loansState: loansState);
          }
        }
      },
    );
  }
}
