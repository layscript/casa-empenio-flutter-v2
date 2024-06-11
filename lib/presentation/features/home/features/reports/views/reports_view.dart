import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/contract/contract_reports_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/deudas/deudas_reports_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/payment/payments_reports_view.dart';
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
                height: 35,
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: [
                    TabsReports(
                      onTap: () {
                        setState(() {
                          selectedIndex = 0;
                        });
                        pageCtrl.animateToPage(
                          0,
                          duration: const Duration(seconds: 1),
                          curve: Curves.ease,
                        );
                      },
                      isSelected: selectedIndex == 0,
                      text: 'Reportes de Pago',
                    ),
                    const SizedBox(width: 10),
                    TabsReports(
                      onTap: () {
                        setState(() {
                          selectedIndex = 1;
                        });
                        pageCtrl.animateToPage(
                          1,
                          duration: const Duration(seconds: 1),
                          curve: Curves.ease,
                        );
                      },
                      isSelected: selectedIndex == 1,
                      text: 'Reportes de Contratos',
                    ),
                    const SizedBox(width: 10),
                    TabsReports(
                      onTap: () {
                        setState(() {
                          selectedIndex = 2;
                        });
                        pageCtrl.animateToPage(
                          2,
                          duration: const Duration(seconds: 1),
                          curve: Curves.ease,
                        );
                      },
                      isSelected: selectedIndex == 2,
                      text: 'Reportes de Deudas',
                    ),
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
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return const PaymentsReportsView();
                      case 1:
                        return const ContractReportsView();
                      case 2:
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
