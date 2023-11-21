import 'package:casa_empenio_pe/presentation/app/utils/keyboard.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/views/loans_step_one_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/views/loans_step_three_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/views/loans_step_two_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepView extends StatelessWidget {
  const LoansStepView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => LoansStepBloc(),
      child: Builder(
        builder: (context) {
          final state = context.watch<LoansStepBloc>().state;
          return GestureDetector(
            onTap: () => Keyboard.unfocus(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ).copyWith(top: 30),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    AppStepper(
                      selectedIndex: state.index,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        state.titleIndexLoans(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    BlocBuilder<LoansStepBloc, LoansStepState>(
                      builder: (context, state) {
                        switch (state.index) {
                          case 0:
                            return const LoansStepOneView();

                          case 1:
                            return const LoansStepTwoView();

                          case 2:
                            return const LoansStepThreeView();
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
