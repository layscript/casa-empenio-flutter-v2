import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AddFormProduct extends StatefulWidget {
  const AddFormProduct({super.key});

  @override
  State<AddFormProduct> createState() => _AddFormProductState();
}

class _AddFormProductState extends State<AddFormProduct> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextFormField(
          labelText: 'Nombre',
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                labelText: 'Marca',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Modelo',
              ),
            )
          ],
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                labelText: 'Marca',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Modelo',
              ),
            )
          ],
        ),
        SizedBox(height: 20),
        AppTextFormField(
          labelText: 'Observaciones',
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              ),
              label: const Text(
                'Salir',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
