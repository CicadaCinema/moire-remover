import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'fourier_filter_paint.dart';

class InputImageSelectionPage extends StatefulWidget {
  const InputImageSelectionPage({super.key});

  @override
  State<InputImageSelectionPage> createState() =>
      _InputImageSelectionPageState();
}

class _InputImageSelectionPageState extends State<InputImageSelectionPage> {
  File? imageChosen;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        imageChosen = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your input image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Select an image'),
            ),
            ...(imageChosen == null
                ? [const Text('No image selected')]
                : [
                    Image.file(imageChosen!),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FilterPaintPage(inputImage: imageChosen!),
                            ),
                          );
                        },
                        child: const Text('Next')),
                  ]),
          ],
        ),
      ),
    );
  }
}
