import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/products/widgets/widgets.dart';
import 'package:flutter/material.dart';

class EditProductDialog extends StatefulWidget {
  const EditProductDialog({
    super.key,
    required this.product,
    required this.isProduct,
    required this.categories,
  });
  final ProductEntity product;
  final bool isProduct;
  final List<CategoriesEntity> categories;

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  String? selectedOption;
  bool isLoading = false;

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

  void onChangeLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AlertDialog(
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
                    AddFormVehiculo(
                      data: widget.product,
                      categories: widget.categories,
                      setLoading: onChangeLoading,
                      isLoading: isLoading,
                    ),
                  if (selectedOption != null && selectedOption == 'Producto')
                    AddFormProduct(
                      data: widget.product,
                      categories: widget.categories,
                      setLoading: onChangeLoading,
                      isLoading: isLoading,
                    ),
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
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
