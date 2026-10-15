import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/utils/expediente_page.dart';
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
    final preferences = context.read<Preferences>();
    return BlocProvider(
      lazy: false,
      create: (context) => LoansStepBloc(
        loansRepository: context.read(),
        interestsRepository: context.read(),
        preferences: context.read(),
        categoriesRepository: context.read(),
        cajaRepository: context.read(),
        customerRepository: context.read(),
      )..add(GetLastCodeLoans()),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.blue,
            centerTitle: true,
            title: const Text('Registrar Préstamo'),
            leading: IconButton(
              onPressed: () {
                context.read<LoansStepBloc>().add(const SaveTempDataLoans());
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_outlined),
            ),
            actions: [
              if (preferences.getLoansPreferences != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('¿Estás seguro de eliminar?'),
                          content: const Text(
                            'Se eliminarán todos los datos almacenados del préstamo',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: AppColors.primaryText,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                preferences.removeLoansPreferences();
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                )
            ],
          ),
          body: BlocConsumer<LoansStepBloc, LoansStepState>(
            listener: (context, state) {
              if (state.isLoansStepStatusSavedLoading) {
                /* OverlayLoader.show(context); */
                LoadingDialog.show(context, 'Guardando...');
              } else {
                /* OverlayLoader.hide(); */

                if (state.isLoansStepStatusSavedError) {
                  Navigator.pop(context, null);
                  ErrorDialog.show(
                    context,
                    state.message ?? 'Ocurrió un error, intentelo de nuevo.',
                  );
                }
                if (state.isLoansStepStatusSavedSuccess) {
                  Navigator.pop(context);
                  SuccessDialog.show(
                    context,
                    'Guardado correctamente',
                    onPressed: () async {
                      preferences.removeLoansPreferences();
                      final codigo = int.tryParse(state.codeLoans ?? '') ?? 0;
                      Navigator.pop(context);
                      if (codigo > 0) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpedientePage(
                              prestamoCodigo: codigo,
                              autoFlujo: true,
                            ),
                          ),
                        );
                      }
                      if (context.mounted) {
                        Navigator.pop(context, state.documentClient);
                      }
                    },
                  );
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
          ),
        );
      }),
    );
  }
}
