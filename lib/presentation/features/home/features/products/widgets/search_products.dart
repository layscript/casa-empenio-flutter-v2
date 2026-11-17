import 'package:casa_empenio_pe/presentation/app/utils/escaner_bien.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:flutter/material.dart';

class SearchProducts extends StatefulWidget {
  const SearchProducts({
    Key? key,
    required this.onPressed,
    required this.suffixOnPressed,
    this.initialValue = '',
  }) : super(key: key);

  final void Function(String)? onPressed;
  final void Function()? suffixOnPressed;
  final String initialValue;

  @override
  State<SearchProducts> createState() => _SearchProductsState();
}

class _SearchProductsState extends State<SearchProducts> {
  late TextEditingController nameCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  void clearSearch() {
    nameCtrl.clear();
    widget.suffixOnPressed!(); // Llama al método en el widget padre
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppTextFormField(
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (nameCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      clearSearch(); // Llama a la función para limpiar
                    },
                    child: const Icon(
                      Icons.clear,
                    ),
                  ),
                botonBuscarConFoto(context, alLeer: (v) {
                  setState(() => nameCtrl.text = v);
                  widget.onPressed?.call(v);
                }),
              ],
            ),
            controller: nameCtrl,
            labelText: 'Buscar por nombre, código, placa, DNI…',
            isValid: (value) => setState(() {}),
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
