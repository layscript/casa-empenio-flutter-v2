import 'package:casa_empenio_pe/domain/roles/rol_entity.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/cajas/views/open_caja_view.dart';
import 'package:flutter/material.dart';

class ShowRolDialogInfo extends StatelessWidget {
  const ShowRolDialogInfo({
    super.key,
    required this.rol,
  });
  final RoleEntity rol;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ROL: ${rol.nombre}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rol.modulos!.isEmpty)
              const Text('No cuenta con módulos')
            else ...[
              const Text(
                'MÓDULOS:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rol.modulos
                        ?.map(
                          (e) => Text(
                            '- ${e.nombre}',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        )
                        .toList() ??
                    [],
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: Colors.red),
          ),
        )
      ],
    );
  }
}
