import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/config/config.dart';
import 'package:casa_empenio_pe_dev/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddInterestsDialog extends StatefulWidget {
  const AddInterestsDialog({super.key});

  @override
  State<AddInterestsDialog> createState() => _AddInterestsDialogState();
}

class _AddInterestsDialogState extends State<AddInterestsDialog> {
  final interesCtrl = TextEditingController();
  bool interestIsValid = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Agregar Interés'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextFormField(
            keyboardType: TextInputType.number,
            controller: interesCtrl,
            labelText: 'Interés',
            validator: (value) {
              return value!.isEmpty ? invalidEmptyValue : null;
            },
            isValid: (value) => setState(() => interestIsValid = value),
          ),
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: !interestIsValid
              ? null
              : () {
                  Navigator.pop(context);
                  context
                      .read<InterestsBloc>()
                      .add(SaveInterest(data: interesCtrl.text));
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
