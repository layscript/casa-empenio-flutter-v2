import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/contract/contract_reports_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/deudas/deudas_reports_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/payment/payments_reports_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/resumen_reports_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final pageCtrl = PageController();
  int selectedIndex = 0;

  static const _titulos = [
    '📊 Resumen',
    'Reportes de Pago',
    'Reportes de Contratos',
    'Reportes de Deudas',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportsBloc(
        reportsRepository: context.read(),
        loansRepository: context.read(),
        categoriesRepository: context.read(),
        expensesRepository: context.read(),
        preferences: context.read(),
        cajaRepository: context.read(),
      )..add(const GetCategoriesEvent()),
      child: Builder(builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 38,
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _titulos.length; i++) ...[
                      TabsReports(
                        onTap: () {
                          setState(() {
                            selectedIndex = i;
                          });
                          pageCtrl.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.ease,
                          );
                        },
                        isSelected: selectedIndex == i,
                        text: _titulos[i],
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: PageView.builder(
                  controller: pageCtrl,
                  onPageChanged: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return const ResumenReportsView();
                      case 1:
                        return const PaymentsReportsView();
                      case 2:
                        return const ContractReportsView();
                      case 3:
                        return const DeudasReportsView();
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
