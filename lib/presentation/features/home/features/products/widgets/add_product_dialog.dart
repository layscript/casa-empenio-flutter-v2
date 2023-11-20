import 'package:casa_empenio_pe/presentation/features/home/features/products/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  String? selectedOption;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Agregar Producto'),
      content: Builder(builder: (context) {
        var width = MediaQuery.of(context).size.width;
        return Container(
          width: width,
          //color: Colors.blue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: 'Vehiculo',
                      groupValue: selectedOption,
                      onChanged: (String? value) {
                        setState(() {
                          selectedOption = value;
                        });
                      },
                      title: const Text('Vehiculo'),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: 'Producto',
                      groupValue: selectedOption,
                      onChanged: (String? value) {
                        setState(() {
                          selectedOption = value;
                        });
                      },
                      title: const Text('Producto'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (selectedOption != null && selectedOption == 'Vehiculo')
                const AddFormVehiculo(),
              if (selectedOption != null && selectedOption == 'Producto')
                const AddFormProduct(),
            ],
          ),
        );
      }),
      actions: selectedOption == null
          ? [
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
              )
            ]
          : null,
    );
  }
}
