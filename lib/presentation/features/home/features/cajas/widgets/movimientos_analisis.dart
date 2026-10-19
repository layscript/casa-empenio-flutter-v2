import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/presentation/app/utils/validators.dart';
import 'package:flutter/material.dart';

/// Clase de movimiento (según su descripción), para dar nombre, icono y color.
enum ClaseMov {
  apertura,
  cierre,
  prestamo,
  pago,
  gasto,
  venta,
  aumentoPrestamo,
  aumentoCaja,
  otro,
}

ClaseMov claseDe(MovimientosEntity m) {
  final d = (m.tipo?.descripcion ?? '').toLowerCase();
  final esAumento = d.contains('aumento');
  final esPrestamo = d.contains('prést') || d.contains('prest');
  if (d.contains('apertura')) return ClaseMov.apertura;
  if (d.contains('cierre')) return ClaseMov.cierre;
  if (esAumento && esPrestamo) return ClaseMov.aumentoPrestamo;
  if (esAumento) return ClaseMov.aumentoCaja;
  if (esPrestamo) return ClaseMov.prestamo;
  if (d.contains('pago')) return ClaseMov.pago;
  if (d.contains('gasto')) return ClaseMov.gasto;
  if (d.contains('venta')) return ClaseMov.venta;
  return ClaseMov.otro;
}

String nombreClase(ClaseMov c) {
  switch (c) {
    case ClaseMov.apertura:
      return 'Apertura de caja';
    case ClaseMov.cierre:
      return 'Cierre de caja';
    case ClaseMov.prestamo:
      return 'Préstamo entregado';
    case ClaseMov.pago:
      return 'Pago recibido';
    case ClaseMov.gasto:
      return 'Gasto';
    case ClaseMov.venta:
      return 'Venta';
    case ClaseMov.aumentoPrestamo:
      return 'Aumento a un préstamo';
    case ClaseMov.aumentoCaja:
      return 'Dinero agregado a la caja';
    case ClaseMov.otro:
      return 'Movimiento';
  }
}

IconData iconoClase(ClaseMov c) {
  switch (c) {
    case ClaseMov.apertura:
      return Icons.lock_open;
    case ClaseMov.cierre:
      return Icons.lock_outline;
    case ClaseMov.prestamo:
      return Icons.request_quote_outlined;
    case ClaseMov.pago:
      return Icons.payments_outlined;
    case ClaseMov.gasto:
      return Icons.receipt_long_outlined;
    case ClaseMov.venta:
      return Icons.sell_outlined;
    case ClaseMov.aumentoPrestamo:
      return Icons.trending_up;
    case ClaseMov.aumentoCaja:
      return Icons.add_card_outlined;
    case ClaseMov.otro:
      return Icons.swap_vert;
  }
}

double montoDe(MovimientosEntity m) => double.tryParse(m.monto ?? '0') ?? 0;

/// ¿Es un movimiento "de control" (apertura/cierre)? No se revisa como duplicado.
bool esDeControl(MovimientosEntity m) {
  final c = claseDe(m);
  return c == ClaseMov.apertura || c == ClaseMov.cierre;
}

/// Un aviso que ayuda a encontrar rápido un error en la caja.
class AlertaMov {
  const AlertaMov({
    required this.clave,
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.color,
    required this.ids,
  });

  final String clave;
  final String titulo;
  final String detalle;
  final IconData icono;
  final Color color;

  /// ids de los movimientos involucrados
  final Set<int> ids;
}

/// Resultado del análisis de una caja.
class AnalisisCaja {
  const AnalisisCaja({required this.alertas, required this.duplicados});
  final List<AlertaMov> alertas;

  /// ids de movimientos que parecen duplicados (para marcarlos en la lista)
  final Set<int> duplicados;

  bool get limpio => alertas.every((a) => a.clave == 'anulados');
}

/// Busca errores típicos al cuadrar caja. Todo se calcula con lo que ya hay
/// en pantalla (no necesita internet).
AnalisisCaja analizarCaja(List<MovimientosEntity> todos) {
  final activos = todos.where((m) => m.eliminado != true).toList();
  final alertas = <AlertaMov>[];

  // ---- 1) Posibles duplicados: mismo tipo, monto, sentido y préstamo,
  //         registrados con menos de 20 minutos de diferencia ----
  final dup = <int>{};
  final revisables = activos.where((m) => !esDeControl(m) && m.id != null).toList()
    ..sort((a, b) {
      final fa = fechaPeru(a.createdAt) ?? DateTime(2000);
      final fb = fechaPeru(b.createdAt) ?? DateTime(2000);
      return fa.compareTo(fb);
    });
  for (var i = 0; i < revisables.length; i++) {
    for (var j = i + 1; j < revisables.length; j++) {
      final a = revisables[i];
      final b = revisables[j];
      final fa = fechaPeru(a.createdAt);
      final fb = fechaPeru(b.createdAt);
      if (fa == null || fb == null) continue;
      if (fb.difference(fa).inMinutes > 20) break;
      final mismoTipo = a.tipo?.id == b.tipo?.id;
      final mismoMonto = (montoDe(a) - montoDe(b)).abs() < 0.005;
      final mismoSentido = a.suma == b.suma;
      final mismoPrestamo = a.prestamoId != null
          ? a.prestamoId == b.prestamoId
          : (b.prestamoId == null &&
              (a.observaciones ?? '').trim() == (b.observaciones ?? '').trim());
      if (mismoTipo && mismoMonto && mismoSentido && mismoPrestamo) {
        dup.add(a.id!);
        dup.add(b.id!);
      }
    }
  }
  if (dup.isNotEmpty) {
    alertas.add(AlertaMov(
      clave: 'duplicados',
      titulo: 'Posibles duplicados (${dup.length} movimientos)',
      detalle: 'Mismo tipo, mismo monto y mismo préstamo registrados con '
          'pocos minutos de diferencia. Si uno está de más, anúlalo.',
      icono: Icons.copy_all_outlined,
      color: Colors.red,
      ids: dup,
    ));
  }

  // ---- 2) Préstamos, pagos o aumentos sin préstamo asociado ----
  final sinPrestamo = activos.where((m) {
    final c = claseDe(m);
    final necesita = c == ClaseMov.prestamo ||
        c == ClaseMov.pago ||
        c == ClaseMov.aumentoPrestamo;
    return necesita && m.prestamoId == null && m.id != null;
  }).map((m) => m.id!).toSet();
  if (sinPrestamo.isNotEmpty) {
    alertas.add(AlertaMov(
      clave: 'sinPrestamo',
      titulo: 'Sin préstamo asociado (${sinPrestamo.length})',
      detalle: 'Son movimientos de préstamo/pago que no indican a qué '
          'préstamo pertenecen. Revisa si se registraron bien.',
      icono: Icons.link_off,
      color: Colors.orange,
      ids: sinPrestamo,
    ));
  }

  // ---- 3) Gastos sin descripción ----
  final gastosVacios = activos.where((m) {
    return claseDe(m) == ClaseMov.gasto &&
        (m.observaciones ?? '').trim().isEmpty &&
        m.id != null;
  }).map((m) => m.id!).toSet();
  if (gastosVacios.isNotEmpty) {
    alertas.add(AlertaMov(
      clave: 'gastosVacios',
      titulo: 'Gastos sin descripción (${gastosVacios.length})',
      detalle: 'Anota siempre en qué se gastó, así luego sabrás de dónde '
          'salió ese dinero.',
      icono: Icons.edit_note,
      color: Colors.orange,
      ids: gastosVacios,
    ));
  }

  // ---- 4) Varios "dinero agregado a la caja" en el mismo día ----
  final aumentosCaja = activos
      .where((m) => claseDe(m) == ClaseMov.aumentoCaja && m.id != null)
      .map((m) => m.id!)
      .toSet();
  if (aumentosCaja.length >= 2) {
    alertas.add(AlertaMov(
      clave: 'aumentosCaja',
      titulo: 'Agregaste dinero a la caja ${aumentosCaja.length} veces',
      detalle: 'Si pagaste un aumento o préstamo por depósito/Yape, ya no '
          'necesitas "agregar efectivo": registra ese aumento con el medio '
          'de pago correcto y la caja cuadra sola.',
      icono: Icons.add_card_outlined,
      color: Colors.amber[800]!,
      ids: aumentosCaja,
    ));
  }

  // ---- 5) Anulados (solo informativo) ----
  final anulados =
      todos.where((m) => m.eliminado == true && m.id != null).map((m) => m.id!).toSet();
  if (anulados.isNotEmpty) {
    alertas.add(AlertaMov(
      clave: 'anulados',
      titulo: 'Movimientos anulados (${anulados.length})',
      detalle: 'Ya no cuentan en el cuadre de caja. Se muestran tachados '
          'solo para que quede el historial.',
      icono: Icons.block,
      color: Colors.blueGrey,
      ids: anulados,
    ));
  }

  return AnalisisCaja(alertas: alertas, duplicados: dup);
}
