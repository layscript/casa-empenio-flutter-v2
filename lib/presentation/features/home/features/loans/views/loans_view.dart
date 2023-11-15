import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoansView extends StatefulWidget {
  const LoansView({super.key});

  @override
  State<LoansView> createState() => _LoansViewState();
}

class _LoansViewState extends State<LoansView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoansBloc(),
      child: Builder(
        builder: (context) {
          final state = context.watch<LoansBloc>().state;

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
                    BlocBuilder<LoansBloc, LoansState>(
                      builder: (context, state) {
                        switch (state.index) {
                          case 0:
                            return const LoansStepOne();

                          case 1:
                            return const LoansStepTwo();

                          case 2:
                            return const LoansStepThree();
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
