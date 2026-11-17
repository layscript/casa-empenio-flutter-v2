import 'package:casa_empenio_pe/domain/domain.dart';
import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/utils/campos_dinamicos_form.dart';
import 'package:casa_empenio_pe/presentation/app/utils/custom_image_picker.dart';
import 'package:casa_empenio_pe/presentation/app/utils/escaner_bien.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/bloc/loans_step_bloc.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/widgets/selector_categoria.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class AddFormWarranty extends StatefulWidget {
  const AddFormWarranty({super.key});

  @override
  State<AddFormWarranty> createState() => _AddFormWarrantyState();
}

class _AddFormWarrantyState extends State<AddFormWarranty> {
  final _desc = TextEditingController();
  final _placa = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _color = TextEditingController();
  final _serie = TextEditingController();
  final _obs = TextEditingController();
  int _fotosNonce = 0;

  @override
  void dispose() {
    for (final c in [_desc, _placa, _marca, _modelo, _color, _serie, _obs]) {
      c.dispose();
    }
    super.dispose();
  }

  CategoriesEntity? _categoriaPara(String tipo, List<CategoriesEntity> todas) {
    final palabras = palabrasCategoria(tipo);
    if (palabras.isEmpty) return null;
    String n(String s) => s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    for (final w in palabras) {
      final subs = todas.where((c) => c.padreId != null && n(c.descripcion).contains(w));
      if (subs.isNotEmpty) return subs.first;
      final raiz = todas.where((c) => n(c.descripcion).contains(w));
      if (raiz.isNotEmpty) return raiz.first;
    }
    return null;
  }

  Future<void> _escanear(LoansStepBloc bloc) async {
    final st = bloc.state;
    String? padre;
    final cat = st.categories;
    if (cat != null && cat.padreId != null) {
      for (final c in st.listCategories ?? <CategoriesEntity>[]) {
        if (c.id == cat.padreId) padre = c.descripcion;
      }
    }
    final r = await abrirEscanerBien(context,
        tipoInicial: tipoEscaneoDeCategoria(cat?.descripcion, padre));
    if (r == null || !mounted) return;
    final c = r.campos;
    if (cat == null) {
      final nueva = _categoriaPara(r.tipo, st.listCategories ?? <CategoriesEntity>[]);
      if (nueva != null) bloc.add(ChangeCategoryWarranty(nueva));
    }
    void poner(TextEditingController ctl, String? v, void Function(String) enviar) {
      final t = (v ?? '').trim();
      if (t.isEmpty) return;
      ctl.text = t;
      enviar(t);
    }

    poner(_desc, c['descripcion'], (t) => bloc.add(ChangeDescription(value: t)));
    poner(_placa, c['placa'], (t) => bloc.add(ChangePlacaWarranty(t)));
    poner(_marca, c['marca'], (t) => bloc.add(ChangeBrand(value: t)));
    poner(_modelo, c['modelo'], (t) => bloc.add(ChangeModel(value: t)));
    poner(_color, c['color'], (t) => bloc.add(ChangeColor(value: t)));
    poner(_serie, c['serie'], (t) => bloc.add(ChangeSerie(value: t)));
    final obs = r.extras.isNotEmpty
        ? 'Registrado con escáner · ${r.extras}'
        : 'Registrado con escáner';
    _obs.text = obs;
    bloc.add(ChangeWarrantyObservations(value: obs));
    if (r.fotos.isNotEmpty) {
      bloc.add(UploadImagesWarranty(r.fotos));
      setState(() => _fotosNonce++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loansStepBloc = context.read<LoansStepBloc>();

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: () => _escanear(loansStepBloc),
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Escanear bien con la cámara'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Toma fotos y el sistema llena marca, modelo, serie/IMEI y placa. Tú revisas.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
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
      controller: _desc,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SelectorCategoria(),
        const SizedBox(height: 15),
        AppTextFormField(
          labelText: 'Placa (opcional)',
          controller: _placa,
          onChanged: (e) => loansStepBloc.add(ChangePlacaWarranty(e)),
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
            controller: _marca,
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
            controller: _modelo,
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
            controller: _color,
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
          controller: _serie,
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
          controller: _obs,
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

  Future<void> _agregarDocumento(
      LoansStepBloc bloc, ImageSource origen) async {
    final foto = await ImagePicker().pickImage(source: origen, imageQuality: 92);
    if (foto == null || !mounted) return;
    final actuales = List<XFile>.from(bloc.state.photoWarranty ?? <XFile>[]);
    if (actuales.length >= 3) return;
    actuales.add(foto);
    bloc.add(UploadImagesWarranty(actuales));
    setState(() => _fotosNonce++);
  }

  Widget _buildPhotoSelectionRow(LoansStepBloc loansStepBloc) {
    return BlocBuilder<LoansStepBloc, LoansStepState>(
      builder: (context, state) {
        final n = state.photoWarranty?.length ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomImagePicker(
              key: ValueKey('fotos$_fotosNonce'),
              onImagesSelected: (e) => loansStepBloc.add(
                UploadImagesWarranty(e),
              ),
              initialSelectedPhotos: state.photoWarranty,
              limit: 3,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: n >= 3
                  ? null
                  : () => showModalBottomSheet<void>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Wrap(children: [
                            ListTile(
                              leading: const Icon(Icons.photo_camera),
                              title: const Text('Tomar foto del documento'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _agregarDocumento(
                                    loansStepBloc, ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Elegir de la galería'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _agregarDocumento(
                                    loansStepBloc, ImageSource.gallery);
                              },
                            ),
                          ]),
                        ),
                      ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Agregar tarjeta o documento'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Hasta 3 fotos en total (bien, tarjeta de propiedad, otros documentos).',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
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
