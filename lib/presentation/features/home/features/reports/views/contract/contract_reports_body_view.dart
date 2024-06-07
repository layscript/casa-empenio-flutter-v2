import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/reports_detail_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

part 'widgets/list_categories.dart';
part 'widgets/list_aumentos.dart';
part 'widgets/list_prestamos.dart';

class ContractReportsBodyView extends StatelessWidget {
  const ContractReportsBodyView({
    super.key,
    required this.constraints,
    required this.reportsBloc,
    required this.state,
  });
  final BoxConstraints constraints;
  final ReportsBloc reportsBloc;
  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.purple,
      width: double.infinity,
      height: constraints.maxHeight * 0.70,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ListCategories(
              constraints: constraints,
              state: state,
              reportsBloc: reportsBloc,
            ),
            _ListAumentos(
              constraints: constraints,
              state: state,
              reportsBloc: reportsBloc,
            ),
            _ListPrestamos(
              constraints: constraints,
              state: state,
              reportsBloc: reportsBloc,
            ),
          ],
        ),
      ),
    );
  }
}
