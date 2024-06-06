import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/products/widgets/widgets.dart';
import 'package:flutter/material.dart';

class EditProductDialog extends StatefulWidget {
  const EditProductDialog({
    super.key,
    required this.product,
    required this.isProduct,
  });
  final ProductEntity product;
  final bool isProduct;

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  String? selectedOption;

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() {
    final result = widget.isProduct;
    setState(() {
      selectedOption = result ? 'Producto' : 'Vehiculo';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 20,
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      scrollable: true,
      title: const Text('Editar Producto'),
      content: Builder(builder: (context) {
        var width = MediaQuery.of(context).size.width;
        return SizedBox(
          width: width * 0.85,
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
                AddFormVehiculo(data: widget.product),
              if (selectedOption != null && selectedOption == 'Producto')
                AddFormProduct(data: widget.product),
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
