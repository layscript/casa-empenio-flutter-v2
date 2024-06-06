import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe_dev/presentation/app/config/config.dart';
import 'package:casa_empenio_pe_dev/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditCategoriesDialog extends StatefulWidget {
  const EditCategoriesDialog({
    super.key,
    required this.categories,
  });
  final CategoriesEntity categories;

  @override
  State<EditCategoriesDialog> createState() => _EditCategoriesDialogState();
}

class _EditCategoriesDialogState extends State<EditCategoriesDialog> {
  final descriptionCtrl = TextEditingController();
  bool descriptionIsValid = false;

  @override
  void initState() {
    super.initState();
    descriptionCtrl.text = widget.categories.descripcion;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Editar Categoría'),
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
                  context.read<CategoriesBloc>().add(UpdateCategories(
                        id: widget.categories.id,
                        data: descriptionCtrl.text,
                      ));
                },
          icon: const Icon(Icons.save),
          label: const Text('Actualizar'),
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
