import 'package:casa_empenio_pe/presentation/app/utils/contrato_compraventa.dart';
import 'package:flutter_test/flutter_test.dart';

DatosContrato _d({required bool veh, String civil = 'Casado'}) => DatosContrato(
      empresaCompra: true,
      esVehiculo: veh,
      nombre: 'Juan Pérez Ñahui',
      dni: '12345678',
      domicilio: 'Jr. Tarapacá 123, Pucallpa',
      descripcion: veh ? 'Motocar Bajaj' : 'Laptop HP 15',
      marca: 'BAJAJ',
      modelo: 'RE',
      color: 'ROJO',
      serie: 'ABC123',
      placa: veh ? '1234-AB' : '',
      motor: 'M123',
      carroceria: 'C123',
      anio: '2020',
      clase: 'MOTOCAR',
      estado: 'USADO',
      precio: 3500,
      ciudad: 'Pucallpa',
      fecha: DateTime(2026, 11, 27),
      representante: 'María López',
      medioPago: 'EFECTIVO',
      documentoPropiedad: 'Tarjeta de propiedad',
      estadoCivil: civil,
    );

void main() {
  for (final veh in [true, false]) {
    test('Contrato de compra ${veh ? "vehículo" : "artefacto"} genera PDF', () async {
      final b = await crearContratoCompraVentaPdf(_d(veh: veh));
      expect(String.fromCharCodes(b.sublist(0, 4)), '%PDF');
      expect(b.length > 3000, true);
    });
  }
  test('Soltero también genera PDF', () async {
    final b = await crearContratoCompraVentaPdf(_d(veh: false, civil: 'Soltero'));
    expect(String.fromCharCodes(b.sublist(0, 4)), '%PDF');
  });
}
