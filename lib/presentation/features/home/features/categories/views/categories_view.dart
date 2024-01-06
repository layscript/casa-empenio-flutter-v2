import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:casa_empenio_pe/presentation/app/config/config.dart';
import 'package:casa_empenio_pe/presentation/app/utils/utils.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/categories/widgets/widgets.dart';
import 'package:casa_empenio_pe/presentation/features/home/features/features.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      lazy: false,
      create: (context) => CategoriesBloc(
        categoriesRepository: context.read(),
      )..add(GetCategories()),
      child: Builder(builder: (context) {
        return BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            switch (state.categoriesStatus) {
              case CategoriesStatus.loading || CategoriesStatus.initial:
                return const ButtonStateLoading();

              case CategoriesStatus.error:
                return ButtonStateError(
                  onPressed: () {
                    context.read<CategoriesBloc>().add(GetCategories());
                  },
                );

              case CategoriesStatus.loaded:
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: MediaQuery.of(context).size.height * 0.9,
                        padding: const EdgeInsets.only(
                          bottom: 120,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              const Center(
                                child: Text(
                                  'Lista de Categorias',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (state.listCategories != null)
                                ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(
                                    height: 10,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: state.listCategories!.length,
                                  itemBuilder: (context, index) {
                                    final category =
                                        state.listCategories![index];
                                    return ListTile(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              category.descripcion,
                                              maxLines: 3,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: AppColors.yellow,
                                                ),
                                                onPressed: () {
                                                  showDialog(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder: (_) {
                                                      return BlocProvider.value(
                                                        value: context.read<
                                                            CategoriesBloc>(),
                                                        child:
                                                            EditCategoriesDialog(
                                                          categories: category,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 10),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: AppColors.red,
                                                ),
                                                onPressed: () {
                                                  showDialog(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder: (_) {
                                                      return DeleteDialog(
                                                        title: 'Categoría',
                                                        onPressed: () => context
                                                            .read<
                                                                CategoriesBloc>()
                                                            .add(
                                                              DeleteCategories(
                                                                id: category.id,
                                                              ),
                                                            ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 15),
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        top: null,
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: defaultBoxShadow,
                          ),
                          child: Center(
                            child: PrimaryButton(
                              onPressed: () {
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (_) {
                                    return BlocProvider.value(
                                      value: context.read<CategoriesBloc>(),
                                      child: const AddCategoriesDialog(),
                                    );
                                  },
                                );
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.circlePlus),
                                  SizedBox(width: 10),
                                  Text('Agregar Categoría'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
            }
          },
        );
      }),
    );
  }
}
