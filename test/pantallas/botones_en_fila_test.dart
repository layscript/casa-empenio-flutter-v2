import 'package:casa_empenio_pe/presentation/app/assets/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Con el tema de la app, un botón al lado de un campo (como "Nuevo" en Usuarios
/// o "Nuevo rol" en Roles) debe verse sin romper la fila.
void main() {
  testWidgets('Botón con ancho normal dentro de una fila, con el tema de la app', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => Theme(
          data: buildTheme(ctx),
          child: Scaffold(
            body: Row(children: [
              const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Buscar usuario'))),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                onPressed: () {},
                icon: const Icon(Icons.person_add),
                label: const Text('Nuevo'),
              ),
            ]),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('Nuevo'), findsOneWidget);
    expect(tester.getSize(find.byType(TextField)).width, greaterThan(150));
  });
}
