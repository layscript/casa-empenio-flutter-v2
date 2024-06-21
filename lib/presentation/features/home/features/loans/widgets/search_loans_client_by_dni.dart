import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:flutter/material.dart';

class SearchLoansClientByDNI extends StatefulWidget {
  const SearchLoansClientByDNI({
    super.key,
    required this.onPressed,
  });
  final void Function(String)? onPressed;

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
                    /* context.read<LoansBloc>().add(
                          GetLoansByDni(
                            value: dniCtrl.text,
                          ),
                        ); */
                    widget.onPressed!(dniCtrl.text);
                  }
                : null,
            child: const Text('Buscar'),
          ),
        ),
      ],
    );
  }
}
