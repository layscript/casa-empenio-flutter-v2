import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Datos del cliente a mano (cuando el DNI/RUC no se reconoce o hay que corregirlo).
/// Dos datos principales, como en la venta de un bien: DNI/RUC y nombre completo.
class ManualCustomerForm extends StatefulWidget {
  const ManualCustomerForm({
    super.key,
    required this.documentNumber,
    required this.onSave,
    this.nombreInicial = '',
    this.direccionInicial = '',
  });

  final String documentNumber;
  final String nombreInicial;
  final String direccionInicial;
  final Function(CustomerSunatEntity) onSave;

  @override
  State<ManualCustomerForm> createState() => _ManualCustomerFormState();
}

class _ManualCustomerFormState extends State<ManualCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _docCtrl = TextEditingController(text: widget.documentNumber);
  late final TextEditingController _nombreCtrl = TextEditingController(text: widget.nombreInicial);
  late final TextEditingController _direccionCtrl = TextEditingController(text: widget.direccionInicial);

  bool get _isRuc => _docCtrl.text.trim().length == 11;

  @override
  void dispose() {
    _docCtrl.dispose();
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    final doc = _docCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final ruc = doc.length == 11;
    widget.onSave(
      CustomerSunatEntity(
        nombre: nombre,
        apellidoPaterno: '',
        apellidoMaterno: '',
        // Sin documento se guarda "0" (la proforma no lo exige)
        dni: ruc ? null : (doc.isEmpty ? '0' : doc),
        ruc: ruc ? doc : null,
        domicilio: HomeSunatEntity(
          direccion: _direccionCtrl.text.trim(),
          distrito: '',
          provincia: '',
          departamento: '',
          ubigeo: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextFormField(
            controller: _docCtrl,
            labelText: 'DNI o RUC (puedes corregirlo)',
            maxLength: 11,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return null; // proforma sin documento
              if (v.length != 8 && v.length != 11) return 'DNI de 8 dígitos o RUC de 11 (o déjalo vacío)';
              return null;
            },
          ),
          const SizedBox(height: 10),
          AppTextFormField(
            controller: _nombreCtrl,
            labelText: _isRuc ? 'Razón social' : 'Nombre completo',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _isRuc ? 'Escribe la razón social' : 'Escribe el nombre completo';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          AppTextFormField(
            controller: _direccionCtrl,
            labelText: 'Dirección (opcional)',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Guardar y continuar'),
            ),
          ),
        ],
      ),
    );
  }
}
