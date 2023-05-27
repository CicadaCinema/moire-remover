/**************************************************************

The program takes as input a BMP image file,
runs `do_something` on the image content,
and saves the result as another BMP image.

**************************************************************/

#include "qdbmp.h"

#include <complex.h>
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

// This is where the real logic happens!
// The rest of this file is purely boilerplate.
// Later, Dart will execute this function directly.
unsigned char *do_something(unsigned char *pixel_array, size_t width,
                            size_t height) {
  // assume the input pixel array has this length
  size_t length = width * height * 3;

  // TODO: ensure I am using `malloc` correctly after I learn about pointers
  unsigned char *pixel_array_output = malloc(sizeof(unsigned char[length]));

  // apply the definition of the fourier transform
  double complex red_frequency_domain[width * height];
  for (size_t u = 0; u < height; u++) {
    for (size_t v = 0; v < width; v++) {
      double complex pixel_in_frequency_domain = 0;

      // compute the sum for this pixel
      for (size_t m = 0; m < height; m++) {
        for (size_t n = 0; n < width; n++) {
          //                 row offset + col offset
          pixel_in_frequency_domain +=
              pixel_array[3 * m * width + 3 * n] *
              cexp(-2 * M_PI * I *
                   ((double)(u * m) / ((double)height) +
                    (double)(v * n) / ((double)width)));
        }
      }

      red_frequency_domain[u * width + v] = pixel_in_frequency_domain;
    }
  }

  // INSERT LOGIC HERE!
  // `red_frequency_domain` now contains the fourier transform of the first
  // image to preview it, uncomment the following block
  /*
  for (size_t i = 0; i < width * height; i++) {
    unsigned char preview_pixel =
        (unsigned char)log(cabs(red_frequency_domain[i])) * 20;
    pixel_array_output[3 * i] = preview_pixel;
    pixel_array_output[3 * i + 1] = preview_pixel;
    pixel_array_output[3 * i + 2] = preview_pixel;
  }
  */

  // apply the definition of the inverse fourier transform
  double red_from_fourier[width * height];
  for (size_t m = 0; m < height; m++) {
    for (size_t n = 0; n < width; n++) {
      double pixel_from_fourier = 0;

      // compute the sum for this pixel
      for (size_t u = 0; u < height; u++) {
        for (size_t v = 0; v < width; v++) {
          //                                        row offset + col offset
          pixel_from_fourier += red_frequency_domain[u * width + v] *
                                cexp(2 * M_PI * I *
                                     ((double)(u * m) / ((double)height) +
                                      (double)(v * n) / ((double)width)));
        }
      }

      red_from_fourier[m * width + n] =
          pixel_from_fourier / (double)(height * width);
    }
  }

  // `red_from_fourier` now contains the original red channel of the image
  for (size_t i = 0; i < width * height; i++) {
    unsigned char preview_pixel = (unsigned char)red_from_fourier[i];
    pixel_array_output[3 * i] = preview_pixel;
    pixel_array_output[3 * i + 1] = preview_pixel;
    pixel_array_output[3 * i + 2] = preview_pixel;
  }

  return pixel_array_output;
}

int main(int argc, char *argv[]) {
  unsigned char r, g, b;
  unsigned long int width, height;
  unsigned long int x, y;
  BMP *bmp;

  // check arguments
  if (argc != 3) {
    fprintf(stderr, "Usage: %s <input file> <output file>\n", argv[0]);
    return 0;
  }

  // read an image file
  bmp = BMP_ReadFile(argv[1]);
  BMP_CHECK_ERROR(stdout, -1);

  // get image dimensions
  width = BMP_GetWidth(bmp);
  height = BMP_GetHeight(bmp);

  printf("width %lu\n", width);
  printf("height %lu\n", height);

  // allocate memory for the input pixel array,
  // and a pointer for stepping through it
  unsigned char pixel_array[width * height * 3];
  unsigned long int pixel_array_index = 0;

  // read the input image into the pixel array
  for (y = 0; y < height; ++y) {
    for (x = 0; x < width; ++x) {
      // read the pixel's RGB values from the BMP image
      BMP_GetPixelRGB(bmp, x, y, &r, &g, &b);

      // populate three elements of the pixel array
      pixel_array[pixel_array_index] = r;
      pixel_array[pixel_array_index + 1] = g;
      pixel_array[pixel_array_index + 2] = b;
      pixel_array_index += 3;
    }
  }

  // EXECUTE LOGIC on pixel array data,
  // saving the output in another pixel array
  unsigned char *pixel_array_output = do_something(pixel_array, width, height);

  // write the output pixel array to an image
  pixel_array_index = 0;
  for (y = 0; y < height; ++y) {
    for (x = 0; x < width; ++x) {
      // read the pixel's RGB values from the output pixel array
      r = pixel_array_output[pixel_array_index];
      g = pixel_array_output[pixel_array_index + 1];
      b = pixel_array_output[pixel_array_index + 2];
      pixel_array_index += 3;

      // write result to BMP
      BMP_SetPixelRGB(bmp, x, y, r, g, b);
    }
  }
  // save result
  BMP_WriteFile(bmp, argv[2]);
  BMP_CHECK_ERROR(stdout, -2);

  // free all memory allocated for the image
  BMP_Free(bmp);

  return 0;
}
