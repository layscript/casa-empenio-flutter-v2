import 'package:casa_empenio_pe/domain/caja/caja_entity.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Texto corto del medio de pago de un movimiento.
/// Ej.: "Efectivo", "Depósito · BCP", "Yape".
String etiquetaMedio(MovimientosEntity m) {
  switch ((m.medioPago ?? 'EFECTIVO').toUpperCase()) {
    case 'DEPOSITO':
      return (m.banco ?? '').trim().isEmpty
          ? 'Depósito'
          : 'Depósito · ${m.banco}';
    case 'YAPE':
      return 'Yape';
    case 'PLIN':
      return 'Plin';
    case 'OTRO':
      return 'Otro medio';
    default:
      return 'Efectivo';
  }
}

bool esEfectivo(MovimientosEntity m) =>
    (m.medioPago ?? 'EFECTIVO').toUpperCase() == 'EFECTIVO';

double _monto(MovimientosEntity m) => double.tryParse(m.monto ?? '0') ?? 0;

/// Suma de ingresos por medio (Efectivo, Depósito · BCP, Yape...).
Map<String, double> desgloseIngresos(List<MovimientosEntity> movs) {
  final mapa = <String, double>{};
  for (final m in movs) {
    if (m.suma != true) continue;
    final k = etiquetaMedio(m);
    mapa[k] = (mapa[k] ?? 0) + _monto(m);
  }
  return mapa;
}

/// Efectivo que debe haber físicamente en la caja:
/// ingresos en efectivo (incluye la apertura) − todos los egresos.
double efectivoEnMano(List<MovimientosEntity> movs) {
  var total = 0.0;
  for (final m in movs) {
    if (m.suma == true) {
      if (esEfectivo(m)) total += _monto(m);
    } else {
      total -= _monto(m);
    }
  }
  return total;
}

class DesgloseMedios extends StatelessWidget {
  const DesgloseMedios({super.key, required this.movimientos});
  final List<MovimientosEntity> movimientos;

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat('#,##0.00', 'en_US');
    final mapa = desgloseIngresos(movimientos);
    if (mapa.isEmpty) return const SizedBox();
    final entradas = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final enMano = efectivoEnMano(movimientos);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cómo entró el dinero?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          for (final e in entradas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    e.key == 'Efectivo'
                        ? Icons.payments_outlined
                        : (e.key.startsWith('Depósito')
                            ? Icons.account_balance_outlined
                            : Icons.phone_android),
                    size: 18,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.key)),
                  Text(
                    'S/.${oCcy.format(e.value)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const Divider(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Efectivo que debe haber en mano',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'S/.${oCcy.format(enMano)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Es la apertura + cobros en efectivo − egresos. Lo que entró por '
            'depósito, Yape o Plin está en el banco o celular, no en la caja.',
            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
