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

NativeLibrary loadFourierLibrary() {
  final libraryPath = path.join(
    Directory.current.path,
    'fourier_library',
    'libfourier_library.so',
  );
  final dylib = DynamicLibrary.open(libraryPath);
  return NativeLibrary(dylib);
}

/// Given a pointer to the memory location where the frequency domain data is
/// stored, and the dimensions of this data (*not the dimensions of the input
/// image*), return an [Image] visualisation of the magnitudes of the complex
/// values.
///
/// We typically take the logarithm of the magnitude and multiply it by a
/// constant factor.
Image produceVisualisationWidget({
  required Pointer<Double> fourierData,
  required int fwidth,
  required int fheight,
}) {
  // Refer to the native library documentation to see how data is stored at
  // offsets from `resultPointer`.
  // TODO: add support for all the colour channels, not just the first one.
  final resultPixelValues = <int>[];
  for (var j = 0; j < fheight * fheight; j++) {
    final realPart = fourierData.elementAt(2 * j).value;
    final imaginaryPart = fourierData.elementAt(2 * j + 1).value;
    final magnitude = sqrt(pow(realPart, 2) + pow(imaginaryPart, 2));
    // Take the logarithm for an acceptable range of values.
    final previewMagntitude = magnitude == 0 ? 0 : log(magnitude).toInt() * 20;

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
    fwidth,
    fheight,
    pixelFormat: PixelFormat.rgba8888,
  );

  // Build Image widget.
  return Image(image: RawImageProvider(raw));
}

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

  late final Pointer<Double> frequencyDomain;

  // Dimensions of the source image, for each channel.
  late final int width;
  late final int height;

  // Dimensions of the frequency domain representation, for each channel.
  late final int fwidth;
  late final int fheight;

  void updateFourierVisualisation() {
    setState(() {
      displayPreviewImage = produceVisualisationWidget(
        fourierData: frequencyDomain,
        fwidth: fwidth,
        fheight: fheight,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    library = loadFourierLibrary();

    final inputImageBytes = widget.inputImage.readAsBytesSync();
    final inputImage = image.decodeImage(inputImageBytes)!;

    width = inputImage.width;
    height = inputImage.height;

    fwidth = (width / 2).floor() + 1;
    fheight = height;

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
    frequencyDomain = library.image2fourier(inputArrayPointer, width, height);

    updateFourierVisualisation();
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
            Container(
              width: double.maxFinite,
              height: 42,
              color: Colors.black38,
              child: const Row(
                children: [
                  Text('Add filters to remove bright spots'),
                ],
              ),
            ),
            ...(displayPreviewImage == null
                ? []
                : [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (myContext, constraints) {
                          ////////////////////////////////////////////////////////////
                          // No idea how these work! Found through experimentation. //
                          ////////////////////////////////////////////////////////////

                          var scale = 1.0;

                          var pillarboxSize =
                              (constraints.maxWidth - fwidth) / 2;
                          var letterboxSize =
                              (constraints.maxHeight - fheight) / 2;

                          if (constraints.maxWidth < fwidth &&
                              constraints.maxHeight < fheight) {
                            // both dimensions are small, work out scale first
                            scale = min(constraints.maxWidth / fwidth,
                                constraints.maxHeight / fheight);
                            pillarboxSize =
                                (constraints.maxWidth - fwidth * scale) / 2;
                            letterboxSize =
                                (constraints.maxHeight - fheight * scale) / 2;
                            pillarboxSize = max(pillarboxSize, 0);
                            letterboxSize = max(letterboxSize, 0);
                          } else if (constraints.maxWidth < fwidth) {
                            pillarboxSize = 0;
                            scale = constraints.maxWidth / fwidth;
                            letterboxSize += (fheight - scale * fheight) / 2;
                          } else if (constraints.maxHeight < fheight) {
                            letterboxSize = 0;
                            scale = constraints.maxHeight / fheight;
                            pillarboxSize += (fwidth - scale * fwidth) / 2;
                          }

                          ////////////////////////////////////////////////////////////
                          ////////////////////////////////////////////////////////////
                          return SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 8,
                              child: GestureDetector(
                                // Apply a filter on tap.
                                onTapUp: (tapDetails) {
                                  library.apply_filter(
                                    frequencyDomain,
                                    fwidth,
                                    fheight,
                                    ((tapDetails.localPosition.dx -
                                                pillarboxSize) /
                                            scale)
                                        .toInt(),
                                    ((tapDetails.localPosition.dy -
                                                letterboxSize) /
                                            scale)
                                        .toInt(),
                                    10,
                                  );
                                  updateFourierVisualisation();
                                },
                                child: displayPreviewImage!,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ])
          ],
        ),
      ),
    );
  }
}
