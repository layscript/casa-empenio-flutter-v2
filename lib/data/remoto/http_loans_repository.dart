import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HttpLoansRepository implements LoansRepository {
  const HttpLoansRepository({
    required Dio dio,
    required CustomerRepository customerRepository,
    required SentryClient sentry,
  })  : _sentry = sentry,
        _dio = dio,
        _customerRepository = customerRepository;

  final Dio _dio;
  final CustomerRepository _customerRepository;
  final SentryClient _sentry;

  @override
  Future<Either<String, int>> getLastCode() async {
    const path = '/prestamos/prestamos/ultimoCodigo';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final code = map['body'] as int;
        return Right(code);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, LoansEntity>> getLoan({
    required int id,
    required int? userId,
  }) async {
    final path = '/prestamos/prestamos/$id';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        if (userId != null) {
          await _customerRepository.createHistory(
            accion: 'VISUALIZAR',
            detalle: 'ver detalle del prestamo con el codigo: $id',
            usuarioId: userId,
          );
        }

        if (map['body'] == null) {
          return const Left('No hay información registrada');
        } else {
          return Right(LoansEntity.getLoanFromMap(map['body']));
        }
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, List<LoansEntity>>> getLoans({
    required String? criterio,
    required int sucursal,
    required int? userId,
    String? categoria,
  }) async {
    const path = '/prestamos/prestamos/criterio';
    final payload = {
      'criterio': criterio != null
          ? criterio.isEmpty
              ? null
              : criterio
          : null,
      'sucursal': sucursal,
      'categoria': categoria,
    };

    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'];
        if (userId != null) {
          await _customerRepository.createHistory(
            accion: 'BUSQUEDA',
            detalle: 'busqueda en prestamos con el criterio: $criterio',
            usuarioId: userId,
          );
        }
        return Right(LoansEntity.listGetSalesDetailFromMap(body));
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, ContratoEntity>> saveLoan({
    required int plazoDias,
    required double interes,
    required DateTime fechaPago,
    required double monto,
    required String observaciones,
    required CustomerEntity cliente,
    required CustomerEntity? aval,
    required List<Map<String, dynamic>> bienes,
    required String usuarioId,
    required bool renew,
    required int? cajaId,
    required int? sucursalId,
  }) async {
    const path = '/prestamos/prestamos';

    final endDateTime = DateTime(
      fechaPago.year,
      fechaPago.month,
      fechaPago.day,
      23,
      59,
      59,
    );

    final payload = {
      'plazoDias': plazoDias,
      'interes': interes,
      'fechaPago': endDateTime.toIso8601String(),
      'monto': monto,
      'observaciones': observaciones,
      'cliente': {
        'nombres': cliente.nombres,
        'apellidos': cliente.apellidos,
        'dni': cliente.dni,
        'celular': cliente.celular,
        'email': cliente.email,
        'domicilio': cliente.domicilio,
      },
      'aval': aval == null
          ? null
          : {
              'nombres': aval.nombres,
              'apellidos': aval.apellidos,
              'dni': aval.dni,
              'celular': aval.celular,
              'email': aval.email,
              'domicilio': aval.domicilio,
            },
      'bienesGarantia': bienes,
      'usuarioId': usuarioId,
      'isRenewed': renew,
      'cajaId': cajaId,
      'sucursalId': sucursalId,
    };

    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        // Crear historial
        await _customerRepository.createHistory(
          accion: 'CREAR',
          detalle:
              'crear prestamo con el codigo: ${json.decode(response.data!)['body']['codigo']}',
          usuarioId: int.parse(usuarioId),
        );

        final map = json.decode(response.data!) as Map<String, dynamic>;
        final bienesResponse = map['body']['bienesGarantia'] as List<dynamic>?;

        if (cliente.imagenUno != null) {
          await updateCustomerPhotos(
            dni: int.parse(cliente.dni ?? '0'),
            imagen: cliente.imagenUno!,
            imagen2: cliente.imagenDos,
          );
        }

        if (aval != null && aval.imagenUno != null) {
          await updateCustomerPhotos(
            dni: int.parse(aval.dni ?? '0'),
            imagen: aval.imagenUno!,
            imagen2: aval.imagenDos,
          );
        }

        if (bienesResponse != null) {
          for (var bienResponse in bienesResponse) {
            final imagenUno = bienResponse['imagen'] as String?;
            if (imagenUno != null) {
              final imagenDos = bienResponse['imagen2'] as String?;
              final imagenTres = bienResponse['imagen3'] as String?;

              await updateWarrantyPhotos(
                idGarantia: bienResponse['id'],
                imagen: imagenUno!,
                imagen2: imagenDos,
                imagen3: imagenTres,
              );
            }
          }
        }

        final prendas = bienes
            .map(
              (e) => PrendaEntity(
                nombre: e['descripcion'],
                marca: e['marca'],
                modelo: e['modelo'],
                serie: e['serie'],
                color: e['color'],
                estado: e['estado'],
              ),
            )
            .toList();

        final contrato = ContratoEntity(
          interes: interes,
          numero: json.decode(response.data!)['body']['codigo'],
          nombre: '${cliente.nombres} ${cliente.apellidos}',
          dni: cliente.dni ?? '',
          domicilio: cliente.domicilio ?? '',
          fechaVencimiento: endDateTime,
          monto: monto,
          montoPagar: monto + (monto * interes / 100),
          prendas: prendas,
          nombreAval: aval == null
              ? ''
              : '${aval.nombres ?? ''} ${aval.apellidos ?? ''}',
          dniAval: aval == null ? '' : aval.dni ?? '',
        );

        return Right(contrato);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<bool> savePayment({
    required int codigo,
    required double monto,
    required String userId,
    //required List<XFile>? photos,
    required String url,
    required bool? efectivo,
    required int? cajaId,
    bool isLiquidacion = false,
  }) async {
    const path = '/prestamos/pagos';
    final payload = {
      'monto': monto,
      'prestamoId': codigo,
      'usuarioId': userId,
      'cajaId': cajaId,
      'isLiquidacion': isLiquidacion,
      'url': url,
    };

    if (efectivo != null) {
      payload['efectivo'] = efectivo;
    }
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        await _customerRepository.createHistory(
          accion: 'PAGAR',
          detalle: 'realizar el pago del prestamo del codigo: $codigo',
          usuarioId: int.parse(userId),
        );
        return true;
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        //return Left(message);
        return false;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      return false;
    }
  }

  @override
  Future<bool> addAmountLoan({
    required int codigo,
    required double monto,
    required String observaciones,
    required String userId,
    required String url,
  }) async {
    const path = '/prestamos/prestamos/aumentarMonto';
    final payload = {
      'monto': monto,
      'prestamoId': codigo,
      'observaciones': observaciones,
      'usuarioId': userId,
      'url': url,
    };
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return false;
      } else {
        await _customerRepository.createHistory(
          accion: 'AGREGAR MONTO',
          detalle: 'Agregar monto del prestamo del codigo: $codigo',
          usuarioId: int.parse(userId),
        );
        return true;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      return false;
    }
  }

  @override
  Future<Uint8List> createInvoicePdf({required String url}) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: downloadFactura));
      final path = url;
      final response = await dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data!);
      } else {
        return Uint8List(0);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return Uint8List(0);
    }
  }

  @override
  Future<void> createLoanNote({required String id}) async {
    const path = '/facturacion/facturacion/nota/empenio';
    final payload = {'prestamoId': id};
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        /*  return false; */
        //return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
        /* return true; */
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      /* return false; */
    }
  }

  @override
  Future<void> createSalesNote({required String id}) async {
    const path = '/facturacion/facturacion/nota/venta';
    final payload = {'ventaId': id};
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        /*  return false; */
        //return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
        /* return true; */
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      /* return false; */
    }
  }

  @override
  Future<bool> createInvoceLoans({
    required String dni,
    required String fullName,
    required String? direccion,
    required int idPrestamo,
    required String userId,
  }) async {
    final payload = {
      'dni': dni,
      'nombreCompleto': fullName,
      'direccion': direccion,
      'prestamoId': idPrestamo,
    };

    const path = '/facturacion/facturacion/';

    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return false;
      } else {
        await _customerRepository.createHistory(
          accion: 'GENERAR BOLETA',
          detalle:
              'Generar boleta electrónica del prestamo del codigo: $idPrestamo',
          usuarioId: int.parse(userId),
        );
        return true;
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
        /* return true; */
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return false;
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      /* return false; */
    }
  }

  @override
  Future<Either<String, ReportsPaymentEntity>> getPayments({
    required int id,
  }) async {
    final path = '/prestamos/pagos/$id';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'];
        return Right(ReportsPaymentEntity.getReportsPaymentFromMap(body));
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> deletePayment({
    required int id,
    required int userId,
  }) async {
    final path = '/prestamos/pagos/eliminar/$id';
    final payload = {
      'usuarioId': userId,
    };

    try {
      final response = await _dio.put<String>(
        path,
        data: payload,
      );
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        /*  final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body']; */
        return const Right(true);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<bool> payOffLoan({
    required int id,
    required int idPrestamo,
    required String userId,
  }) async {
    final path = '/prestamos/prestamos/liquidar/$id';

    try {
      final response = await _dio.put<String>(path);
      if (response.statusCode == 201 || response.statusCode == 200) {
        await _customerRepository.createHistory(
          accion: 'LIQUIDAR',
          detalle:
              'realizar la liquidacion del prestamo del codigo: $idPrestamo',
          usuarioId: int.parse(userId),
        );

        return true;
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        //return Left(message);
        return false;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      return false;
    }
  }

  @override
  Future<Either<String, String>> createImagePagos({
    required String path,
  }) async {
    final img = File(path);
    try {
      const path = '/prestamos/prestamos/imagenPagos';
      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          img.path,
          filename: img.path.split('/').last,
        )
      });

      final response = await _dio.put(path, data: formData);
      if (response.statusCode == 200) {
        final body = response.data['body']['imagenPagos'] as String;
        return Right(body);
      } else {
        return const Left('No se pudo grabar la imagen');
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> createImageAumentos({
    required String path,
  }) async {
    final img = File(path);
    try {
      const path = '/prestamos/prestamos/imagenAumentos';
      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          img.path,
          filename: img.path.split('/').last,
        )
      });

      final response = await _dio.put(path, data: formData);
      if (response.statusCode == 200) {
        final body = response.data['body']['imagenAumentos'] as String;
        return Right(body);
      } else {
        return const Left('No se pudo grabar la imagen');
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return Left(e.toString());
    }
  }

// TODO:: Probar Aca 2

  Future<bool> updateCustomerPhotos({
    required int dni,
    required String? imagen,
    required String? imagen2,
  }) async {
    try {
      FormData formData = FormData();
      if (imagen != null && !imagen.contains('files/')) {
        final img = File(imagen);
        formData.files.add(MapEntry(
            'imagen',
            await MultipartFile.fromFile(
              img.path,
              filename: img.path.split('/').last,
            )));
      }
      if (imagen2 != null && !imagen2.contains('files/')) {
        final img2 = File(imagen2);
        formData.files.add(MapEntry(
            'imagen2',
            await MultipartFile.fromFile(
              img2.path,
              filename: img2.path.split('/').last,
            )));
      }
      if (formData.files.isNotEmpty) {
        final path = '/clientes/clientes/imagenCliente/$dni';
        final response = await _dio.put(path, data: formData);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        } else {
          return false;
        }
      } else {
        return true;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> updateWarrantyPhotos({
    required String? imagen,
    required String? imagen2,
    required String? imagen3,
    required int idGarantia,
  }) async {
    final data = {
      'imagen': imagen,
      'imagen2': imagen2,
      'imagen3': imagen3,
      'id': idGarantia,
    };

    try {
      FormData formData = FormData();
      if (imagen != null && !imagen.contains('files/')) {
        final img = File(imagen);
        formData.files.add(MapEntry(
            'imagen',
            await MultipartFile.fromFile(
              img.path,
              filename: img.path.split('/').last,
            )));
      }
      if (imagen2 != null && !imagen2.contains('files/')) {
        final img2 = File(imagen2);
        formData.files.add(MapEntry(
            'imagen2',
            await MultipartFile.fromFile(
              img2.path,
              filename: img2.path.split('/').last,
            )));
      }
      if (imagen3 != null && !imagen3.contains('files/')) {
        final img3 = File(imagen3);
        formData.files.add(MapEntry(
            'imagen3',
            await MultipartFile.fromFile(
              img3.path,
              filename: img3.path.split('/').last,
            )));
      }
      if (formData.files.isNotEmpty) {
        final path = '/prestamos/prestamos/imagenGarantia/$idGarantia';
        final response = await _dio.put(path, data: formData);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        } else {
          return false;
        }
      } else {
        return true;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  /*  Future<bool> updateWarrantyPhotos({
    required int idGarantia,
    required String imagen,
    required String? imagen2,
    required String? imagen3,
  }) async {
    final imgUno = File(imagen);
    File? imgDos;
    File? imgTres;

    if (imagen2 != null && imagen2.isNotEmpty) {
      imgDos = File(imagen2);
    }
    if (imagen3 != null && imagen3.isNotEmpty) {
      imgTres = File(imagen3);
    }

    try {
      final path = '/prestamos/prestamos/imagenGarantia/$idGarantia';

      FormData formData = FormData.fromMap({
        if (!imgUno.path.contains('files'))
          'imagen': await MultipartFile.fromFile(
            imgUno.path,
            filename: imgUno.path.split('/').last,
          ),
        if (imgDos != null && !imgDos.path.contains('/files'))
          'imagen2': await MultipartFile.fromFile(
            imgDos.path,
            filename: imgDos.path.split('/').last,
          ),
        if (imgTres != null && !imgTres.path.contains('/files'))
          'imagen3': await MultipartFile.fromFile(
            imgTres.path,
            filename: imgTres.path.split('/').last,
          ),
      });

      final response = await _dio.put(path, data: formData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
 */
  @override
  Future<Either<String, bool>> updateLoan({
    required int plazoDias,
    required double interes,
    required DateTime fechaPago,
    required double monto,
    required String observaciones,
    required CustomerEntity cliente,
    required CustomerEntity? aval,
    required List<Map<String, dynamic>> bienes,
    required String usuarioId,
    required int idLoan,
    required int? cajaId,
    required int? sucursalId,
  }) async {
    final path = '/prestamos/prestamos/$idLoan';

    final payload = {
      'plazoDias': plazoDias,
      'interes': interes,
      'fechaPago': fechaPago.toIso8601String(),
      'monto': monto,
      'observaciones': observaciones,
      'cliente': {
        'nombres': cliente.nombres,
        'apellidos': cliente.apellidos,
        'dni': cliente.dni,
        'celular': cliente.celular,
        'email': cliente.email,
        'domicilio': cliente.domicilio,
      },
      'aval': aval == null
          ? null
          : {
              'nombres': aval.nombres,
              'apellidos': aval.apellidos,
              'dni': aval.dni,
              'celular': aval.celular,
              'email': aval.email,
              'domicilio': aval.domicilio,
            },
      'bienesGarantia': bienes,
      'adminId': usuarioId,
      'isRenewed': false,
      'cajaId': cajaId,
      'sucursalId': sucursalId,
    };

    try {
      final response = await _dio.put<String>(path, data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        await _customerRepository.createHistory(
          accion: 'ACTUALIZAR',
          detalle: 'actualizar prestamo del codigo: $idLoan',
          usuarioId: int.parse(usuarioId),
        );

        final bienesResponse = map['body']['bienesGarantia'] as List<dynamic>?;

        if (cliente.imagenUno != null) {
          await updateCustomerPhotos(
            dni: int.parse(cliente.dni ?? '0'),
            imagen: cliente.imagenUno!,
            imagen2: cliente.imagenDos,
          );
        }

        if (aval != null && aval.imagenUno != null) {
          await updateCustomerPhotos(
            dni: int.parse(aval.dni ?? '0'),
            imagen: aval.imagenUno!,
            imagen2: aval.imagenDos,
          );
        }

        if (bienesResponse != null) {
          for (var bienResponse in bienesResponse) {
            final imagenUno = bienResponse['imagen'] as String?;
            final imagenDos = bienResponse['imagen2'] as String?;
            final imagenTres = bienResponse['imagen3'] as String?;

            final mapa = {
              'idGarantia': bienResponse['id'],
              'imagen': imagenUno,
              'imagen2': imagenDos,
              'imagen3': imagenTres,
            };

            final exito = await updateWarrantyPhotos(
              idGarantia: bienResponse['id'],
              imagen: imagenUno,
              imagen2: imagenDos,
              imagen3: imagenTres,
            );

            if (!exito) {
              return const Left(
                'Ocurrió un problema con las imágenes de la garantía',
              );
            }
          }
        }

        return const Right(true);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, bool>> deleteLoan({
    required int idLoan,
    required String userId,
  }) async {
    final path = '/prestamos/prestamos/$idLoan/$userId';
    try {
      final response = await _dio.delete<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        await _customerRepository.createHistory(
          accion: 'ELIMINAR',
          detalle: 'eliminar el prestamo con el codigo: $idLoan',
          usuarioId: int.parse(userId),
        );
        return const Right(true);
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return Left(e.toString());
    }
  }

  @override
  Future<bool> anularLoan({
    required int idLoan,
    required String userId,
  }) async {
    final path = '/prestamos/prestamos/anularPrestamo/$idLoan';
    try {
      final response = await _dio.put<String>(path);
      if (response.statusCode == 201 || response.statusCode == 200) {
        await _customerRepository.createHistory(
          accion: 'ANULAR',
          detalle: 'anular el prestamo con el codigo: $idLoan',
          usuarioId: int.parse(userId),
        );
        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      //print('responseee ee: $e');
      return false;
    }
  }

  @override
  Future<bool> updateStatusLoan({
    required int idLoan,
    required String value,
  }) async {
    final path = '/prestamos/prestamos/cambiar-estado/$idLoan';
    final payload = {
      'estado': value,
    };

    try {
      final response = await _dio.put<String>(path, data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      await _sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
