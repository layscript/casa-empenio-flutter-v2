import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PayloadAnexo {
  const PayloadAnexo({
    required this.prestamoId,
    required this.description,
    required this.imagenes,
  });

  final String prestamoId;
  final String description;
  final List<XFile>? imagenes;
}

class AddAnexoDialog extends StatefulWidget {
  const AddAnexoDialog({
    super.key,
    required this.onPressed,
    this.idPrestamo,
  });
  final void Function(PayloadAnexo)? onPressed;
  final int? idPrestamo;

  @override
  State<AddAnexoDialog> createState() => _AddAnexoDialogState();
}

class _AddAnexoDialogState extends State<AddAnexoDialog> {
  List<XFile>? selectedPhotosAnexos = [];
  final descriptionCtrl = TextEditingController();
  final prestamoCtrl = TextEditingController();

  bool prestamoIsValid = false;
  bool descriptionIsValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.idPrestamo != null) {
      prestamoCtrl.text = widget.idPrestamo.toString();
    }
  }

  void onChangePhotosGastos() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        selectedPhotosAnexos?.add(photo);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Agregar Anexo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextFormField(
            keyboardType: TextInputType.number,
            controller: prestamoCtrl,
            labelText: 'Préstamo',
            validator: (value) {
              return value!.isEmpty ? invalidEmptyValue : null;
            },
            isValid: (value) => setState(() => prestamoIsValid = value),
          ),
          const SizedBox(height: 20),
          AppTextFormField(
            controller: descriptionCtrl,
            labelText: 'Descripción',
            validator: (value) {
              return value!.isEmpty ? invalidEmptyValue : null;
            },
            isValid: (value) => setState(() => descriptionIsValid = value),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (int i = 0; i < (selectedPhotosAnexos?.length ?? 0); i++)
                CustomImageClient(
                  onTap: () {
                    setState(() {
                      selectedPhotosAnexos?.removeAt(i);
                    });
                  },
                  path: selectedPhotosAnexos![i].path,
                ),
              if (selectedPhotosAnexos!.isEmpty)
                Expanded(
                  child: SecondaryButton(
                    onPressed: onChangePhotosGastos,
                    child: const Text(
                      'Subir Imagen',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: !prestamoIsValid  || !descriptionIsValid || selectedPhotosAnexos!.isEmpty
              ? null
              : () {
                  Navigator.pop(context, true);
                  widget.onPressed!(
                    PayloadAnexo(
                      prestamoId: prestamoCtrl.text,
                      description: descriptionCtrl.text,
                      imagenes: selectedPhotosAnexos,
                    ),
                  );
                },
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
        const SizedBox(height: 15),
        TextButton.icon(
          onPressed: () => Navigator.pop(context, false),
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
