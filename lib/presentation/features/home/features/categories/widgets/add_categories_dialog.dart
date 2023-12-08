import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddCategoriesDialog extends StatefulWidget {
  const AddCategoriesDialog({super.key});

  @override
  State<AddCategoriesDialog> createState() => _AddCategoriesDialogState();
}

class _AddCategoriesDialogState extends State<AddCategoriesDialog> {
  final descriptionCtrl = TextEditingController();
  bool descriptionIsValid = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Agregar Categoría'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextFormField(
            controller: descriptionCtrl,
            labelText: 'Descripción',
            validator: (value) {
              return value!.isEmpty ? invalidEmptyValue : null;
            },
            isValid: (value) => setState(() => descriptionIsValid = value),
          ),
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: !descriptionIsValid
              ? null
              : () {
                  Navigator.pop(context);
                  context
                      .read<CategoriesBloc>()
                      .add(SaveCategories(data: descriptionCtrl.text));
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
