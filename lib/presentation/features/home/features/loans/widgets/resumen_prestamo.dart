import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

/// Vista previa de un préstamo en las listas de búsqueda: número, monto,
/// cliente, el bien (código · descripción · marca) y el estado en un solo vistazo.
class ResumenPrestamo extends StatelessWidget {
  const ResumenPrestamo({
    super.key,
    required this.prestamo,
    required this.monto,
    this.fecha,
  });

  final LoansEntity prestamo;
  final String monto;
  final String? fecha;

  static Color _colorEstado(String? e) {
    switch (e) {
      case 'VIGENTE':
        return Colors.green.shade700;
      case 'VENCIDO':
        return Colors.red.shade700;
      case 'VENTA':
        return Colors.orange.shade800;
      case 'PAGADO':
      case 'LIQUIDADO':
        return Colors.blueGrey;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = prestamo;
    final bienes = p.bienesGarantia ?? const [];
    String? bien;
    if (bienes.isNotEmpty) {
      final b = bienes.first;
      final partes = [
        if ((b.codigoInventario ?? '').isNotEmpty) b.codigoInventario,
        if ((b.description ?? '').isNotEmpty) b.description,
        if ((b.marca ?? '').isNotEmpty) b.marca,
        if ((b.modelo ?? '').isNotEmpty) b.modelo,
      ];
      bien = partes.join(' · ');
      if (bienes.length > 1) bien = '$bien  (+${bienes.length - 1} más)';
    }
    final cliente =
        '${p.cliente?.nombres ?? ''} ${p.cliente?.apellidos ?? ''}'.trim();
    final color = _colorEstado(p.estado);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'N° ${p.codigo.toString().padLeft(6, '0')}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Text(
                'S/. $monto',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          if (cliente.isNotEmpty)
            Text(
              cliente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          if (bien != null && bien.isNotEmpty)
            Text(
              bien,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.secondaryText),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${p.estado}',
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              if (fecha != null)
                Text(
                  fecha!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.secondaryText),
                ),
              if (p.isRenewed == true)
                Text(
                  (p.renewalCount ?? 0) > 0
                      ? 'RENOVACIÓN N° ${p.renewalCount}'
                      : 'RENOVADO',
                  style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                      fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
