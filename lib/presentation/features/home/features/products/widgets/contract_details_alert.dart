import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/app/utils/utils.dart';
import 'package:flutter/material.dart';

class ContractsDetailsAlert extends StatefulWidget {
  const ContractsDetailsAlert({
    super.key,
    required this.product,
  });
  final ProductEntity product;

  @override
  State<ContractsDetailsAlert> createState() => _ContractsDetailsAlertState();
}

class _ContractsDetailsAlertState extends State<ContractsDetailsAlert> {
  int type = 1;
  final nombreController = TextEditingController();
  final dniController = TextEditingController();
  final domicilioController = TextEditingController();
  final precioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Datos del contrato'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de contrato'),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: 1,
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('Compra'),
                ),
                DropdownMenuItem(
                  value: 0,
                  child: Text('Venta'),
                ),
              ],
              onChanged: (int? value) {
                type = value!;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: nombreController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nombre completo',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: dniController,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'DNI',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: domicilioController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Domicilio',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: precioController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: 'S/.',
                labelText: 'Precio del vehiculo',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PdfPreviewVehiculoPage(
                  vehiculo: {
                    'id': widget.product.id,
                    'descripcion': widget.product.descripcion,
                    'categoria': widget.product.categoria,
                    'estado': widget.product.estado,
                    'marca': widget.product.marca,
                    'modelo': widget.product.modelo,
                    'color': widget.product.color,
                    'serie': widget.product.serie,
                    'placa': widget.product.placa,
                    'carroceria': widget.product.carroceria,
                    'motor': widget.product.motor,
                    'anio': widget.product.anio,
                    'valorizacion': widget.product.valorizacion,
                    'observaciones': widget.product.observaciones,
                    'cantidad': widget.product.cantidad,
                    'imagen': widget.product.imagen,
                    'activo': widget.product.activo,
                    'updatedAt': widget.product.updatedAt,
                    'createdAt': widget.product.createdAt,
                    'prestamo': widget.product.prestamo,
                  },
                  type: type,
                  cliente: {
                    "nombre": nombreController.text.trim(),
                    "dni": dniController.text.trim(),
                    "domicilio": domicilioController.text.trim(),
                    "valor": precioController.text.trim(),
                  },
                ),
              ),
            );
          },
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
