import 'package:casa_empenio_pe/presentation/features/home/features/loans/feature/loans_step/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:casa_empenio_pe/presentation/app/widgets/widgets.dart'; // Asegúrate de importar los widgets necesarios

class CustomImagePicker extends StatefulWidget {
  const CustomImagePicker({
    Key? key,
    required this.onImagesSelected,
    required this.initialSelectedPhotos,
    required this.limit,
  }) : super(key: key);

  final void Function(List<XFile>?) onImagesSelected;
  final List<XFile>? initialSelectedPhotos;
  final int limit;

  @override
  _CustomImagePickerState createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  List<XFile>? selectedPhotos;

  @override
  void initState() {
    super.initState();
    selectedPhotos = widget.initialSelectedPhotos ?? [];
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        selectedPhotos!.add(photo);
      });
      widget.onImagesSelected(selectedPhotos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < (selectedPhotos?.length ?? 0); i++) ...[
          CustomImageClient(
            onTap: () {
              setState(() {
                selectedPhotos!.removeAt(i);
              });
              widget.onImagesSelected(selectedPhotos);
            },
            path: selectedPhotos![i].path,
          ),
          const SizedBox(width: 10),
        ],
        if (selectedPhotos!.length < widget.limit)
          Expanded(
            child: SecondaryButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Seleccionar imagen desde:"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickImageFromSource(ImageSource.camera);
                          },
                          child: const Text("Cámara"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickImageFromSource(ImageSource.gallery);
                          },
                          child: const Text("Galería"),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(
                'Subir Imagen (${widget.limit - selectedPhotos!.length})',
              ),
            ),
          ),
      ],
    );
  }
}
