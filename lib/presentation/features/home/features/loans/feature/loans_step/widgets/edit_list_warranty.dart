import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/custom_image_picker.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditFormWarranty extends StatelessWidget {
  const EditFormWarranty({super.key});

  @override
  Widget build(BuildContext context) {
    final loansStepBloc = context.read<LoansStepBloc>();
    final loansState = context.read<LoansStepBloc>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Descripcion (requerido)',
          initialValue: loansState.description,
          onChanged: (e) =>
              loansStepBloc.add(ChangeDescription(value: e, edit: true)),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            BlocBuilder<LoansStepBloc, LoansStepState>(
              builder: (context, state) {
                return Expanded(
                  child: AppDropdownButtonFormField<CategoriesEntity?>(
                    labelText: 'Categoría (requerido)',
                    value: state.categories,
                    onChanged: (e) =>
                        loansStepBloc.add(ChangeCategoryWarranty(e)),
                    items: state.listCategories != null
                        ? state.listCategories!
                            .map(
                              (e) => DropdownMenuItem<CategoriesEntity?>(
                                value: e,
                                child: Text(e.descripcion),
                              ),
                            )
                            .toList()
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Placa (opcional)',
                initialValue: loansState.placa,
                onChanged: (e) => loansStepBloc.add(ChangePlacaWarranty(e)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: AppTextFormField(
                labelText: 'Marca (requerido)',
                initialValue: loansState.brand,
                onChanged: (e) => loansStepBloc.add(ChangeBrand(value: e)),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppTextFormField(
                labelText: 'Modelo (requerido)',
                initialValue: loansState.model,
                onChanged: (e) => loansStepBloc.add(ChangeModel(value: e)),
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
                labelText: 'Color (requerido)',
                initialValue: loansState.color,
                onChanged: (e) => loansStepBloc.add(ChangeColor(value: e)),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo Requerido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BlocBuilder<LoansStepBloc, LoansStepState>(
                builder: (context, state) {
                  return AppDropdownButtonFormField<String?>(
                    labelText: 'Estado (requerido)',
                    value: state.status,
                    onChanged: (e) =>
                        loansStepBloc.add(ChangeStatus(value: e!)),
                    items: ['nuevo', 'bueno', 'regular']
                        .map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Serie (opcional)',
          initialValue: loansState.serie,
          onChanged: (e) => loansStepBloc.add(ChangeSerie(value: e)),
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Observaciones (requerido)',
          initialValue: loansState.warrantyObservations,
          onChanged: (e) =>
              loansStepBloc.add(ChangeWarrantyObservations(value: e)),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        AppTextFormField(
          initialValue: loansState.price,
          preffix: const Text(
            'S/.',
            style: TextStyle(
              color: AppColors.black,
            ),
          ),
          labelText: 'Precio Referencial (requerido)',
          keyboardType: TextInputType.number,
          onChanged: (e) => loansStepBloc.add(ChangePrice(value: e)),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
        const SizedBox(height: 15),
        BlocBuilder<LoansStepBloc, LoansStepState>(
          builder: (context, state) {
            return CustomImagePicker(
              onImagesSelected: (e) => loansStepBloc.add(
                UploadImagesWarranty(e),
              ),
              initialSelectedPhotos: loansState.photoWarranty,
              limit: 2,
            );
          },
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
          onPressed: /* isValidDescriptionWarranty &&
                  isValidCategories &&
                  isValidMarcaWarranty &&
                  isValidModeloWarranty &&
                  isValidColorWarranty &&
                  /* isValidSerieWarranty && */
                  isValidObservationWarranty &&
                  isValidPriceWarranty /* &&
                  (selectedPhotos?.length == 3) */ */
              true
                  ? () {
                      loansStepBloc.add(
                        const EditListWarranty(),
                      );
                    }
                  : null,
          child: const Text('Editar'),
        )
      ],
    );
  }
}
