import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/bloc/sales_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchCustomerSales extends StatefulWidget {
  const SearchCustomerSales({super.key});

  @override
  State<SearchCustomerSales> createState() => _SearchCustomerSalesState();
}

class _SearchCustomerSalesState extends State<SearchCustomerSales> {
  final dniCtrl = TextEditingController();
  bool dniIsValid = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
                  return null;
                },
                suffixIcon: dniCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          dniCtrl.clear();
                          context.read<SalesBloc>().add(GetSalesInitial());
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
                        context.read<SalesBloc>().add(
                              GetCustomerSalesByDni(
                                dniCtrl.text,
                              ),
                            );
                      }
                    : null,
                child: const Text('Buscar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            context.read<SalesBloc>().add(const UseGenericCustomer());
          },
          icon: const Icon(Icons.person_add, color: AppColors.blue),
          label: const Text('Usar Cliente Genérico'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 45),
          ),
        ),
      ],
    );
  }
}
