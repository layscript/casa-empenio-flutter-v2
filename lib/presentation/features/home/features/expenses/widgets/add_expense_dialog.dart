import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/features.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/expenses/bloc/expenses_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final montoCtrl = TextEditingController();
  final obsCtrl = TextEditingController();
  bool isValidMonto = false;

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>().state as Authenticated;

    return AlertDialog(
      scrollable: true,
      title: const Text('Agregar Gasto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextFormField(
            keyboardType: TextInputType.number,
            controller: montoCtrl,
            labelText: 'Monto',
            validator: (value) {
              return value!.isEmpty ? invalidEmptyValue : null;
            },
            isValid: (value) => setState(() => isValidMonto = value),
          ),
          const SizedBox(height: 20),
          AppTextFormField(
            controller: obsCtrl,
            labelText: 'Observaciones',
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: !isValidMonto
              ? null
              : () {
                  context.read<ExpensesBloc>().add(
                        SaveExpense(
                          obs: obsCtrl.text,
                          usuarioId: authBloc.user.id,
                          monto: montoCtrl.text,
                        ),
                      );
                },
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
        const SizedBox(height: 15),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close,
            color: AppColors.red,
          ),
          label: const Text(
            'Salir',
            style: TextStyle(
              color: AppColors.red,
            ),
          ),
        ),
      ],
    );
  }
}
