import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/views/loans_step_one_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/views/loans_step_three_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/views/loans_step_two_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansStepView extends StatelessWidget {
  const LoansStepView({super.key});

  static const route = 'loans-step';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        centerTitle: true,
        title: const Text('Registrar Préstamo'),
      ),
      body: BlocProvider(
        lazy: false,
        create: (context) => LoansStepBloc(
          loansRepository: context.read(),
          interestsRepository: context.read(),
        )..add(GetLastCodeLoans()),
        child: Builder(
          builder: (context) {
            return BlocConsumer<LoansStepBloc, LoansStepState>(
              listener: (context, state) {
                if (state.isLoansStepLoading) {
                  OverlayLoader.show(context);
                } else {
                  OverlayLoader.hide();
                  if (state.isLoansStepError) {
                    ErrorSnackbar.show(context, state.message ?? '');
                  }
                }
              },
              builder: (context, state) {
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
            );
          },
        ),
      ),
    );
  }
}
