import 'dart:convert';

import 'package:casa_empenio_pe/presentation/app/utils/full_screen_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// PNG de 1x1 píxel
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');

void main() {
  testWidgets('el visor de fotos permite zoom con pellizco y doble toque', (tester) async {
    await tester.pumpWidget(MaterialApp(home: FullScreenImageUint8List(image: _png)));
    await tester.pump();
    final visor = find.byType(InteractiveViewer);
    expect(visor, findsOneWidget);
    final v = tester.widget<InteractiveViewer>(visor);
    expect(v.maxScale, greaterThanOrEqualTo(4));
    final ctl = v.transformationController!;
    expect(ctl.value.getMaxScaleOnAxis(), 1.0);

    // doble toque: acerca
    final centro = tester.getCenter(visor);
    await tester.tapAt(centro);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(centro);
    await tester.pumpAndSettle();
    expect(ctl.value.getMaxScaleOnAxis(), greaterThan(2));

    // otro doble toque: vuelve
    await tester.tapAt(centro);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tapAt(centro);
    await tester.pumpAndSettle();
    expect(ctl.value.getMaxScaleOnAxis(), 1.0);
  });

  testWidgets('pellizco con dos dedos acerca de inmediato, sin doble toque', (tester) async {
    await tester.pumpWidget(MaterialApp(home: FullScreenImageUint8List(image: _png)));
    await tester.pump();
    final visor = find.byType(InteractiveViewer);
    final ctl = tester.widget<InteractiveViewer>(visor).transformationController!;
    final c = tester.getCenter(visor);
    final a = await tester.startGesture(c - const Offset(20, 0), pointer: 1);
    final b = await tester.startGesture(c + const Offset(20, 0), pointer: 2);
    await tester.pump();
    await a.moveTo(c - const Offset(120, 0));
    await b.moveTo(c + const Offset(120, 0));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(ctl.value.getMaxScaleOnAxis(), greaterThan(1.5));
  });
}
