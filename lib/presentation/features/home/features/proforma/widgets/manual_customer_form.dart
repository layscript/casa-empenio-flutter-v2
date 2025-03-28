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
  final _direccionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Crear un objeto CustomerSunatEntity con los datos ingresados manualmente
      final manualCustomer = CustomerSunatEntity(
        nombre: _nombreCtrl.text,
        apellidoPaterno: _apellidoPaternoCtrl.text,
        apellidoMaterno: _apellidoMaternoCtrl.text,
        dni: widget.documentNumber,
        ruc: widget.documentNumber.length > 8 ? widget.documentNumber : null,
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
          AppTextFormField(
            controller: _nombreCtrl,
            labelText: 'Nombres',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa los nombres';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          AppTextFormField(
            controller: _apellidoPaternoCtrl,
            labelText: 'Apellido Paterno',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el apellido paterno';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          AppTextFormField(
            controller: _apellidoMaternoCtrl,
            labelText: 'Apellido Materno',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa el apellido materno';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          AppTextFormField(
            controller: _direccionCtrl,
            labelText: 'Dirección',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa la dirección';
              }
              return null;
            },
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
