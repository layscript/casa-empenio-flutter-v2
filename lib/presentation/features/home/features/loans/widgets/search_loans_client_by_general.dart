import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchLoansClientByGeneral extends StatefulWidget {
  const SearchLoansClientByGeneral({super.key});

  @override
  State<SearchLoansClientByGeneral> createState() =>
      _SearchLoansClientByGeneralState();
}

class _SearchLoansClientByGeneralState
    extends State<SearchLoansClientByGeneral> {
  final textCtrl = TextEditingController();
  bool textIsValid = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppTextFormField(
            controller: textCtrl,
            labelText: 'Ingresar texto',
            isValid: (value) => setState(() => textIsValid = value),
            validator: (value) {
              if (value!.isEmpty) return 'Campo requerido';
              return null;
            },
            suffixIcon: textCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      textCtrl.clear();
                      context.read<LoansBloc>().add(GetLoansInitial());
                    },
                    child: const Icon(
                      Icons.clear,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: textIsValid
                ? () {
                    context.read<LoansBloc>().add(
                          GetLoansByText(
                            value: textCtrl.text,
                          ),
                        );
                  }
                : null,
            child: const Text('Buscar'),
          ),
        ),
      ],
    );
  }
}
