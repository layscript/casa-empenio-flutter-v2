import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/campos_dinamicos_form.dart';
import 'package:casa_empenio_pe/presentation/app/utils/custom_image_picker.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddFormWarranty extends StatelessWidget {
  const AddFormWarranty({super.key});

  @override
  Widget build(BuildContext context) {
    final loansStepBloc = context.read<LoansStepBloc>();

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          _buildDescriptionField(loansStepBloc),
          const SizedBox(height: 15),
          _buildCategoryAndPlacaRow(loansStepBloc),
          const SizedBox(height: 15),
          BlocBuilder<LoansStepBloc, LoansStepState>(
            buildWhen: (a, b) => a.categories?.id != b.categories?.id,
            builder: (context, state) {
              // En terrenos, casas, etc. no se piden marca/modelo/color/estado
              if (categoriaOcultaBasicos(
                  state.categories, state.listCategories)) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  _buildBrandAndModelRow(loansStepBloc),
                  const SizedBox(height: 15),
                  _buildColorAndStatusRow(loansStepBloc),
                  const SizedBox(height: 15),
                ],
              );
            },
          ),
          _buildOptionalFields(loansStepBloc),
          const SizedBox(height: 15),
          _buildPhotoSelectionRow(loansStepBloc),
          const SizedBox(height: 15),
          _buildButtons(loansStepBloc),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildDescriptionField(LoansStepBloc loansStepBloc) {
    return AppTextFormField(
      labelText: 'Descripción (requerido)',
      onChanged: (e) => loansStepBloc.add(
        ChangeDescription(value: e),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Campo Requerido';
        return null;
      },
    );
  }

  Widget _buildCategoryAndPlacaRow(LoansStepBloc loansStepBloc) {
    return Row(
      children: [
        BlocBuilder<LoansStepBloc, LoansStepState>(
          builder: (context, state) {
            return Expanded(
              child: AppDropdownButtonFormField<CategoriesEntity?>(
                labelText: 'Categoría (requerido)',
                value: state.categories,
                onChanged: (value) =>
                    loansStepBloc.add(ChangeCategoryWarranty(value)),
                items: state.listCategories == null
                    ? null
                    : ordenarCategorias(state.listCategories!)
                        .map((e) => DropdownMenuItem<CategoriesEntity?>(
                              value: e,
                              child: Text(
                                nombreCategoria(e, state.listCategories),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppTextFormField(
            labelText: 'Placa (opcional)',
            onChanged: (e) => loansStepBloc.add(ChangePlacaWarranty(e)),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandAndModelRow(LoansStepBloc loansStepBloc) {
    return Row(
      children: [
        Expanded(
          child: AppTextFormField(
            labelText: 'Marca (requerido)',
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
            onChanged: (e) => loansStepBloc.add(ChangeModel(value: e)),
            validator: (value) {
              if (value!.isEmpty) return 'Campo Requerido';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorAndStatusRow(LoansStepBloc loansStepBloc) {
    return Row(
      children: [
        Expanded(
          child: AppTextFormField(
            labelText: 'Color (requerido)',
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
                onChanged: (e) => loansStepBloc.add(ChangeStatus(value: e!)),
                items: ['nuevo', 'bueno', 'regular']
                    .map((e) => DropdownMenuItem<String?>(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalFields(LoansStepBloc loansStepBloc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextFormField(
          labelText: 'Serie (opcional)',
          onChanged: (e) => loansStepBloc.add(ChangeSerie(value: e)),
        ),
        const SizedBox(height: 15),
        // Campos extra de la categoría elegida (se crean en Administración > Campos)
        BlocBuilder<LoansStepBloc, LoansStepState>(
          buildWhen: (a, b) => a.categories?.id != b.categories?.id,
          builder: (context, state) =>
              CamposDinamicosForm(categoriaId: state.categories?.id),
        ),
        AppTextFormField(
          labelText: 'Observaciones (requerido)',
          onChanged: (e) =>
              loansStepBloc.add(ChangeWarrantyObservations(value: e)),
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
          labelText: 'Precio Referencial (requerido)',
          keyboardType: TextInputType.number,
          onChanged: (e) => loansStepBloc.add(ChangePrice(value: e)),
          validator: (value) {
            if (value!.isEmpty) return 'Campo Requerido';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotoSelectionRow(LoansStepBloc loansStepBloc) {
    return BlocBuilder<LoansStepBloc, LoansStepState>(
      builder: (context, state) {
        return CustomImagePicker(
          onImagesSelected: (e) => loansStepBloc.add(
            UploadImagesWarranty(e),
          ),
          initialSelectedPhotos: state.photoWarranty,
          limit: 2,
        );
      },
    );
  }

  Widget _buildButtons(
    LoansStepBloc loansStepBloc,
  ) {
    return BlocBuilder<LoansStepBloc, LoansStepState>(
      builder: (context, state) {
        return Column(
          children: [
            SecondaryButton(
              onPressed: () {
                // Lógica para volver atrás
                if (state.listWarranty == null || state.listWarranty!.isEmpty) {
                  loansStepBloc.add(
                    SaveThirdStepOne(
                      index: 1,
                      value: WarrantyState(
                        id: generateIDFromDateTime(),
                        category: state.categories,
                        placa: state.placa,
                        description: state.description,
                        brand: state.brand,
                        model: state.model,
                        color: state.color,
                        status: state.status,
                        serie: state.serie,
                        warrantyObservations: state.warrantyObservations,
                        price: state.price,
                        photoWarranty: state.photoWarranty,
                      ),
                    ),
                  );
                } else {
                  loansStepBloc.add(
                    const ChangeStatusAddListWarranty(
                      value: false,
                    ),
                  );
                }
              },
              child: const Text('Volver'),
            ),
            const SizedBox(height: 15),
            PrimaryButton(
              onPressed:
                  (state.description != '' && state.description != null) &&
                          (state.categories != null) &&
                          (categoriaOcultaBasicos(
                                  state.categories, state.listCategories) ||
                              ((state.brand != '' && state.brand != null) &&
                                  (state.model != '' && state.model != null) &&
                                  (state.color != '' && state.color != null) &&
                                  (state.status != '' &&
                                      state.status != null))) &&
                          (state.warrantyObservations != '' &&
                              state.warrantyObservations != null) &&
                          (state.price != '' && state.price != null)
                      ? () {
                          final faltan = CamposDinamicosEstado.faltantes();
                          if (faltan.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Complete: ${faltan.join(', ')}'),
                              ),
                            );
                            return;
                          }
                          // Los datos extra se guardan junto a las observaciones del bien
                          final extra = CamposDinamicosEstado.resumen();
                          if (extra.isNotEmpty) {
                            loansStepBloc.add(
                              ChangeWarrantyObservations(
                                value: '${state.warrantyObservations} | $extra',
                              ),
                            );
                          }
                          loansStepBloc.add(const AddListWarranty());
                          CamposDinamicosEstado.limpiar();
                        }
                      : null,
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
