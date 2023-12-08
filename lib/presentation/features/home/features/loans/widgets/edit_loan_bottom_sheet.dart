import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditLoanBottomSheet extends StatefulWidget {
  const EditLoanBottomSheet({
    super.key,
    required this.idPrestamo,
    required this.isNuevo,
  });
  final int idPrestamo;
  final bool isNuevo;

  @override
  State<EditLoanBottomSheet> createState() => _EditLoanBottomSheetState();
}

class _EditLoanBottomSheetState extends State<EditLoanBottomSheet> {
  int tabIndex = 0;

  final oCcy = NumberFormat("#,##0.00", "en_US");
  final ImagePicker _picker = ImagePicker();

  // FORM KEY
  final _formKeyCliente = GlobalKey<FormState>();
  final _formKeyAval = GlobalKey<FormState>();
  final _formKeyPrestamo = GlobalKey<FormState>();
  final _formKeyGarantia = GlobalKey<FormState>();

  // CONTROLLERS CLIENTE
  final TextEditingController _nombreClienteController =
      TextEditingController();
  final TextEditingController _apellidoClienteController =
      TextEditingController();
  final TextEditingController _dniClienteController = TextEditingController();
  final TextEditingController _celularClienteController =
      TextEditingController();
  final TextEditingController _direccionClienteController =
      TextEditingController();
  final TextEditingController _correoClienteController =
      TextEditingController(); // OPCIONAL

  // CONTROLLERS AVAL
  final TextEditingController _nombreAvalController = TextEditingController();
  final TextEditingController _apellidoAvalController = TextEditingController();
  final TextEditingController _dniAvalController = TextEditingController();
  final TextEditingController _celularAvalController = TextEditingController();
  final TextEditingController _direccionAvalController =
      TextEditingController();
  final TextEditingController _correoAvalController =
      TextEditingController(); // OPCIONAL

  // CONTROLLERS PRESTAMO
  final TextEditingController _codigoPrestamoController =
      TextEditingController();
  final TextEditingController _fechaPrestamoController =
      TextEditingController();
  double _valorTasaPrestamo = 0;
  final TextEditingController _plazosPrestamoController =
      TextEditingController();
  final TextEditingController _fechaPagoPrestamoController =
      TextEditingController();
  final TextEditingController _montoPrestamoController =
      TextEditingController();
  final TextEditingController _observacionesPrestamoController =
      TextEditingController(); // OPCIONAL
  double _montoPagarPrestamo = 0;
  double _gananciaPrestamo = 0;
  DateTime fechaPago = DateTime.now();

  int garantias = 1;
  // CONTROLLERS GARANTIA
  final List<Map<String, dynamic>> _garantiasControllers = [];

  bool _isLoadingDni = false;
  bool _isAval = false;
  DateTime now = DateTime.now();
  List<InterestsEntity> intereses = [];

  @override
  void initState() {
    super.initState();
    _getPrestamo();
    _getIntereses();
  }

  Future<void> _getPrestamo() async {
    final pres = await context.read<LoansRepository>().getLoan(
          id: widget.idPrestamo,
        );
    if (mounted) {
      setState(() {
        pres.fold((error) => null, (prestamo) {
          _nombreClienteController.text = prestamo.cliente?.nombres ?? '';
          _apellidoClienteController.text = prestamo.cliente?.apellidos ?? '';
          _dniClienteController.text = prestamo.cliente?.dni ?? '';
          _celularClienteController.text = prestamo.cliente?.celular ?? '';
          _direccionClienteController.text = prestamo.cliente?.domicilio ?? '';
          _correoClienteController.text = prestamo.cliente?.email ?? '';
          _isAval = prestamo.aval != null;
          if (_isAval) {
            _nombreAvalController.text = prestamo.aval?.nombres ?? '';
            _apellidoAvalController.text = prestamo.aval?.apellidos ?? '';
            _dniAvalController.text = prestamo.aval?.dni ?? '';
            _celularAvalController.text = prestamo.aval?.celular ?? '';
            _direccionAvalController.text = prestamo.aval?.domicilio ?? '';
            _correoAvalController.text = prestamo.aval?.email ?? '';
          }

          _codigoPrestamoController.text =
              prestamo.codigo.toString().padLeft(6, '0');
          _fechaPrestamoController.text = DateFormat('dd/MM/yyyy')
              .format(DateTime.parse(prestamo.fecha ?? '').toLocal());
          _valorTasaPrestamo = double.parse(prestamo.interes.toString());
          _montoPrestamoController.text = prestamo.monto.toString();
          _observacionesPrestamoController.text = prestamo.observaciones ?? '';
          _gananciaPrestamo = double.parse(prestamo.ganancia.toString());
          _montoPagarPrestamo =
              double.parse(prestamo.monto.toString()) + _gananciaPrestamo;

          if (!widget.isNuevo) {
            _plazosPrestamoController.text = prestamo.plazoDias.toString();
            _fechaPagoPrestamoController.text = DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(prestamo.fechaPago ?? '').toLocal());
            final fechaCreacion =
                DateTime.parse(prestamo.fecha ?? '').toLocal();
            now = DateTime.parse(prestamo.fecha ?? '').toLocal();
            fechaPago = fechaCreacion.add(
              Duration(days: int.parse(prestamo.plazoDias.toString()) - 1),
            );
          }

          prestamo.bienesGarantia?.forEach((garantia) {
            _garantiasControllers.add({
              "descripcion": TextEditingController(text: garantia.description),
              "valor":
                  TextEditingController(text: garantia.valorizacion.toString()),
              "observaciones": TextEditingController(
                  text: garantia.observaciones.toString()),
              "marca": TextEditingController(text: garantia.marca.toString()),
              "modelo": TextEditingController(text: garantia.modelo.toString()),
              "serie": TextEditingController(text: garantia.serie.toString()),
              "color": TextEditingController(text: garantia.color.toString()),
              "keyForm": GlobalKey<FormState>(),
              "estado": 'regular',
              'imagen': garantia.imagen,
            });
          });
          garantias = prestamo.bienesGarantia?.length ?? 0;
        });
      });
    }

    if (widget.isNuevo) {
      _getUltimoCodigo();
      String formattedDate = DateFormat('dd/MM/yyyy').format(now);
      _fechaPrestamoController.text = formattedDate;
    }
  }

  Future<void> _getUltimoCodigo() async {
    final ultimoCodigo = await context.read<LoansRepository>().getLastCode();
    ultimoCodigo.fold(
      (error) => null,
      (code) {
        _codigoPrestamoController.text = (code + 1).toString().padLeft(6, '0');
      },
    );
  }

  Future<void> _getIntereses() async {
    final response = await context.read<InterestsRepository>().getInterest();
    if (mounted) {
      response.fold(
        (error) => null,
        (interest) {
          intereses = interest;
        },
      );
    }
  }

  Future<void> _getCliente(String value, String tipo) async {
    setState(() {
      _isLoadingDni = true;
    });
    final cliente =
        await context.read<CustomerRepository>().getCustomerByDni(dni: value);

    cliente.fold(
      (l) {
        if (tipo == 'cliente') {
          _nombreClienteController.text = '';
          _apellidoClienteController.text = '';
          _celularClienteController.text = '';
          _direccionClienteController.text = '';
          _correoClienteController.text = '';
        } else {
          _nombreAvalController.text = '';
          _apellidoAvalController.text = '';
          _celularAvalController.text = '';
          _direccionAvalController.text = '';
          _correoAvalController.text = '';
        }
      },
      (c) {
        if (tipo == 'cliente') {
          _nombreClienteController.text = c.nombres ?? '';
          _apellidoClienteController.text = c.apellidos ?? '';
          _celularClienteController.text = c.celular ?? '';
          _direccionClienteController.text = c.domicilio ?? '';
          _correoClienteController.text = c.email ?? '';
        } else {
          _nombreAvalController.text = c.nombres ?? '';
          _apellidoAvalController.text = c.apellidos ?? '';
          _celularAvalController.text = c.celular ?? '';
          _direccionAvalController.text = c.domicilio ?? '';
          _correoAvalController.text = c.email ?? '';
        }
      },
    );
    setState(() {
      _isLoadingDni = false;
    });
  }

  @override
  Widget build(BuildContext context) {
/*     final List<Widget> garantiasWidget = [];
    if (_garantiasControllers.isNotEmpty) {
      for (var i = 0; i < garantias; i++) {
        if (garantias > _garantiasControllers.length) {
          _garantiasControllers.add({
            "descripcion": TextEditingController(),
            "valor": TextEditingController(),
            "observaciones": TextEditingController(),
            "marca": TextEditingController(),
            "modelo": TextEditingController(),
            "serie": TextEditingController(),
            "color": TextEditingController(),
            "keyForm": GlobalKey<FormState>(),
            "estado": 'regular',
          });
        }
        garantiasWidget.add(_buildFormGarantia(
            _garantiasControllers[i]['keyForm'],
            _garantiasControllers[i]['descripcion'],
            _garantiasControllers[i]['marca'],
            _garantiasControllers[i]['modelo'],
            _garantiasControllers[i]['serie'],
            _garantiasControllers[i]['observaciones'],
            _garantiasControllers[i]['valor'],
            _garantiasControllers[i]['color'],
            _garantiasControllers[i]['estado'],
            i,
            _garantiasControllers));
      }
    } */

    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  onTap: (value) {
                    setState(() {
                      tabIndex = value;
                    });
                  },
                  tabs: const [
                    SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          'CLIENTE',
                          style: TextStyle(
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          'PRESTAMO',
                          style: TextStyle(
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                      child: Center(
                        child: Text(
                          'GARANTIA',
                          style: TextStyle(
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      child: Column(children: [
                        _buildFormCliente(),
                        _isAval ? _buildFormAval() : const SizedBox(),
                      ]),
                    ),
                    SingleChildScrollView(
                      child: Column(children: [
                        _buildFormPrestamo(),
                      ]),
                    ),
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _garantiasControllers.length,
                            itemBuilder: (context, index) {
                              if (garantias > _garantiasControllers.length) {
                                _garantiasControllers.add({
                                  "descripcion": TextEditingController(),
                                  "valor": TextEditingController(),
                                  "observaciones": TextEditingController(),
                                  "marca": TextEditingController(),
                                  "modelo": TextEditingController(),
                                  "serie": TextEditingController(),
                                  "color": TextEditingController(),
                                  "keyForm": GlobalKey<FormState>(),
                                  "estado": 'regular',
                                });
                              }

                              /* for (var i = 0; i < garantias; i++) {
                                if (garantias > _garantiasControllers.length) {
                                  _garantiasControllers.add({
                                    "descripcion": TextEditingController(),
                                    "valor": TextEditingController(),
                                    "observaciones": TextEditingController(),
                                    "marca": TextEditingController(),
                                    "modelo": TextEditingController(),
                                    "serie": TextEditingController(),
                                    "color": TextEditingController(),
                                    "keyForm": GlobalKey<FormState>(),
                                    "estado": 'regular',
                                  });
                                }
                                garantiasWidget.add(_buildFormGarantia(
                                    _garantiasControllers[i]['keyForm'],
                                    _garantiasControllers[i]['descripcion'],
                                    _garantiasControllers[i]['marca'],
                                    _garantiasControllers[i]['modelo'],
                                    _garantiasControllers[i]['serie'],
                                    _garantiasControllers[i]['observaciones'],
                                    _garantiasControllers[i]['valor'],
                                    _garantiasControllers[i]['color'],
                                    _garantiasControllers[i]['estado'],
                                    i,
                                    _garantiasControllers));
                              } */

                              return Container(
                                padding: const EdgeInsets.all(20),
                                child: Form(
                                  key: _garantiasControllers[index]['keyForm'],
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'BIEN ${index + 1} EN GARANTIA',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        controller: _garantiasControllers[index]
                                            ['descripcion'],
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'El campo es requerido';
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Descripción',
                                        ),
                                      ),
                                      const Divider(height: 15),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.50 -
                                                27.5,
                                            child: TextFormField(
                                              validator: (value) {
                                                if (value?.isEmpty ?? true) {
                                                  return 'El campo es requerido';
                                                }
                                                return null;
                                              },
                                              controller:
                                                  _garantiasControllers[index]
                                                      ['marca'],
                                              decoration: const InputDecoration(
                                                labelText: 'Marca',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.50 -
                                                27.5,
                                            child: TextFormField(
                                              validator: (value) {
                                                if (value?.isEmpty ?? true) {
                                                  return 'El campo es requerido';
                                                }
                                                return null;
                                              },
                                              controller:
                                                  _garantiasControllers[index]
                                                      ['modelo'],
                                              decoration: const InputDecoration(
                                                labelText: 'Modelo',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.50 -
                                                27.5,
                                            child: TextFormField(
                                              validator: (value) {
                                                if (value?.isEmpty ?? true) {
                                                  return 'El campo es requerido';
                                                }
                                                return null;
                                              },
                                              controller:
                                                  _garantiasControllers[index]
                                                      ['color'],
                                              decoration: const InputDecoration(
                                                labelText: 'Color',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.50 -
                                                27.5,
                                            child: DropdownButtonFormField(
                                              value:
                                                  _garantiasControllers[index]
                                                      ['estado'],
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              validator: (value) {
                                                if (value == null) {
                                                  return 'El campo es requerido';
                                                }
                                                return null;
                                              },
                                              decoration: const InputDecoration(
                                                labelText: 'Estado',
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'nuevo',
                                                  child: Center(
                                                      child: Text('Nuevo')),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'bueno',
                                                  child: Center(
                                                      child: Text('Bueno')),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'regular',
                                                  child: Center(
                                                      child: Text('Regular')),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  _garantiasControllers[index]
                                                          ['estado'] =
                                                      value.toString();
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      TextFormField(
                                        controller: _garantiasControllers[index]
                                            ['serie'],
                                        decoration: const InputDecoration(
                                          labelText: 'Serie',
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      TextFormField(
                                        maxLines: 8,
                                        minLines: 1,
                                        controller: _garantiasControllers[index]
                                            ['observaciones'],
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        decoration: const InputDecoration(
                                          labelText: 'Observaciones',
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      TextFormField(
                                        controller: _garantiasControllers[index]
                                            ['valor'],
                                        //textDirection: TextDirection.ltr,
                                        keyboardType: TextInputType.number,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        decoration: const InputDecoration(
                                          prefix: Text('S/. '),
                                          labelText: 'Precio Referencial',
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _garantiasControllers[index]
                                                      ['imagen'] !=
                                                  null
                                              ? _garantiasControllers[index]
                                                          ['imagen']
                                                      .contains(
                                                          'files/garantias')
                                                  ? Expanded(
                                                      child: Image.network(
                                                        '$endPoint/${_garantiasControllers[index]['imagen']}',
                                                        width: 100,
                                                        height: 100,
                                                      ),
                                                    )
                                                  : Expanded(
                                                      child: Image.file(
                                                        File(
                                                            _garantiasControllers[
                                                                    index]
                                                                ['imagen']),
                                                        width: 100,
                                                        height: 100,
                                                      ),
                                                    )
                                              : const SizedBox.shrink(),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                final XFile? photo =
                                                    await _cargarImagen();
                                                if (photo != null) {
                                                  setState(() {
                                                    _garantiasControllers[index]
                                                        ['imagen'] = photo.path;
                                                  });
                                                }
                                              },
                                              child: _garantiasControllers[
                                                          index]['imagen'] !=
                                                      null
                                                  ? const Text('Cambiar Imagen')
                                                  : const Text('Cargar Imagen'),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 60),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.save),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCliente() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKeyCliente,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // const SizedBox(width: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DATOS DEL CLIENTE',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  width: 140,
                  height: 50,
                  child: SwitchListTile(
                    value: _isAval,
                    onChanged: (value) {
                      setState(() {
                        _isAval = value;
                      });
                    },
                    title: const Text('Aval'),
                  ),
                )
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.38,
                  child: AppTextFormField(
                    enabled: !_isLoadingDni,
                    controller: _dniClienteController,
                    validator: (value) {
                      if (value?.length != 8) {
                        return 'Ingrese un valor correcto';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    labelText: 'DNI',
                    suffixIcon: _isLoadingDni
                        ? Container(
                            padding: const EdgeInsets.all(15),
                            height: 10,
                            width: 10,
                            child: const CircularProgressIndicator(),
                          )
                        : null,
                    onChanged: (value) {
                      if (value.length == 8) {
                        setState(() {
                          _isLoadingDni = true;
                        });
                        _getCliente(value, 'cliente');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.62 - 55,
                  child: AppTextFormField(
                    controller: _nombreClienteController,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    labelText: 'Nombres',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.38,
                  child: AppTextFormField(
                    controller: _celularClienteController,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    preffix: const Text('(+51)'),
                    labelText: 'Celular',
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.62 - 55,
                  child: AppTextFormField(
                    controller: _apellidoClienteController,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    labelText: 'Apellidos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            AppTextFormField(
              controller: _correoClienteController,
              keyboardType: TextInputType.emailAddress,
              labelText: 'Correo Electrónico',
            ),
            const SizedBox(height: 15),
            AppTextFormField(
              controller: _direccionClienteController,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'El campo es requerido';
                }
                return null;
              },
              labelText: 'Domicilio',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormAval() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKeyAval,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // const SizedBox(width: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'DATOS DEL AVAL',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                )
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.38,
                  child: TextFormField(
                    enabled: !_isLoadingDni,
                    controller: _dniAvalController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.length != 8) {
                        return 'Ingrese un valor correcto';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      suffixIcon: _isLoadingDni
                          ? Container(
                              padding: const EdgeInsets.all(15),
                              height: 10,
                              width: 10,
                              child: const CircularProgressIndicator(),
                            )
                          : null,
                      labelText: 'DNI',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.length == 8) {
                        setState(() {
                          _isLoadingDni = true;
                        });
                        _getCliente(value, 'aval');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.62 - 55,
                  child: TextFormField(
                    controller: _nombreAvalController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Nombres',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.38,
                  child: TextFormField(
                    controller: _celularAvalController,
                    //textDirection: TextDirection.rtl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      prefix: Text('+51'),
                      labelText: 'Celular',
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.62 - 55,
                  child: TextFormField(
                    controller: _apellidoAvalController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Apellidos',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _correoAvalController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Correo Electronico',
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _direccionAvalController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'El campo es requerido';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Domicilio',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPrestamo() {
    return Container(
      padding: const EdgeInsets.all(20).copyWith(
        bottom: 20,
      ),
      child: Form(
        key: _formKeyPrestamo,
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                child: AppTextFormField(
                  enabled: false,
                  controller: _codigoPrestamoController,
                  //textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.number,
                  labelText: 'Código Préstamo',
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                child: AppTextFormField(
                  enabled: false,
                  //textDirection: TextDirection.rtl,
                  controller: _fechaPrestamoController,
                  labelText: 'Fecha',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                child: AppTextFormField(
                  onChanged: (value) {
                    final monto = double.tryParse(value) ?? 0;
                    final porcentaje = _valorTasaPrestamo;
                    final interes = monto * porcentaje / 100;
                    final total = monto + interes;
                    setState(() {
                      _montoPagarPrestamo = total;
                      _gananciaPrestamo = interes;
                    });
                  },
                  //autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'El campo es requerido';
                    }
                    return null;
                  },
                  controller: _montoPrestamoController,
                  //textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.number,
                  /*  decoration: const InputDecoration(
                    prefix: Text('S/.'),
                    labelText: 'Monto a prestar',
                  ), */
                  preffix: const Text('S/. '),
                  labelText: 'Monto a prestar',
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                child: AppTextFormField(
                  //autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'El campo es requerido';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      fechaPago = now.add(
                        Duration(
                            days: int.parse(value == '' ? '0' : value) - 1),
                      );
                    });
                    _fechaPagoPrestamoController.text =
                        DateFormat('dd/MM/yyyy').format(fechaPago);
                  },
                  controller: _plazosPrestamoController,
                  //textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.number,
                  labelText: 'Plazos',
                  suffix: const Text('Dia(s)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                child: AppDropdownButtonFormField<double?>(
                  value: _valorTasaPrestamo == 0 ? null : _valorTasaPrestamo,
                  //autovalidateMode: AutovalidateMode.onUserInteraction,
                  /* validator: (value) {
                    if (value == null) {
                      return 'El campo es requerido';
                    }
                    return null;
                  }, */
                  /* decoration: const InputDecoration(
                    labelText: 'Tasa de Interes',
                  ), */
                  labelText: 'Tasa de Interés',
                  items: intereses
                      .map((e) => DropdownMenuItem<double?>(
                            value: double.parse(e.intereses),
                            child: Text("${e.intereses} %"),
                          ))
                      .toList(),
                  onChanged: (value) {
                    final monto =
                        double.tryParse(_montoPrestamoController.text) ?? 0;
                    final porcentaje = double.parse(value.toString());
                    final interes = monto * porcentaje / 100;
                    final total = monto + interes;
                    setState(() {
                      _valorTasaPrestamo = porcentaje;
                      _montoPagarPrestamo = total;
                      _gananciaPrestamo = interes;
                    });
                  },
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                child: AppTextFormField(
                  enabled: false,
                  controller: _fechaPagoPrestamoController,
                  //textDirection: TextDirection.rtl,
                  labelText: 'Fecha de Pago',
                  /* decoration: const InputDecoration(
                    labelText: 'Fecha de Pago',
                  ), */
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          AppTextFormField(
            /*  minLines: 1,
            maxLines: 8, */
            controller: _observacionesPrestamoController,
            /*  decoration: const InputDecoration(
              labelText: 'Observaciones',
            ), */
            labelText: 'Observaciones',
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            // textDirection: TextDirection.ltr,
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  'Ganancia:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('S/. ${oCcy.format(_gananciaPrestamo)}'),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            //textDirection: TextDirection!.LTR!,
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  'Total a pagar:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('S/. ${oCcy.format(_montoPagarPrestamo)}'),
                ),
              )
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildFormGarantia(
      Key formKeyGarantia,
      descripcionGarantiaController,
      marcaGarantiaController,
      modeloGarantiaController,
      serieGarantiaController,
      observacionesGarantiaController,
      valorGarantiaController,
      colorGarantiaController,
      estadoGarantia,
      int index,
      List<Map<String, dynamic>> garantia) {
    return Container(
      width: 300,
      height: 300,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKeyGarantia,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // const SizedBox(width: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BIEN ${index + 1} EN GARANTIA',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: descripcionGarantiaController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'El campo es requerido';
                }
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Descripción',
              ),
            ),
            const Divider(height: 15),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                  child: TextFormField(
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    controller: marcaGarantiaController,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                  child: TextFormField(
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    controller: modeloGarantiaController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                  child: TextFormField(
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    controller: colorGarantiaController,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.50 - 27.5,
                  child: DropdownButtonFormField(
                    value: estadoGarantia,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'nuevo',
                        child: Center(child: Text('Nuevo')),
                      ),
                      DropdownMenuItem(
                        value: 'bueno',
                        child: Center(child: Text('Bueno')),
                      ),
                      DropdownMenuItem(
                        value: 'regular',
                        child: Center(child: Text('Regular')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        garantia[index]['estado'] = value.toString();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: serieGarantiaController,
              decoration: const InputDecoration(
                labelText: 'Serie',
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              maxLines: 8,
              minLines: 1,
              controller: observacionesGarantiaController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: valorGarantiaController,
              //textDirection: TextDirection.ltr,
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                prefix: Text('S/. '),
                labelText: 'Precio Referencial',
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                garantia[index]['imagen'] != null
                    ? garantia[index]['imagen'].contains('files/garantias')
                        ? Image.network(
                            '$endPoint/${garantia[index]['imagen']}',
                            width: 100,
                            height: 100,
                          )
                        : Image.file(
                            File(garantia[index]['imagen']),
                            width: 100,
                            height: 100,
                          )
                    : const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: () async {
                    final XFile? photo = await _cargarImagen();
                    if (photo != null) {
                      setState(() {
                        garantia[index]['imagen'] = photo.path;
                      });
                    }
                  },
                  child: garantia[index]['imagen'] != null
                      ? const Text('Cambiar Imagen')
                      : const Text('Cargar Imagen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<XFile?> _cargarImagen() async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    return photo;
  }
}
