import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/theme.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/widgets/vender_bien_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Préstamo vencido hace 90 días (así no pide confirmar la venta).
LoansEntity _prestamo() => LoansEntity(
      codigo: 1, codigoFormateado: '000001', plazoDias: 30, interes: 10,
      fechaPago: DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
      fechaCierre: null, monto: '500', observaciones: null, estado: 'Vencido',
      cerrado: false, ganancia: '50', fecha: null, updatedAt: null, createdAt: null,
      boleta: null, notaCredito: null, cliente: null, admin: null, aumentos: null,
      aval: null, imagenLiquidado: null, imagenPagos: null, imagenAumentos: null,
      pagos: null, usuario: null, eliminado: false, bienesGarantia: const [],
      isRenewed: false, caja: null,
    );

Future<void> _abrirVenta(WidgetTester tester) async {
  // Pantalla del tamaño de un celular, con el MISMO tema que usa la app
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (ctx) => Theme(data: buildTheme(ctx), child: VenderBienPage(prestamo: _prestamo())),
    ),
  ));
  await tester.tap(find.textContaining('VENTA'));
  await tester.pumpAndSettle();
}

void main() {
  for (final doc in ['Contrato privado', 'Proforma', 'Boleta']) {
    testWidgets('$doc: se ve el campo DNI y el botón Buscar, sin errores', (tester) async {
      await _abrirVenta(tester);
      await tester.tap(find.text(doc));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'La pantalla no debe tener errores de diseño');
      expect(find.widgetWithText(TextField, 'DNI o RUC'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Buscar'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Nombre completo'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Domicilio'), findsOneWidget);

      // El campo DNI debe verse en pantalla (no con ancho cero)
      final caja = tester.getSize(find.widgetWithText(TextField, 'DNI o RUC'));
      expect(caja.width, greaterThan(150));
    });
  }

  testWidgets('Se puede escribir el DNI y corregir el nombre a mano', (tester) async {
    await _abrirVenta(tester);
    await tester.tap(find.text('Proforma'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'DNI o RUC'), '1234');
    await tester.enterText(find.widgetWithText(TextField, 'Nombre completo'), 'Juan Pérez');
    await tester.pump();
    expect(find.text('1234'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
