import 'dart:io';

import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditFormWarranty extends StatelessWidget {
  const EditFormWarranty({super.key});

  @override
  Widget build(BuildContext context) {
    final loansState = context.watch<LoansStepBloc>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Descripcion',
          initialValue: loansState.description,
          onChanged: (e) => context.read<LoansStepBloc>().add(
                ChangeDescription(value: e),
              ),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                labelText: 'Marca',
                initialValue: loansState.brand,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeBrand(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Modelo',
                initialValue: loansState.model,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeModel(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                labelText: 'Color',
                initialValue: loansState.color,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeColor(value: e),
                    ),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppDropdownButtonFormField<String?>(
                labelText: 'Estado',
                value: loansState.status,
                onChanged: (e) => context.read<LoansStepBloc>().add(
                      ChangeStatus(value: e!),
                    ),
                items: ['Nuevo', 'Bueno', 'Regular']
                    .map(
                      (e) => DropdownMenuItem<String?>(
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
          labelText: 'Serie',
          initialValue: loansState.serie,
          onChanged: (e) => context.read<LoansStepBloc>().add(
                ChangeSerie(value: e),
              ),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Observaciones',
          initialValue: loansState.warrantyObservations,
          onChanged: (e) => context.read<LoansStepBloc>().add(
                ChangeWarrantyObservations(value: e),
              ),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          preffix: const Text(
            'S/.',
            style: TextStyle(
              color: AppColors.black,
            ),
          ),
          labelText: 'Precio Referencial',
          keyboardType: TextInputType.number,
          initialValue: loansState.price,
          onChanged: (e) => context.read<LoansStepBloc>().add(
                ChangePrice(value: e),
              ),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            if (loansState.photoWarranty != null)
              Image.file(
                File(loansState.photoWarranty!.path),
                width: 100,
                height: 100,
              ),
            Expanded(
              child: ElevatedButton(
                onPressed: () =>
                    context.read<LoansStepBloc>().add(UploadImagesWarranty()),
                child: const Text(
                  'Cambiar Imagen',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SecondaryButton(
          onPressed: () {
            context.read<LoansStepBloc>().add(
                  const ChangeStatusAddListWarranty(
                    value: false,
                  ),
                );
          },
          child: const Text('Volver'),
        ),
        const SizedBox(height: 15),
        PrimaryButton(
          onPressed: loansState.canRegisterWarranty
              ? () {
                  context.read<LoansStepBloc>().add(
                        EditListWarranty(
                          value: WarrantyState(
                            id: loansState.idWarranty,
                            description: loansState.description,
                            brand: loansState.brand,
                            model: loansState.model,
                            color: loansState.color,
                            status: loansState.status,
                            serie: loansState.serie,
                            warrantyObservations:
                                loansState.warrantyObservations,
                            price: loansState.price,
                            photoWarranty: loansState.photoWarranty,
                          ),
                        ),
                      );
                }
              : null,
          child: const Text('Editar'),
        )
      ],
    );
  }
}
