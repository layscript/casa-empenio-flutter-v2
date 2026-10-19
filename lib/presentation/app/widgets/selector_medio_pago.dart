import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

/// Elige CÓMO se movió el dinero: efectivo, depósito (con banco), Yape, Plin u
/// otro. Sirve para aumentos de préstamo, gastos y cualquier egreso.
///
/// `alCambiar` se llama cada vez que cambia algo, con el medio, el banco
/// (solo si es depósito) y si la elección ya está completa.
class SelectorMedioPago extends StatefulWidget {
  const SelectorMedioPago({
    super.key,
    required this.alCambiar,
    this.pregunta = '¿Cómo salió el dinero?',
    this.ayudaEfectivo = 'Sale dinero de la caja (efectivo).',
    this.verbo = 'salió',
  });

  final void Function(String medioPago, String? banco, bool completo)
      alCambiar;
  final String pregunta;
  final String ayudaEfectivo;
  final String verbo;

  @override
  State<SelectorMedioPago> createState() => _SelectorMedioPagoState();
}

class _SelectorMedioPagoState extends State<SelectorMedioPago> {
  String _medio = 'EFECTIVO';
  String? _banco;
  final _otroBancoCtrl = TextEditingController();

  static const _medios = <String, String>{
    'EFECTIVO': '💵 Efectivo',
    'DEPOSITO': '🏦 Depósito',
    'YAPE': '📱 Yape',
    'PLIN': '📱 Plin',
    'OTRO': '➕ Otro',
  };
  static const _bancos = [
    'BCP',
    'Interbank',
    'BBVA',
    'Scotiabank',
    'Caja Huancayo',
    'Banco de la Nación',
    'Otro banco',
  ];

  String? get _bancoFinal {
    if (_medio != 'DEPOSITO') return null;
    if (_banco == 'Otro banco') {
      final t = _otroBancoCtrl.text.trim();
      return t.isEmpty ? null : t;
    }
    return _banco;
  }

  bool get _completo => _medio != 'DEPOSITO' || _bancoFinal != null;

  void _avisar() => widget.alCambiar(_medio, _bancoFinal, _completo);

  @override
  void dispose() {
    _otroBancoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.pregunta,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in _medios.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _medio == e.key,
                onSelected: (_) {
                  setState(() {
                    _medio = e.key;
                    if (e.key != 'DEPOSITO') _banco = null;
                  });
                  _avisar();
                },
              ),
          ],
        ),
        if (_medio == 'DEPOSITO') ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _banco,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '¿En qué banco?'),
            items: _bancos
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) {
              setState(() => _banco = v);
              _avisar();
            },
          ),
          if (_banco == 'Otro banco') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _otroBancoCtrl,
              onChanged: (_) {
                setState(() {});
                _avisar();
              },
              decoration: const InputDecoration(labelText: 'Nombre del banco'),
            ),
          ],
        ],
        const SizedBox(height: 6),
        Text(
          _medio == 'EFECTIVO'
              ? widget.ayudaEfectivo
              : 'Se registra como ${_medios[_medio]!.substring(3)}'
                  '${_bancoFinal != null ? ' ($_bancoFinal)' : ''}: el dinero '
                  '${widget.verbo} sin tocar el efectivo de la caja. '
                  'No necesitas agregar efectivo para compensar.',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
