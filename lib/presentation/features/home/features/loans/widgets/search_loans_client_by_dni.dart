import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchLoansClientByDNI extends StatefulWidget {
  const SearchLoansClientByDNI({super.key});

  @override
  State<SearchLoansClientByDNI> createState() => _SearchLoansClientByDNIState();
}

class _SearchLoansClientByDNIState extends State<SearchLoansClientByDNI> {
  final dniCtrl = TextEditingController();
  bool dniIsValid = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppTextFormField(
            controller: dniCtrl,
            labelText: 'Ingresar DNI del cliente',
            maxLength: 8,
            keyboardType: TextInputType.number,
            isValid: (value) => setState(() => dniIsValid = value),
            validator: (value) {
              if (value!.isEmpty) return 'Campo requerido';
              if (value.length < 8) return 'Ingrese 8 digitos';
              return null;
            },
            suffixIcon: dniCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      dniCtrl.clear();
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
            onPressed: dniIsValid
                ? () {
                    context.read<LoansBloc>().add(
                          GetLoansByDni(
                            value: dniCtrl.text,
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
