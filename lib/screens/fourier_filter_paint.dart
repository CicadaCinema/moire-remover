import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;

import '../generated_bindings.dart';
import '../common.dart';
import 'output_image_view.dart';

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
      // TODO: add support for previewing all the colour channels, not just the first one.
      displayPreviewImage = fourierToWidget(
        library: library,
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
              child: Row(
                children: [
                  const Text('Add filters to remove bright spots'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OutputImageViewPage(
                              outputImage: arrayToWidget(
                            pixelArray: library.fourier2image(
                              frequencyDomain,
                              width,
                              height,
                            ),
                            width: width,
                            height: height,
                          )),
                        ),
                      );
                    },
                    child: const Text('proceed'),
                  )
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
                                    (tapDetails.localPosition.dx -
                                            pillarboxSize) ~/
                                        scale,
                                    (tapDetails.localPosition.dy -
                                            letterboxSize) ~/
                                        scale,
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
