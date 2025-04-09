import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ManualCustomerForm extends StatefulWidget {
  const ManualCustomerForm({
    super.key,
    required this.documentNumber,
    required this.onSave,
  });

  final String documentNumber;
  final Function(CustomerSunatEntity) onSave;

  @override
  State<ManualCustomerForm> createState() => _ManualCustomerFormState();
}

class _ManualCustomerFormState extends State<ManualCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoPaternoCtrl = TextEditingController();
  final _apellidoMaternoCtrl = TextEditingController();
  final _razonSocialCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  
  bool get isRuc => widget.documentNumber.length == 11;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    _razonSocialCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Verificar si todos los campos están vacíos
      final bool allFieldsEmpty = isRuc
          ? _razonSocialCtrl.text.isEmpty && _direccionCtrl.text.isEmpty
          : _nombreCtrl.text.isEmpty &&
              _apellidoPaternoCtrl.text.isEmpty &&
              _apellidoMaternoCtrl.text.isEmpty &&
              _direccionCtrl.text.isEmpty;

      // Si todos los campos están vacíos, usar "Cliente Genérico"
      final String nombre = allFieldsEmpty
          ? 'Cliente Genérico'
          : isRuc
              ? (_razonSocialCtrl.text.isEmpty ? 'Cliente Genérico' : _razonSocialCtrl.text)
              : (_nombreCtrl.text.isEmpty ? 'Cliente Genérico' : _nombreCtrl.text);

      // Crear un objeto CustomerSunatEntity con los datos ingresados manualmente
      // Si es cliente genérico (todos los campos vacíos), usar DNI "00000000"
      final String dniValue = allFieldsEmpty || nombre == 'Cliente Genérico' 
          ? "00000000" 
          : widget.documentNumber;
          
      final manualCustomer = CustomerSunatEntity(
        nombre: nombre,
        apellidoPaterno: isRuc ? '' : _apellidoPaternoCtrl.text,
        apellidoMaterno: isRuc ? '' : _apellidoMaternoCtrl.text,
        dni: isRuc ? null : dniValue,
        ruc: isRuc ? widget.documentNumber : null,
        domicilio: HomeSunatEntity(
          direccion: _direccionCtrl.text,
          distrito: '',
          provincia: '',
          departamento: '',
          ubigeo: '',
        ),
      );

      widget.onSave(manualCustomer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRuc) ...[
            // Formulario para RUC (empresas)
            AppTextFormField(
              controller: _razonSocialCtrl,
              labelText: 'Razón Social (opcional)',
            ),
          ] else ...[
            // Formulario para DNI (personas naturales)
            AppTextFormField(
              controller: _nombreCtrl,
              labelText: 'Nombres (opcional)',
            ),
            const SizedBox(height: 10),
            AppTextFormField(
              controller: _apellidoPaternoCtrl,
              labelText: 'Apellido Paterno (opcional)',
            ),
            const SizedBox(height: 10),
            AppTextFormField(
              controller: _apellidoMaternoCtrl,
              labelText: 'Apellido Materno (opcional)',
            ),
          ],
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
              child: const Text('Guardar y Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}
