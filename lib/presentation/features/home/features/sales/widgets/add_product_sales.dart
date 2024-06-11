import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/sales/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AddProductoSales extends StatefulWidget {
  const AddProductoSales({super.key});

  @override
  State<AddProductoSales> createState() => _AddProductoSalesState();
}

class _AddProductoSalesState extends State<AddProductoSales> {
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
                    ? CreateProductPersonalizado(width: width)
                    : CreateProductAlmacen(width: width),
          );
        }),
      ),
    );
  }
}
