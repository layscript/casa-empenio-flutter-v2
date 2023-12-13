import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class HttpLoansRepository implements LoansRepository {
  const HttpLoansRepository({
    required Dio dio,
  }) : _dio = dio;

  final Dio _dio;

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
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, LoansEntity>> getLoan({required int id}) async {
    final path = '/prestamos/prestamos/$id';
    try {
      final response = await _dio.get<String>(path);

      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        return Right(LoansEntity.getLoanFromMap(map['body']));
      }
    } catch (e) {
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<Either<String, List<LoansEntity>>> getLoans({
    required String criterio,
  }) async {
    final path = '/prestamos/prestamos/criterio/$criterio';
    try {
      final response = await _dio.get<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final body = map['body'];
        return Right(LoansEntity.listGetSalesDetailFromMap(body));
      }
    } catch (e) {
      print('skjladajlsdkjlasaljksd: ${e}');
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
    };

    log('payladolada 1: $payload');
    log('payladolada 2: $bienes');

    try {
      final response = await _dio.post<String>(path, data: payload);
      log('statttuututus code 1: ${response.statusCode}');
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return Left(message);
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        log('statttuututus code 2: ${map}');
        final bienesResponse = map['body']['bienesGarantia'] as List<dynamic>?;
        log('statttuututus code 3_1: ${bienesResponse}');
        log('statttuututus code 3_2: ${bienes}');

        log('debugggg aui 1.1.1: ${cliente?.imagenUno}');
        log('debugggg aui 1.1.2: ${cliente?.imagenDos}');
        if (cliente.imagenUno != null) {
          log('debugggg aui 1.1.3: ${cliente.imagenUno}');
          log('debugggg aui 1.1.4: ${cliente.imagenDos}');
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

        log('debugggg aui 1.2');

        if (bienesResponse != null) {
          log('debugggg aui 1.3');
          for (var bienResponse in bienesResponse) {
            final imagenUno = bienResponse['imagen'] as String?;
            final imagenDos = bienResponse['imagen2'] as String?;
            final imagenTres = bienResponse['imagen3'] as String?;

            final exito = await updateWarrantyPhotos(
              idGarantia: bienResponse['id'],
              imagen: imagenUno!,
              imagen2: imagenDos,
              imagen3: imagenTres,
            );

            if (!exito) {
              return const Left(
                  'Ocurrió un problema con las imágenes de la garantía');
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
    } catch (e) {
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<bool> savePayment({
    required int codigo,
    required double monto,
    required String userId,
  }) async {
    const path = '/prestamos/pagos';
    final payload = {
      'monto': monto,
      'prestamoId': codigo,
      'usuarioId': userId,
    };
    try {
      final response = await _dio.post<String>(path, data: payload);
      print('saveeeee 1: ${response.statusCode}');
      print('saveeeee 2: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        //return Left(message);
        return false;
      }
    } catch (e) {
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
  }) async {
    const path = '/prestamos/prestamos/aumentarMonto';
    final payload = {
      'monto': monto,
      'prestamoId': codigo,
      'observaciones': observaciones,
    };
    try {
      final response = await _dio.post<String>(path, data: payload);
      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return false;
        //return Left(message);
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
        return true;
      }
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
      print('skjaldjsadkla 1: ${response.statusCode}');
      print('skjaldjsadkla 2:   ${response.data}');

      if (response.statusCode != 201) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return false;
      } else {
        return true;
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        //return const Right(true);
        /* return true; */
      }
    } catch (e) {
      return false;
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      /* return false; */
    }
  }

  @override
  Future<Either<String, ReportsPaymentEntity>> getPayments(
      {required int id}) async {
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
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<bool> uploadWarrantyImage({
    required String path,
    required int idGarantia,
  }) async {
    if (path.contains('files/garantias')) {
      return true;
    }

    final img = File(path);

    try {
      final path = '/prestamos/prestamos/imagenGarantia/$idGarantia';

      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          img.path,
          filename: img.path.split('/').last,
        )
      });

      log('statttuututus code 6: ${formData}');

      final response = await _dio.put(path, data: formData);
      log('statttuututus code 7: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> payOffLoan({
    required int id,
    required int idPrestamo,
    required List<XFile>? photos,
  }) async {
    final path = '/prestamos/prestamos/liquidar/$id';

    try {
      final response = await _dio.put<String>(path);
      print('saveeeee 1.1: ${response.statusCode}');
      print('saveeeee 2.2: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (photos?.length == 0) {
          return true;
        } else {
          final result = await updateLiquidacionPhotos(
            idPrestamo: idPrestamo,
            imagenUno: photos!.first.path,
          );
          return result;
        }
      } else {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        //return Left(message);
        return false;
      }
    } catch (e) {
      //print('responseee ee: $e');
      //return const Left('Ocurrió un error 2');
      return false;
    }
  }

  Future<bool> updateLiquidacionPhotos({
    required int idPrestamo,
    required String imagenUno,
  }) async {
    final imgUno = File(imagenUno);
    try {
      final path = '/prestamos/prestamos/imagenLiquidar/$idPrestamo';
      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          imgUno.path,
          filename: imgUno.path.split('/').last,
        ),
      });

      final response = await _dio.put(path, data: formData);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

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
    } catch (e) {
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

    log('statttuututus code 3_4.5: ${data}');

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
    } catch (e) {
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
      log('qllqp: $path ==>  ${imagen}');

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
    };

    log('payladolada: $payload');

    try {
      final response = await _dio.put<String>(path, data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        log('statttuututus code 2: ${map}');
        final bienesResponse = map['body']['bienesGarantia'] as List<dynamic>?;
        log('statttuututus code 3: ${bienesResponse}');

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
          log('debugggg aui 1.3');
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

            log('mapasaaa: $mapa');

            final exito = await updateWarrantyPhotos(
              idGarantia: bienResponse['id'],
              imagen: imagenUno,
              imagen2: imagenDos,
              imagen3: imagenTres,
            );

            print('debugggg aui 1.4: $exito');

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
    } catch (e) {
      //print('responseee ee: $e');
      return const Left('Ocurrió un error con el servidor');
    }
  }

  @override
  Future<bool> deleteLoan({
    required int idLoan,
  }) async {
    final path = '/prestamos/prestamos/$idLoan';
    try {
      final response = await _dio.delete<String>(path);
      if (response.statusCode != 200) {
        final map = json.decode(response.data!) as Map<String, dynamic>;
        final message = map['message'] ?? 'Ocurrió un error';
        return false;
      } else {
        //final map = json.decode(response.data!) as Map<String, dynamic>;
        return true;
      }
    } catch (e) {
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
    } catch (e) {
      return false;
    }
  }
}
