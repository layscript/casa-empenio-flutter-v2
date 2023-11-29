import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditInterestsDialog extends StatefulWidget {
  const EditInterestsDialog({
    super.key,
    required this.interests,
  });
  final InterestsEntity interests;

  @override
  State<EditInterestsDialog> createState() => _EditInterestsDialogState();
}

class _EditInterestsDialogState extends State<EditInterestsDialog> {
  final interesCtrl = TextEditingController();
  bool interestIsValid = false;

  @override
  void initState() {
    super.initState();
    interesCtrl.text = widget.interests.intereses;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Editar Interés'),
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
                  context.read<InterestsBloc>().add(UpdateInterest(
                        id: widget.interests.id,
                        data: interesCtrl.text,
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
