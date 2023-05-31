import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:raw_image_provider/raw_image_provider.dart';

import '../generated_bindings.dart';

import 'package:path/path.dart' as path;
import 'package:image/image.dart' as image;

class FilterPaintPage extends StatefulWidget {
  const FilterPaintPage({
    super.key,
    required this.inputImage,
  });
  final File inputImage;

  @override
  State<FilterPaintPage> createState() => _FilterPaintPageState();
}

class _FilterPaintPageState extends State<FilterPaintPage> {
  /// A preview visualisation of the frequency domain representation, or null
  /// if it has not been computed yet.
  Image? displayPreviewImage;

  /// The Fourier library.
  late final NativeLibrary library;

  void loadFourierLibrary() {
    final libraryPath = path.join(
        Directory.current.path, 'fourier_library', 'libfourier_library.so');
    final dylib = DynamicLibrary.open(libraryPath);
    library = NativeLibrary(dylib);
  }

  @override
  void initState() {
    super.initState();

    loadFourierLibrary();

    final inputImageBytes = widget.inputImage.readAsBytesSync();
    final inputImage = image.decodeImage(inputImageBytes)!;

    // These variables correspond to the `height` and `width` in the C code.
    final width = inputImage.width;
    final height = inputImage.height;

    // Allocate memory for the input array.
    final inputArrayPointer = calloc<Uint8>(3 * width * height);

    // Set values at offsets from `inputArrayPointer` to the corresponding
    // pixel colour channel intensity values.
    var i = 0;
    final pixelIterator = inputImage.iterator;
    while (pixelIterator.moveNext()) {
      final pixel = pixelIterator.current;
      inputArrayPointer.elementAt(i * 3).value = pixel.r.toInt();
      inputArrayPointer.elementAt(i * 3 + 1).value = pixel.g.toInt();
      inputArrayPointer.elementAt(i * 3 + 2).value = pixel.b.toInt();
      i++;
    }

    // Execute a Fourier transform using the native library.
    final resultPointer =
        library.image2fourier(inputArrayPointer, width, height);

    // Refer to the native library documentation to see how data is stored at
    // offsets from `resultPointer`.
    // TODO: add support for all the colour channels, not just the first one.
    final resultPixelValues = <int>[];
    for (var j = 0; j < height * ((width / 2).floor() + 1); j++) {
      final realPart = resultPointer.elementAt(2 * j).value;
      final imaginaryPart = resultPointer.elementAt(2 * j + 1).value;
      final magnitude = sqrt(pow(realPart, 2) + pow(imaginaryPart, 2));
      // For an acceptable range of values.
      final previewMagntitude = log(magnitude).toInt() * 20;

      // The magnitudes are displayed in greyscale, and the opacity must be maximal.
      resultPixelValues.add(previewMagntitude);
      resultPixelValues.add(previewMagntitude);
      resultPixelValues.add(previewMagntitude);
      resultPixelValues.add(255);
    }

    final resultImageBytes = Uint8List.fromList(resultPixelValues);

    // Use https://github.com/yrom/flutter_raw_image_provider to display an
    // image from raw bytes.
    var raw = RawImageData(
      resultImageBytes,
      (width / 2).floor() + 1,
      height,
      pixelFormat: PixelFormat.rgba8888,
    );

    // Build Image widget.
    displayPreviewImage = Image(image: RawImageProvider(raw));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paint your filter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('You have chosen ${widget.inputImage.path}'),
            ...(displayPreviewImage == null ? [] : [displayPreviewImage!])
          ],
        ),
      ),
    );
  }
}
