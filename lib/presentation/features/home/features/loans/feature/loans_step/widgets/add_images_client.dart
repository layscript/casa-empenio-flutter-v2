import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddImagesClientLoan extends StatefulWidget {
  const AddImagesClientLoan({Key? key}) : super(key: key);

  @override
  State<AddImagesClientLoan> createState() => _AddImagesClientLoanState();
}

class _AddImagesClientLoanState extends State<AddImagesClientLoan> {
  List<XFile>? _listPhotos = [];

  Future<void> _loadImages() async {
    if (_listPhotos!.length < 2) {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        setState(() {
          _listPhotos!.add(photo);
        });
      }
    } else {
      // Ya se han seleccionado 2 imágenes
      // Puedes mostrar un mensaje o realizar otra acción según tus necesidades.
    }
  }

  void _removeImage(int index) {
    setState(() {
      _listPhotos!.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Aquí puedes mostrar las imágenes seleccionadas
        if (_listPhotos != null)
          Container(
            //color: Colors.purple,
            width: double.infinity,
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: _listPhotos!.length,
              itemBuilder: (context, index) {
                return Container(
                    //color: Colors.red,
                    width: 100,
                    height: 100,
                    child: Stack(
                      children: [
                        Image.file(
                          width: 100,
                          File(
                            _listPhotos![index].path,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.red,
                            ),
                            child: IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ),
                      ],
                    ));
              },
            ),
          ),
        const SizedBox(height: 10),
        if (_listPhotos!.length < 2)
          ElevatedButton(
            onPressed: _loadImages,
            child: const Text('Cargar Imagen'),
          ),
      ],
    );
  }
}
