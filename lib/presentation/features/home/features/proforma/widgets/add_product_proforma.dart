import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/proforma/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AddProductProforma extends StatefulWidget {
  const AddProductProforma({super.key});

  @override
  State<AddProductProforma> createState() => _AddProductProformaState();
}

class _AddProductProformaState extends State<AddProductProforma> {
  int? index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Keyboard.unfocus(context),
      child: AlertDialog(
        insetPadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 20,
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        scrollable: true,
        title: const Text(
          'Agregar producto',
          textAlign: TextAlign.center,
        ),
        content: Builder(builder: (context) {
          var width = MediaQuery.of(context).size.width;
          return SizedBox(
            width: width * 0.85,
            child: index == null
                ? Row(
                    children: [
                      TextButton(
                        style: const ButtonStyle(
                          foregroundColor: MaterialStatePropertyAll(
                            Colors.white,
                          ),
                          backgroundColor: MaterialStatePropertyAll(
                            Colors.red,
                          ),
                        ),
                        onPressed: () => setState(() {
                          index = 1;
                        }),
                        child: const Text('Personalizado'),
                      ),
                      const Spacer(),
                      TextButton(
                        style: const ButtonStyle(
                          foregroundColor: MaterialStatePropertyAll(
                            Colors.white,
                          ),
                          backgroundColor: MaterialStatePropertyAll(
                            Colors.green,
                          ),
                        ),
                        onPressed: () => setState(() {
                          index = 2;
                        }),
                        child: const Text('Almacen'),
                      ),
                    ],
                  )
                : index == 1
                    ? CreateProductPersonalizadoProforma(width: width)
                    : CreateProductAlmacenProforma(width: width),
          );
        }),
      ),
    );
  }
}
