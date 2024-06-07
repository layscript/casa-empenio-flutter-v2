import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/reports_detail_view.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/reports/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

part 'widgets/list_pagos.dart';
part 'widgets/list_prestamos_cerrados.dart';

class PaymentsReportsBodyView extends StatelessWidget {
  const PaymentsReportsBodyView({
    super.key,
    required this.constraints,
    required this.state,
  });
  final BoxConstraints constraints;
  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ListPrestamosCerrados(
          state: state,
          constraints: constraints,
        ),
        _ListPagos(
          constraints: constraints,
          state: state,
        ),
      ],
    );
  }
}
