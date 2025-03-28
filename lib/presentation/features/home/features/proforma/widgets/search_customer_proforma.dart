import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/proforma/bloc/proforma_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchCustomerProforma extends StatefulWidget {
  const SearchCustomerProforma({super.key});

  @override
  State<SearchCustomerProforma> createState() => _SearchCustomerProformaState();
}

class _SearchCustomerProformaState extends State<SearchCustomerProforma> {
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
            labelText: 'Ingresar DNI/RUC del cliente',
            maxLength: 11,
            keyboardType: TextInputType.number,
            isValid: (value) => setState(() => dniIsValid = value),
            validator: (value) {
              if (value!.isEmpty) return 'Campo requerido';
              if (value.length != 8 && value.length != 11) {
                return 'Debe ser DNI (8 dígitos) o RUC (11 dígitos)';
              }
              return null;
            },
            suffixIcon: dniCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      dniCtrl.clear();
                      context.read<ProformaBloc>().add(GetProformasInitial());
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
                    final documento = dniCtrl.text;
                    if (documento.length == 8 || documento.length == 11) {
                      context.read<ProformaBloc>().add(
                            GetCustomerProformasByDni(
                              documento,
                            ),
                          );
                    }
                  }
                : null,
            child: const Text('Buscar'),
          ),
        ),
      ],
    );
  }
}
