import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/bloc/reports_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/contract_reports_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/views/payments_reports_view.dart';
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: selectedIndex == 0
                            ? AppColors.blue
                            : AppColors.blue.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: FittedBox(
                        child: Text(
                          'Reportes de Pago',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: selectedIndex == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
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
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: selectedIndex == 1
                            ? AppColors.blue
                            : AppColors.blue.withOpacity(0.5),
                      ),
                      child: FittedBox(
                        child: Text(
                          'Reportes de Contratos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: selectedIndex == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return const PaymentsReportsView();
                      case 1:
                        return const ContractReportsView();
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
