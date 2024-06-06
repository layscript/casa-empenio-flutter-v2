import 'package:casa_empenio_pe_dev/domain/domain.dart';
import 'package:casa_empenio_pe_dev/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

class LoansPreferencesEntity extends Equatable {
  const LoansPreferencesEntity({
    required this.documentClient,
    required this.fullNamesClient,
    required this.fullLastNamesClient,
    required this.phoneClient,
    required this.emailClient,
    required this.domicilioClient,
    required this.imagesClient,
    required this.isAval,
    required this.documentAval,
    required this.fullNamesAval,
    required this.fullLastNamesAval,
    required this.phoneAval,
    required this.emailAval,
    required this.domicilioAval,
    required this.imagesAval,
    required this.codeLoans,
    required this.startDateTime,
    required this.amount,
    required this.interest,
    required this.deadline,
    required this.endDateTime,
    required this.observations,
    required this.totalProfit,
    required this.totalToPay,
    required this.warrantyPreferences,
  });

  final String? documentClient;
  final String? fullNamesClient;
  final String? fullLastNamesClient;
  final String? phoneClient;
  final String? emailClient;
  final String? domicilioClient;
  final List<XFile>? imagesClient;
  final bool? isAval;
  final String? documentAval;
  final String? fullNamesAval;
  final String? fullLastNamesAval;
  final String? phoneAval;
  final String? emailAval;
  final String? domicilioAval;
  final List<XFile>? imagesAval;
  final String? codeLoans;
  final String? startDateTime;
  final String? amount;
  final InterestsEntity? interest;
  final String? deadline;
  final String? endDateTime;
  final String? observations;
  final String? totalToPay;
  final String? totalProfit;
  //final List<WarrantyPreferencesEntity>? warrantyPreferences;
  final List<WarrantyState>? warrantyPreferences;

  factory LoansPreferencesEntity.init() {
    return const LoansPreferencesEntity(
      documentClient: null,
      fullNamesClient: null,
      fullLastNamesClient: null,
      phoneClient: null,
      emailClient: null,
      domicilioClient: null,
      imagesClient: null,
      isAval: null,
      documentAval: null,
      fullNamesAval: null,
      fullLastNamesAval: null,
      phoneAval: null,
      emailAval: null,
      domicilioAval: null,
      imagesAval: null,
      codeLoans: null,
      startDateTime: null,
      amount: null,
      deadline: null,
      interest: null,
      endDateTime: null,
      observations: null,
      totalProfit: null,
      totalToPay: null,
      warrantyPreferences: null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'documentClient': documentClient,
      'fullNamesClient': fullNamesClient,
      'fullLastNamesClient': fullLastNamesClient,
      'phoneClient': phoneClient,
      'emailClient': emailClient,
      'domicilioClient': domicilioClient,
      'imagesClient': imagesClient?.map((xFile) => xFile.path).toList(),
      'isAval': isAval,
      'documentAval': documentAval,
      'fullNamesAval': fullNamesAval,
      'fullLastNamesAval': fullLastNamesAval,
      'phoneAval': phoneAval,
      'emailAval': emailAval,
      'domicilioAval': domicilioAval,
      'imagesAval': imagesAval?.map((xFile) => xFile.path).toList(),
      'codeLoans': codeLoans,
      'startDateTime': startDateTime,
      'amount': amount,
      'interest': interest != null
          ? {
              'id': interest?.id,
              'interes': interest?.intereses,
            }
          : null,
      'deadline': deadline,
      'endDateTime': endDateTime,
      'observations': observations,
      'totalProfit': totalProfit,
      'totalToPay': totalToPay,
      'warrantyPreferences':
          warrantyPreferences?.map((warranty) => warranty.toJson()).toList(),
    };
  }

  factory LoansPreferencesEntity.fromJson(Map<String, dynamic> map) {
    return LoansPreferencesEntity(
      documentClient: map['documentClient'],
      fullNamesClient: map['fullNamesClient'],
      fullLastNamesClient: map['fullLastNamesClient'],
      phoneClient: map['phoneClient'],
      emailClient: map['emailClient'],
      domicilioClient: map['domicilioClient'],
      imagesClient: map['imagesClient'] != null
          ? (map['imagesClient'] as List<dynamic>)
              .map((path) => XFile(path))
              .toList()
          : null,
      isAval: map['isAval'],
      documentAval: map['documentAval'],
      fullNamesAval: map['fullNamesAval'],
      fullLastNamesAval: map['fullLastNamesAval'],
      phoneAval: map['phoneAval'],
      emailAval: map['emailAval'],
      domicilioAval: map['domicilioAval'],
      imagesAval: map['imagesAval'] != null
          ? (map['imagesAval'] as List<dynamic>)
              .map((path) => XFile(path))
              .toList()
          : null,
      codeLoans: map['codeLoans'],
      startDateTime: map['startDateTime'],
      amount: map['amount'],
      deadline: map['deadline'],
      interest: map['interest'] != null
          ? InterestsEntity.getInterestFromMap(map['interest'])
          : null,
      endDateTime: map['endDateTime'],
      observations: map['observations'],
      totalProfit: map['totalProfit'],
      totalToPay: map['totalToPay'],
      //warrantyPreferences: map['warrantyPreferences'],
      warrantyPreferences: map['warrantyPreferences'] != null
          ? (map['warrantyPreferences'] as List<dynamic>)
              .map((warrantyMap) => WarrantyState.fromJson(warrantyMap))
              .toList()
          : null,
    );
  }

  LoansPreferencesEntity copyWith({
    String? documentClient,
    String? fullNamesClient,
    String? fullLastNamesClient,
    String? phoneClient,
    String? emailClient,
    String? domicilioClient,
    List<XFile>? imagesClient,
    bool? isAval,
    String? documentAval,
    String? fullNamesAval,
    String? fullLastNamesAval,
    String? phoneAval,
    String? emailAval,
    String? domicilioAval,
    List<XFile>? imagesAval,
    String? codeLoans,
    String? startDateTime,
    String? amount,
    String? deadline,
    InterestsEntity? interest,
    String? endDateTime,
    String? observations,
    String? totalToPay,
    String? totalProfit,
    List<WarrantyState>? warrantyPreferences,
    // List<WarrantyPreferencesEntity>? warrantyPreferences,
  }) =>
      LoansPreferencesEntity(
        documentClient: documentClient ?? this.documentClient,
        fullNamesClient: fullNamesClient ?? this.fullNamesClient,
        fullLastNamesClient: fullLastNamesClient ?? this.fullLastNamesClient,
        phoneClient: phoneClient ?? this.phoneClient,
        emailClient: emailClient ?? this.emailClient,
        domicilioClient: domicilioClient ?? this.domicilioClient,
        imagesClient: imagesClient ?? this.imagesClient,
        isAval: isAval ?? this.isAval,
        documentAval: documentAval ?? this.documentAval,
        fullNamesAval: fullNamesAval ?? this.fullNamesAval,
        fullLastNamesAval: fullLastNamesAval ?? this.fullLastNamesAval,
        phoneAval: phoneAval ?? this.phoneAval,
        emailAval: emailAval ?? this.emailAval,
        domicilioAval: domicilioAval ?? this.domicilioAval,
        imagesAval: imagesAval ?? this.imagesAval,
        codeLoans: codeLoans ?? this.codeLoans,
        startDateTime: startDateTime ?? this.startDateTime,
        amount: amount ?? this.amount,
        deadline: deadline ?? this.deadline,
        interest: interest ?? this.interest,
        endDateTime: endDateTime ?? this.endDateTime,
        observations: observations ?? this.observations,
        warrantyPreferences: warrantyPreferences ?? this.warrantyPreferences,
        totalProfit: totalProfit ?? this.totalProfit,
        totalToPay: totalToPay ?? this.totalToPay,
      );

  @override
  List<Object?> get props => [
        documentClient,
        fullNamesClient,
        fullLastNamesClient,
        phoneClient,
        emailClient,
        domicilioClient,
        imagesClient,
        isAval,
        documentAval,
        fullNamesAval,
        fullLastNamesAval,
        phoneAval,
        emailAval,
        domicilioAval,
        imagesAval,
        codeLoans,
        startDateTime,
        amount,
        deadline,
        interest,
        endDateTime,
        observations,
        totalProfit,
        totalToPay,
        warrantyPreferences,
      ];
}

class WarrantyPreferencesEntity extends Equatable {
  const WarrantyPreferencesEntity({
    required this.description,
    required this.categoria,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.estado,
    required this.serie,
    required this.observacionesWarranty,
    required this.precioReferencial,
    required this.imagesWarranty,
  });

  final String? description;
  final String? categoria;
  final String? placa;
  final String? marca;
  final String? modelo;
  final String? color;
  final String? estado;
  final String? serie;
  final String? observacionesWarranty;
  final String? precioReferencial;
  final List<XFile>? imagesWarranty;

  @override
  List<Object?> get props => [
        description,
        categoria,
        placa,
        marca,
        modelo,
        color,
        estado,
        serie,
        observacionesWarranty,
        precioReferencial,
        imagesWarranty,
      ];
}
