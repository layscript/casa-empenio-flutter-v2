import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/products/bloc/products_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchProducts extends StatefulWidget {
  const SearchProducts({
    super.key,
    required this.onPressed,
  });
  final void Function(String)? onPressed;

  @override
  State<SearchProducts> createState() => _SearchProductsState();
}

class _SearchProductsState extends State<SearchProducts> {
  final nameCtrl = TextEditingController();
  bool nameIsValid = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppTextFormField(
            suffixIcon: nameCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      nameCtrl.clear();
                      context.read<ProductsBloc>().add(
                            const GetProducts(),
                          );
                    },
                    child: const Icon(
                      Icons.clear,
                    ),
                  )
                : null,
            controller: nameCtrl,
            labelText: 'Buscar producto por nombre',
            isValid: (value) => setState(() => nameIsValid = value),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => widget.onPressed!(nameCtrl.text),
            child: const Text('Buscar'),
          ),
        ),
      ],
    );
  }
}
