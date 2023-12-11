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
      },
      'aval': aval == null
          ? null
          : {
              'nombres': aval.nombres,
              'apellidos': aval.apellidos,
              'dni': aval.dni,
              'celular': aval.celular,
              'email': aval.email,
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
        final bienesResponse = map['body']['bienesGarantia'];
        log('statttuututus code 3: ${bienesResponse}');
        if (cliente.imagenUno != null && cliente.imagenDos != null) {
          await updateCustomerPhotos(
            dni: int.parse(cliente.dni ?? '0'),
            imagenUno: cliente.imagenUno ?? '',
            imagenDos: cliente.imagenDos ?? '',
          );
        }

        for (var bienResponse in bienesResponse) {
          log('aksjdljldsakjklads z3.6: ${bienResponse}');

          for (var garantia in bienes) {
            log('aksjdljldsakjklads z3.7: ${garantia}');
            final imagenUno = garantia['imagen'] as String?;
            final imagenDos = garantia['imagen2'] as String?;
            final imagenTres = garantia['imagen3'] as String?;
            print('aksjdljldsakjklads 3.1: $imagenUno');
            print('aksjdljldsakjklads 3.2: $imagenDos');
            print('aksjdljldsakjklads 3.3: $imagenTres');
            final mainImage = imagenUno?.trimLeft();
            print('aksjdljldsakjklads 3.4: $mainImage');

            if (mainImage != null || mainImage != '') {
              print('aksjdljldsakjklads 3.5.1: $mainImage');
              print('aksjdljldsakjklads 3.5.2: ${bienResponse['id']}');

              final exito = await updateWarrantyPhotos(
                idGarantia: bienResponse['id'],
                imagenUno: imagenUno!.trimLeft(),
                imagenDos: imagenDos == null ? '' : imagenDos.trimLeft(),
                imagenTres: imagenTres == null ? '' : imagenTres.trimLeft(),
              );

              print('aksjdljldsakjklads 3.5.3: ${exito}');

              if (!exito) {
                return const Left('Ocurrió un problema con las imagenes');
              }
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
      //print('responseee ee: $e');
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

  Future<bool> updateCustomerPhotos({
    required int dni,
    required String imagenUno,
    required String imagenDos,
  }) async {
    if (imagenUno.contains('files/garantias') ||
        imagenDos.contains('files/garantias')) {
      return true;
    }

    final imgUno = File(imagenUno);
    final imgDos = File(imagenDos);

    try {
      final path = '/clientes/clientes/imagenCliente/$dni';

      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          imgUno.path,
          filename: imgUno.path.split('/').last,
        ),
        'imagen2': await MultipartFile.fromFile(
          imgDos.path,
          filename: imgDos.path.split('/').last,
        )
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

  Future<bool> updateLiquidacionPhotos({
    required int idPrestamo,
    required String imagenUno,
    //required String imagenDos,
  }) async {
    if (imagenUno.contains(
            'files/garantias') /* ||
        imagenDos.contains('files/garantias') */
        ) {
      return true;
    }

    final imgUno = File(imagenUno);
    //final imgDos = File(imagenDos);

    try {
      final path = '/prestamos/prestamos/imagenLiquidar/$idPrestamo';

      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          imgUno.path,
          filename: imgUno.path.split('/').last,
        ),
        /* 'imagen2': await MultipartFile.fromFile(
          imgDos.path,
          filename: imgDos.path.split('/').last,
        ) */
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

  Future<bool> updateWarrantyPhotos({
    required int idGarantia,
    required String imagenUno,
    required String? imagenDos,
    required String? imagenTres,
  }) async {
    print('aksjdljldsakjklads 3.5.4');
    if (imagenUno.contains('files/garantias')) {
      return true;
    }

    if (imagenDos != null && imagenDos.contains('files/garantias')) {
      return true;
    }
    print('aksjdljldsakjklads 3.5.5');

    if (imagenTres != null && imagenTres.contains('files/garantias')) {
      return true;
    }

    print('aksjdljldsakjklads 3.5.6');

    final imgUno = File(imagenUno);
    File? imgDos;
    File? imgTres;

    if (imagenDos != null) {
      imgDos = File(imagenDos);
    }

    if (imagenTres != null) {
      imgTres = File(imagenTres);
    }

    print('aksjdljldsakjklads 3.5.7.1 : ${imgUno}');
    print('aksjdljldsakjklads 3.5.7.2 : ${imgDos}');
    print('aksjdljldsakjklads 3.5.7.3 : ${imgTres}');

    try {
      final path = '/prestamos/prestamos/imagenGarantia/$idGarantia';
      print('aksjdljldsakjklads 3.5.7.4 : ${path}');

      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(
          imgUno.path,
          filename: imgUno.path.split('/').last,
        ),
        /*  if (imagenDos != null)
          'imagen2': await MultipartFile.fromFile(
            imgDos!.path,
            filename: imgDos.path.split('/').last,
          ),
        if (imagenTres != null)
          'imagen3': await MultipartFile.fromFile(
            imgTres!.path,
            filename: imgTres.path.split('/').last,
          ) */
      });

      print('aksjdljldsakjklads 3.5.7.5 : ${formData}');
      final response = await _dio.put(path, data: formData);
      print('aksjdljldsakjklads 3.5.7.6 : ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('aksjdljldsakjklads 3.5.7.7 : ${e}');

      return false;
    }
  }

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
      },
      'aval': aval == null
          ? null
          : {
              'nombres': aval.nombres,
              'apellidos': aval.apellidos,
              'dni': aval.dni,
              'celular': aval.celular,
              'email': aval.email,
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
        final bienesResponse = map['body']['bienesGarantia'];
        log('statttuututus code 3: ${bienesResponse}');

        if (cliente.imagenUno != null && cliente.imagenDos != null) {
          await updateCustomerPhotos(
            dni: int.parse(cliente.dni ?? '0'),
            imagenUno: cliente.imagenUno ?? '',
            imagenDos: cliente.imagenDos ?? '',
          );
        }

        log('aksjdljldsakjklads z3.5: ${bienesResponse}');

        for (var bienResponse in bienesResponse) {
          log('aksjdljldsakjklads z3.6: ${bienResponse}');

          for (var garantia in bienes) {
            log('aksjdljldsakjklads z3.7: ${garantia}');
            final imagenUno = garantia['imagen'] as String?;
            final imagenDos = garantia['imagen2'] as String?;
            final imagenTres = garantia['imagen3'] as String?;
            print('aksjdljldsakjklads 3.1: $imagenUno');
            print('aksjdljldsakjklads 3.2: $imagenDos');
            print('aksjdljldsakjklads 3.3: $imagenTres');
            final mainImage = imagenUno?.trimLeft();
            print('aksjdljldsakjklads 3.4: $mainImage');

            if (mainImage != null || mainImage != '') {
              print('aksjdljldsakjklads 3.5.1: $mainImage');
              print('aksjdljldsakjklads 3.5.2: ${bienResponse['id']}');

              final exito = await updateWarrantyPhotos(
                idGarantia: bienResponse['id'],
                imagenUno: imagenUno!.trimLeft(),
                imagenDos: imagenDos == null ? '' : imagenDos.trimLeft(),
                imagenTres: imagenTres == null ? '' : imagenTres.trimLeft(),
              );

              print('aksjdljldsakjklads 3.5.3: ${exito}');

              if (!exito) {
                return const Left('Ocurrió un problema con las imagenes');
              }
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
