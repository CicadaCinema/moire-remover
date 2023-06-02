import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'package:raw_image_provider/raw_image_provider.dart';

import 'generated_bindings.dart';
import 'package:flutter/material.dart';

NativeLibrary loadFourierLibrary() {
  final libraryPath = path.join(
    Directory.current.path,
    'fourier_library',
    'libfourier_library.so',
  );
  final dylib = DynamicLibrary.open(libraryPath);
  return NativeLibrary(dylib);
}

/// Given a pointer to the memory location where the pixel image data is
/// stored, and the dimensions of each channel, return an [Image] widget which
/// displays this image.
Image arrayToWidget({
  required Pointer<Uint8> pixelArray,
  required int width,
  required int height,
}) {
  // Refer to the native library documentation to see how data is stored at
  // offsets from `pixelArray`.
  final pixelValues = <int>[];
  for (var j = 0; j < width * height; j++) {
    final r = pixelArray.elementAt(3 * j).value;
    final g = pixelArray.elementAt(3 * j + 1).value;
    final b = pixelArray.elementAt(3 * j + 2).value;

    // TODO: show all the colour channels, not just the first one.
    pixelValues.add(r);
    pixelValues.add(r);
    pixelValues.add(r);
    pixelValues.add(255);
  }

  final imageBytes = Uint8List.fromList(pixelValues);

  // Use https://github.com/yrom/flutter_raw_image_provider to display an
  // image from raw bytes.
  final raw = RawImageData(
    imageBytes,
    width,
    height,
    pixelFormat: PixelFormat.rgba8888,
  );

  // Build Image widget.
  return Image(image: RawImageProvider(raw));
}

/// Given a pointer to the memory location where the frequency domain data is
/// stored, and the dimensions of this data (*not the dimensions of the input
/// image*), return an [Image] visualisation of the magnitudes of the complex
/// values.
///
/// We typically take the logarithm of the magnitude and multiply it by a
/// constant factor.
Image fourierToWidget({
  required NativeLibrary library,
  required Pointer<Double> fourierData,
  required int fwidth,
  required int fheight,
}) {
  final previewPointer =
      library.fourier2rgba_preview(fourierData, fwidth * fheight);

  final preview = previewPointer.asTypedList(fwidth * fheight * 4);

  // Use https://github.com/yrom/flutter_raw_image_provider to display an
  // image from raw bytes.
  final raw = RawImageData(
    preview,
    fwidth,
    fheight,
    pixelFormat: PixelFormat.rgba8888,
  );

  // TODO: am I freeing this pointer correctly?
  malloc.free(previewPointer);

  // Build Image widget.
  return Image(image: RawImageProvider(raw));
}
