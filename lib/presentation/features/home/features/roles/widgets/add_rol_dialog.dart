import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class AddRolDialog extends StatefulWidget {
  const AddRolDialog({super.key});

  @override
  State<AddRolDialog> createState() => _AddRolDialogState();
}

class _AddRolDialogState extends State<AddRolDialog> {
  final nameCtrl = TextEditingController();
  List<ModulosEntity> _selectedModulos = [];
  bool fullNamesIsValid = false;

  @override
  Widget build(BuildContext context) {
    final rolBloc = context.read<RolesBloc>();
    final rolState = rolBloc.state;

    return AlertDialog(
      title: const Text('Agregar Rol'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextFormField(
                controller: nameCtrl,
                labelText: 'Nombre',
                validator: (value) {
                  return value!.isEmpty ? invalidEmptyValue : null;
                },
                isValid: (value) => setState(() => fullNamesIsValid = value),
              ),
              const SizedBox(height: 20),
              MultiSelectDialogField(
                items: rolState.listModules
                    .map((m) => MultiSelectItem<ModulosEntity>(m, m.nombre))
                    .toList(),
                title: const Text("Módulos"),
                selectedColor: AppColors.blue,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  border: Border.all(
                    color: AppColors.secondaryText,
                  ),
                ),
                buttonText: const Text(
                  "Seleccionar Módulos",
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                confirmText: const Text(
                  'Aceptar',
                ),
                cancelText: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                onConfirm: (results) {
                  setState(() {
                    _selectedModulos = results.cast<ModulosEntity>();
                  });
                },
                initialValue: _selectedModulos,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: !fullNamesIsValid || _selectedModulos.isEmpty
              ? null
              : () {
                  rolBloc.add(
                    SaveRol(
                      nombre: nameCtrl.text,
                      modulos: _selectedModulos,
                    ),
                  );
                  Navigator.pop(context);
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
