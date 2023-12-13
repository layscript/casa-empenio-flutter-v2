import 'dart:developer';
import 'dart:io';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/error_snackbar.dart';
import 'package:casa_empenio_pe/presentation/app/utils/overlay_loader.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/auth/auth.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/blocs/loans_bloc/loans_bloc.dart';
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
  List<XFile>? selectedPhotosClient = [];
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
  List<XFile>? selectedPhotosAval = [];
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
  CategoriesEntity? categories;
  DateTime fechaPago = DateTime.now();

  int garantias = 1;
  // CONTROLLERS GARANTIA
  List<XFile>? selectedPhotosWarranty = [];
  final List<Map<String, dynamic>> _garantiasControllers = [];

  bool _isLoadingDni = false;
  bool _isAval = false;
  bool isValidCategories = false;
  DateTime now = DateTime.now();
  List<InterestsEntity> intereses = [];
  List<CategoriesEntity> listCategories = [];

  @override
  void initState() {
    super.initState();
    _getPrestamo();
    _getIntereses();
    _getCategories();
  }

  void getPhotosClient(String? imagenUno, String? imagenDos) {
    List<XFile> photos = [];
    if (imagenUno != null && imagenUno != '') {
      final path = XFile(imagenUno);
      photos.add(path);
    }

    if (imagenDos != null && imagenDos != '') {
      final path = XFile(imagenDos);
      photos.add(path);
    }

    selectedPhotosClient = photos;
  }

  void getPhotosAval(String? imagenUno, String? imagenDos) {
    List<XFile> photos = [];
    if (imagenUno != null && imagenUno != '') {
      final path = XFile(imagenUno);
      photos.add(path);
    }

    if (imagenDos != null && imagenDos != '') {
      final path = XFile(imagenDos);
      photos.add(path);
    }

    selectedPhotosAval = photos;
  }

  void getPhotosWarranty(
    String? imagenUno,
    String? imagenDos,
    String? imagenTres,
  ) {
    List<XFile> photos = [];
    if (imagenUno != null && imagenUno != '') {
      final path = XFile(imagenUno);
      photos.add(path);
    }

    if (imagenDos != null && imagenDos != '') {
      final path = XFile(imagenDos);
      photos.add(path);
    }

    if (imagenTres != null && imagenTres != '') {
      final path = XFile(imagenTres);
      photos.add(path);
    }

    selectedPhotosWarranty = photos;
  }

  Future<void> _getPrestamo() async {
    final pres = await context.read<LoansRepository>().getLoan(
          id: widget.idPrestamo,
        );
    if (mounted) {
      setState(() {
        pres.fold((error) => null, (prestamo) {
          log('dododododmi 1: ${prestamo.cliente?.toString()}');
          log('dododododmi 2: ${prestamo.aval}');

          _nombreClienteController.text = prestamo.cliente?.nombres ?? '';
          _apellidoClienteController.text = prestamo.cliente?.apellidos ?? '';
          _dniClienteController.text = prestamo.cliente?.dni ?? '';
          _celularClienteController.text = prestamo.cliente?.celular ?? '';
          _direccionClienteController.text = prestamo.cliente?.domicilio ?? '';
          _correoClienteController.text = prestamo.cliente?.email ?? '';
          getPhotosClient(
            prestamo.cliente?.imagenUno,
            prestamo.cliente?.imagenDos,
          );

          _isAval = prestamo.aval != null &&
              (prestamo.aval?.dni != null && prestamo.aval?.dni != '');
/* 
          print('_isAval 1: ${_isAval}');
          print('_isAval 2: ${prestamo.aval?.dni != null}');
          print('_isAval 3: ${prestamo.aval?.dni != ''}'); */

          if (_isAval) {
            _nombreAvalController.text = prestamo.aval?.nombres ?? '';
            _apellidoAvalController.text = prestamo.aval?.apellidos ?? '';
            _dniAvalController.text = prestamo.aval?.dni ?? '';
            _celularAvalController.text = prestamo.aval?.celular ?? '';
            _direccionAvalController.text = prestamo.aval?.domicilio ?? '';
            _correoAvalController.text = prestamo.aval?.email ?? '';
            getPhotosAval(
              prestamo.aval?.imagenUno,
              prestamo.aval?.imagenDos,
            );
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
              'categoria': garantia.categoria,
              'placa': TextEditingController(text: garantia.placa ?? ''),
              'imagen': garantia.imagen,
              'imagen2': garantia.imagenDos,
              'imagen3': garantia.imagenTres,
            });

            getPhotosWarranty(
              garantia.imagen,
              garantia.imagenDos,
              garantia.imagenTres,
            );
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

  Future<void> _getCategories() async {
    final response = await context.read<CategoriesRepository>().getCategories();
    if (mounted) {
      response.fold(
        (error) => null,
        (categories) {
          listCategories = categories;
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

  void _validarData() {
    _formKeyPrestamo.currentState?.validate();
    _formKeyCliente.currentState?.validate();
    _formKeyAval.currentState?.validate();
    _formKeyGarantia.currentState?.validate();

    bool valido = true;
    for (var element in _garantiasControllers) {
      element['keyForm']?.currentState?.validate();
      if (element['descripcion'].text == '' ||
          element['estado'] == '' ||
          element['marca'].text == '' ||
          element['modelo'].text == '' ||
          element['categoria'] == '' ||
          element['color'].text == '') {
        valido = false;
      }
    }

    if (_nombreClienteController.text != '' &&
        _apellidoClienteController.text != '' &&
        _dniClienteController.text != '' &&
        _celularClienteController.text != '' &&
        _direccionClienteController.text != '' &&
        _codigoPrestamoController.text != '' &&
        _fechaPrestamoController.text != '' &&
        _valorTasaPrestamo != 0 &&
        _plazosPrestamoController.text != '' &&
        _fechaPagoPrestamoController.text != '' &&
        _montoPrestamoController.text != '' &&
        _montoPagarPrestamo != 0 &&
        //selectedPhotosClient?.length == 2 &&
        valido) {
      if (_isAval) {
        if (_nombreAvalController.text != '' &&
            _apellidoAvalController.text != '' &&
            _dniAvalController.text != '' &&
            _celularAvalController.text != '' &&
            //selectedPhotosAval?.length == 2 &&
            _direccionAvalController.text != '') {
          return showDialogGuardar();
        } else {
          return showDialogMensaje(
            'Datos Faltantes',
            'Por favor complete todos los campos',
            context,
          );
        }
      }
      return showDialogGuardar();
    } else {
      return showDialogMensaje(
        'Datos Faltantes',
        'Por favor complete todos los campos',
        context,
      );
    }
  }

  void showDialogMensaje(String titulo, String? mensaje, context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: mensaje != null ? Text(mensaje) : null,
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<String> keys = ['imagen', 'imagen2', 'imagen3'];

  Future<void> _seleccionarNuevaImagen(int index, String key) async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (photo != null) {
      setState(() {
        _garantiasControllers[index][key] = photo.path;
      });
    }
  }

  void _eliminarImagen(int index, String key) {
    setState(() {
      _garantiasControllers[index][key] = null;
    });
  }

  void showDialogGuardar() {
    final authUser = context.read<Preferences>().token;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Guardar Préstamo'),
          content: const Text(
            '¿Esta seguro que desea guardar los cambios?',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.normal,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Regresar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                final garantiasData = _garantiasControllers.map((e) {
                  print('imageeen 1: ${e['imagen']}');
                  return {
                    'descripcion': e['descripcion'].text,
                    'marca': e['marca'].text,
                    'modelo': e['modelo'].text,
                    'color': e['color'].text,
                    'serie': e['serie'].text,
                    'valorizacion': double.parse(
                        e['valor'].text == '' ? '0' : e['valor'].text),
                    'observaciones': e['observaciones'].text,
                    'estado': e['estado'],
                    'placa': e['placa'].text,
                    'categoria': e['categoria'],
                    // TODO:: Revisar bien el cambio
                    'imagen': e['imagen'],
                    'imagen2': e['imagen2'],
                    'imagen3': e['imagen3'],
                  };
                }).toList();

                context.read<LoansBloc>().add(
                      UpdateAllLoan(
                        isNuevo: widget.isNuevo,
                        userId: authUser!.id.toString(),
                        plazoDias: int.parse(_plazosPrestamoController.text),
                        interes: _valorTasaPrestamo,
                        fechaPago: fechaPago,
                        monto: double.parse(_montoPrestamoController.text),
                        observaciones: _observacionesPrestamoController.text,
                        cliente: CustomerEntity(
                          dni: _dniClienteController.text,
                          nombres: _nombreClienteController.text,
                          apellidos: _apellidoClienteController.text,
                          domicilio: _direccionClienteController.text,
                          email: _correoClienteController.text,
                          celular: _celularClienteController.text,
                          prestamos: null,
                          prestamosAval: null,
                          pagos: null,
                          imagenUno: selectedPhotosClient!.isEmpty ||
                                  selectedPhotosClient!.length == 0
                              ? null
                              : selectedPhotosClient?[0].path,
                          imagenDos: selectedPhotosClient!.isEmpty ||
                                  selectedPhotosClient!.length == 1
                              ? null
                              : selectedPhotosClient?[1].path,
                          ventas: null,
                          updatedAt: '',
                          createdAt: '',
                        ),
                        aval: CustomerEntity(
                          dni: _dniAvalController.text,
                          nombres: _nombreAvalController.text,
                          apellidos: _apellidoAvalController.text,
                          domicilio: _direccionAvalController.text,
                          email: _correoAvalController.text,
                          celular: _celularAvalController.text,
                          prestamos: null,
                          prestamosAval: null,
                          pagos: null,
                          imagenUno: selectedPhotosAval!.isEmpty ||
                                  selectedPhotosAval!.length == 0
                              ? null
                              : selectedPhotosAval?[0].path,
                          imagenDos: selectedPhotosAval!.isEmpty ||
                                  selectedPhotosAval!.length == 1
                              ? null
                              : selectedPhotosAval?[1].path,
                          ventas: null,
                          updatedAt: '',
                          createdAt: '',
                        ),
                        bienes: garantiasData,
                        codigo: widget.idPrestamo,
                      ),
                    );
              },
            ),
          ],
        );
      },
    );
  }

  CategoriesEntity? parseCategorie(String value) {
    print('valoooor: ${value}');
    if (value.isEmpty) return null;

    final response =
        listCategories.firstWhere((element) => element.descripcion == value);

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoansBloc, LoansState>(
      listener: (context, state) {
        if (state.isLoansRenevLoading) {
          print('gogogoges 1');
          OverlayLoader.show(context);
        } else {
          OverlayLoader.hide();
          if (state.isLoansRenevError) {
            print('gogogoges 2');

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: const Text(
                    'Ocurrió un problema al guardar el prestamo, intentelo de nuevo.',
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.normal),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Aceptar'),
                    ),
                  ],
                );
              },
            );
          }

          if (state.isLoansRenevSuccess) {
            print('gogogoges 3');

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Mensaje'),
                  content: const Text(
                    'Prestamo guardado correctamente',
                    style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.normal),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                      child: const Text('Aceptar'),
                    ),
                  ],
                );
              },
            );
          }
        }
      },
      child: DefaultTabController(
        length: 3,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
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
                        child: Column(
                          children: [
                            _buildFormCliente(),
                            _isAval ? _buildFormAval() : const SizedBox(),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildFormPrestamo(),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _garantiasControllers.length,
                              itemBuilder: (context, index) {
                                final garantia = _garantiasControllers[index];
                                print('sakldjldas: ${garantia['categoria']}');
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
                                    "placa": TextEditingController(),
                                    //"categoria": garantia['categoria'],
                                    "categoria": '',
                                    "imagen": '',
                                    "imagen1": '',
                                    "imagen2": '',
                                  });
                                }

                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Form(
                                    key: _garantiasControllers[index]
                                        ['keyForm'],
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
                                        AppTextFormField(
                                          controller:
                                              _garantiasControllers[index]
                                                  ['descripcion'],
                                          validator: (value) {
                                            if (value?.isEmpty ?? true) {
                                              return 'El campo es requerido';
                                            }
                                            return null;
                                          },
                                          labelText: 'Descripción',
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: AppDropdownButtonFormField<
                                                  CategoriesEntity?>(
                                                labelText: 'Categoría',
                                                value: parseCategorie(
                                                    _garantiasControllers[index]
                                                            ['categoria'] ??
                                                        ''),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _garantiasControllers[index]
                                                            ['categoria'] =
                                                        value?.descripcion
                                                            .toString();
                                                  });
                                                },
                                                items: listCategories
                                                    .map(
                                                      (e) => DropdownMenuItem<
                                                          CategoriesEntity?>(
                                                        value: e,
                                                        child: Text(
                                                          e.descripcion,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: AppTextFormField(
                                                labelText: 'Placa',
                                                controller:
                                                    _garantiasControllers[index]
                                                        ['placa'],
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
                                              child: AppTextFormField(
                                                validator: (value) {
                                                  if (value?.isEmpty ?? true) {
                                                    return 'El campo es requerido';
                                                  }
                                                  return null;
                                                },
                                                controller:
                                                    _garantiasControllers[index]
                                                        ['marca'],
                                                labelText: 'Marca',
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.50 -
                                                  27.5,
                                              child: AppTextFormField(
                                                validator: (value) {
                                                  if (value?.isEmpty ?? true) {
                                                    return 'El campo es requerido';
                                                  }
                                                  return null;
                                                },
                                                controller:
                                                    _garantiasControllers[index]
                                                        ['modelo'],
                                                labelText: 'Modelo',
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
                                              child: AppTextFormField(
                                                validator: (value) {
                                                  if (value?.isEmpty ?? true) {
                                                    return 'El campo es requerido';
                                                  }
                                                  return null;
                                                },
                                                controller:
                                                    _garantiasControllers[index]
                                                        ['color'],
                                                labelText: 'Color',
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.50 -
                                                  27.5,
                                              child: AppDropdownButtonFormField<
                                                  String?>(
                                                labelText: 'Estado',
                                                value:
                                                    _garantiasControllers[index]
                                                        ['estado'],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _garantiasControllers[index]
                                                            ['estado'] =
                                                        value.toString();
                                                  });
                                                },
                                                items: [
                                                  'nuevo',
                                                  'bueno',
                                                  'regular'
                                                ]
                                                    .map(
                                                      (e) => DropdownMenuItem<
                                                          String?>(
                                                        value: e,
                                                        child: Text(e),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        AppTextFormField(
                                          controller:
                                              _garantiasControllers[index]
                                                  ['serie'],
                                          labelText: 'Serie',
                                        ),
                                        const SizedBox(height: 15),
                                        AppTextFormField(
                                          controller:
                                              _garantiasControllers[index]
                                                  ['observaciones'],
                                          labelText: 'Observaciones',
                                        ),
                                        const SizedBox(height: 15),
                                        AppTextFormField(
                                          controller:
                                              _garantiasControllers[index]
                                                  ['valor'],
                                          keyboardType: TextInputType.number,
                                          preffix: const Text('S/. '),
                                          labelText: 'Precio Referencial',
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          children: keys.map((key) {
                                            return GestureDetector(
                                              onTap: () {
                                                _seleccionarNuevaImagen(
                                                  index,
                                                  key,
                                                );
                                              },
                                              child: Stack(
                                                children: [
                                                  if (_garantiasControllers[
                                                              index][key] !=
                                                          null &&
                                                      _garantiasControllers[
                                                              index][key] !=
                                                          '')
                                                    _garantiasControllers[index]
                                                                [key]!
                                                            .contains(
                                                                'files/garantias')
                                                        ? Expanded(
                                                            child:
                                                                Image.network(
                                                              '$endPoint/${_garantiasControllers[index][key]}',
                                                              width: 90,
                                                              height: 90,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Container(
                                                                  margin: const EdgeInsets
                                                                          .only(
                                                                      right:
                                                                          10),
                                                                  child: Image
                                                                      .asset(
                                                                    AppIcons
                                                                        .notFound,
                                                                    width: 80,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          )
                                                        : Expanded(
                                                            child: Image.file(
                                                              File(
                                                                  _garantiasControllers[
                                                                          index]
                                                                      [key]!),
                                                              width: 90,
                                                              height: 90,
                                                            ),
                                                          )
                                                  else
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                        right: 7,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      width: 85,
                                                      height: 85,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color: AppColors.blue,
                                                      ),
                                                      child: const Center(
                                                        child: Text(
                                                          'Subir Imagen',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (_garantiasControllers[
                                                              index][key] !=
                                                          null &&
                                                      _garantiasControllers[
                                                              index][key] !=
                                                          '')
                                                    Positioned(
                                                      top: 0,
                                                      right: 5,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          _eliminarImagen(
                                                              index, key);
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(2),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            color: Colors.red,
                                                          ),
                                                          child: const Icon(
                                                            Icons.close,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
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
                onPressed: () {
                  // Validar Data
                  _validarData();
                },
                child: const Icon(Icons.save),
              ),
            ),
            tabIndex == 2
                ? Positioned(
                    bottom: 100,
                    right: 20,
                    child: FloatingActionButton(
                      backgroundColor: Colors.green,
                      onPressed: () {
                        // Sumar garantias
                        setState(() {
                          garantias++;
                        });
                      },
                      child: const Icon(Icons.add_box_outlined),
                    ),
                  )
                : const SizedBox(),
            tabIndex == 2
                ? Positioned(
                    bottom: 170,
                    right: 20,
                    child: FloatingActionButton(
                      backgroundColor:
                          garantias != 1 ? Colors.red : Colors.grey,
                      onPressed: () {
                        if (garantias != 1) {
                          setState(() {
                            garantias--;
                            _garantiasControllers.removeLast();
                          });
                        }
                      },
                      child: const Icon(Icons.delete_forever_rounded),
                    ),
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }

  Widget _buildFormCliente() {
    if (selectedPhotosClient != null) {
      for (var element in selectedPhotosClient!) {
        print('asdasd1: ${element.path}');
      }
    }

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
            const SizedBox(height: 15),
            Row(
              children: [
                for (int i = 0; i < (selectedPhotosClient?.length ?? 0); i++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPhotosClient?.removeAt(i);
                      });
                    },
                    child: Stack(
                      children: [
                        if (selectedPhotosClient!.isNotEmpty &&
                            selectedPhotosClient![i].path.contains('files'))
                          Image.network(
                            '$endPoint/${selectedPhotosClient?[i].path}',
                            width: 70,
                            height: 70,
                          ),
                        if (selectedPhotosClient!.isNotEmpty &&
                            selectedPhotosClient![i].path.contains('/data'))
                          Image.file(
                            File(selectedPhotosClient![i].path),
                            width: 70,
                            height: 70,
                          ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.red,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (selectedPhotosClient!.length < 2)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final photo = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          imageQuality: 70,
                        );

                        if (photo != null) {
                          setState(() {
                            selectedPhotosClient?.add(photo);
                          });
                        }
                      },
                      child: Text(
                        'Cargar Imagen (${2 - selectedPhotosClient!.length})',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  child: AppTextFormField(
                    enabled: !_isLoadingDni,
                    controller: _dniAvalController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.length != 8) {
                        return 'Ingrese un valor correcto';
                      }
                      return null;
                    },
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
                        _getCliente(value, 'aval');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.62 - 55,
                  child: AppTextFormField(
                    controller: _nombreAvalController,
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
                    controller: _celularAvalController,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El campo es requerido';
                      }
                      return null;
                    },
                    labelText: 'Celular',
                    preffix: const Text('+51'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.62 - 55,
                  child: AppTextFormField(
                    controller: _apellidoAvalController,
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
              controller: _correoAvalController,
              labelText: 'Correo Electronico',
            ),
            const SizedBox(height: 15),
            AppTextFormField(
              controller: _direccionAvalController,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'El campo es requerido';
                }
                return null;
              },
              labelText: 'Domicilio',
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                for (int i = 0; i < (selectedPhotosAval?.length ?? 0); i++)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPhotosAval?.removeAt(i);
                      });
                    },
                    child: Stack(
                      children: [
                        if (selectedPhotosAval!.isNotEmpty &&
                            selectedPhotosAval![i].path.contains('files'))
                          Image.network(
                            '$endPoint/${selectedPhotosAval?[i].path}',
                            width: 70,
                            height: 70,
                          ),
                        if (selectedPhotosAval!.isNotEmpty &&
                            selectedPhotosAval![i].path.contains('/data'))
                          Image.file(
                            File(selectedPhotosAval![i].path),
                            width: 70,
                            height: 70,
                          ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.red,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (selectedPhotosAval!.length < 2)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final photo = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          imageQuality: 70,
                        );

                        if (photo != null) {
                          setState(() {
                            selectedPhotosAval?.add(photo);
                          });
                        }
                      },
                      child: Text(
                        'Cargar Imagen (${2 - selectedPhotosAval!.length})',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
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
              Expanded(
                child: Text('S/. ${oCcy.format(_gananciaPrestamo)}'),
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
              Expanded(
                child: Text('S/. ${oCcy.format(_montoPagarPrestamo)}'),
              )
            ],
          ),
        ]),
      ),
    );
  }

  Future<XFile?> _cargarImagen() async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    return photo;
  }
}
