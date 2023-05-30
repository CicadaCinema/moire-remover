/**************************************************************

The program takes as input a BMP image file,
runs `do_something` on the image content,
and saves the result as another BMP image.

**************************************************************/

#include "qdbmp.h"

#include <fftw3.h>

#include <assert.h>
#include <complex.h>
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// applies the filter to `fourier` in-place
// TODO: implement a better filter
void apply_ideal_notch_reject_filter(complex double *fourier, size_t fwidth,
                                     size_t fheight, size_t target_x,
                                     size_t target_y, double target_radius) {
  for (size_t y = 0; y < fheight; y++) {
    for (size_t x = 0; x < fwidth; x++) {
      // TODO: implement a more elegant solution than casting everything to signed
      double D = sqrt(pow((signed)target_x - (signed)x, 2) +
                      pow((signed)target_y - (signed)y, 2));
      if (D < target_radius) {
        fourier[y * fwidth + x] = 0;
      }
    }
  }
}

// This is where the real logic happens!
// The rest of this file is purely boilerplate.
// Later, Dart will execute this function directly.
unsigned char *do_something(unsigned char *input_array, size_t width,
                            size_t height) {
  // assume each colour channel has length `clength` ("colour length"),
  // and the entire input pixel array has length `length`.
  // this means that the frequency domain representation of each colour channel
  // will have length `flength` ("Fourier length")
  // TODO: convince myself that width/2+1 == (width/2)+1
  size_t clength = width * height;
  size_t length = width * height * 3;
  size_t flength = height * (width / 2 + 1);

  // we will later return this pointer
  // TODO: ensure I am using `malloc` correctly after I learn about pointers
  unsigned char *pixel_array_output = malloc(sizeof(unsigned char[length]));

  // allocate memory for both the forward and backward Fourier passes:
  // initial ~> fourier ~> final
  double *initial = fftw_alloc_real(clength);
  fftw_complex *fourier = fftw_alloc_complex(flength);
  double *final = fftw_alloc_real(clength);

  // define plans for both the forward and backward passes
  fftw_plan plan_forward = fftw_plan_dft_r2c_2d(
      (int)height, (int)width, initial, fourier, FFTW_ESTIMATE);
  fftw_plan plan_inverse = fftw_plan_dft_c2r_2d((int)height, (int)width,
                                                fourier, final, FFTW_ESTIMATE);

  // compute the fourier transform, one channel at a time,
  // using the fftw-initialised arrays as temporary caches
  // TODO: could use memcpy here, or another optimisation
  double complex frequency_domain[3][flength];
  for (size_t channel_index = 0; channel_index < 3; channel_index++) {
    // copy input data into fftw array
    for (size_t i = 0; i < clength; i++) {
      initial[i] = input_array[i * 3 + channel_index];
    }
    // execute fft
    fftw_execute(plan_forward);
    // copy output data from fftw array
    for (size_t i = 0; i < flength; i++) {
      frequency_domain[channel_index][i] = fourier[i][0] + I * fourier[i][1];
    }
  }
  // `frequency_domain[k]` now contains the fourier transform of the k'th colour channel

  // INSERT LOGIC HERE! MODIFY `frequency_domain`!

  // try out some filters
  apply_ideal_notch_reject_filter(frequency_domain[0], width / 2 + 1, height,
                                  45, 135, 6);
  apply_ideal_notch_reject_filter(frequency_domain[0], width / 2 + 1, height,
                                  34, 32, 6);
  apply_ideal_notch_reject_filter(frequency_domain[0], width / 2 + 1, height,
                                  42, 75, 4);
  apply_ideal_notch_reject_filter(frequency_domain[0], width / 2 + 1, height,
                                  51, 15, 4);
  apply_ideal_notch_reject_filter(frequency_domain[0], width / 2 + 1, height,
                                  63, 35, 4);
  apply_ideal_notch_reject_filter(frequency_domain[0], width / 2 + 1, height,
                                  69, 74, 4);
  apply_ideal_notch_reject_filter(frequency_domain[0], width / 2 + 1, height,
                                  22, 123, 4);
  apply_ideal_notch_reject_filter(frequency_domain[0], width / 2 + 1, height,
                                  50, 116, 4);
  apply_ideal_notch_reject_filter(frequency_domain[0], width / 2 + 1, height,
                                  56, 153, 4);

  // to preview, uncomment the following block.
  // fftw produces a smaller complex array than the source data, so we must pad
  // the preview output array with zeroes to ensure that its size is consistent
  // with the dimensions of the standard image output
  // TODO: carefully review this for off-by-one bugs
  /*
  size_t colour_channel_preview = 0;
  size_t i = 0; // indexes the source fourier array
  size_t j = 0; // indexes the destination preview array
  for (size_t y = 0; y < height; y++) {
    // fill in the beginning of this row with data
    for (size_t x = 0; x < width / 2 + 1; x++) {
      // the logarithm and the constant factor of 20 result in a pleasing
      // visualisation of the test image
      unsigned char preview_pixel =
          (unsigned char)log(
              cabs(frequency_domain[colour_channel_preview][i])) *
          20;
      pixel_array_output[j] = preview_pixel;
      pixel_array_output[j + 1] = preview_pixel;
      pixel_array_output[j + 2] = preview_pixel;
      i += 1;
      j += 3;
    }
    // pad the rest with zeroes
    for (size_t x = width / 2 + 1; x < width; x++) {
      pixel_array_output[j] = 0;
      pixel_array_output[j + 1] = 0;
      pixel_array_output[j + 2] = 0;
      j += 3;
    }
    assert(i == (y + 1) * (width / 2 + 1));
    assert(j == (y + 1) * 3 * width);
  }
  assert(i == flength);
  assert(j == length);
  return pixel_array_output;
  */

  // compute the inverse fourier transform, one channel at a time
  // using the fftw-initialised arrays as temporary caches
  // TODO: could use memcpy here, or another optimisation
  unsigned char from_fourier[3][clength];
  for (size_t channel_index = 0; channel_index < 3; channel_index++) {
    // copy input data into fftw array
    for (size_t i = 0; i < flength; i++) {
      fourier[i][0] = creal(frequency_domain[channel_index][i]);
      fourier[i][1] = cimag(frequency_domain[channel_index][i]);
    }
    // execute inverse fft
    fftw_execute(plan_inverse);
    // copy output data from fftw array, normalising each value
    for (size_t i = 0; i < clength; i++) {
      from_fourier[channel_index][i] =
          (unsigned char)(final[i] / (double)clength);
    }
  }
  // `from_fourier` now contains the altered image

  // copy the result to the output array
  for (size_t i = 0; i < clength; i++) {
    pixel_array_output[3 * i] = from_fourier[0][i];
    pixel_array_output[3 * i + 1] = from_fourier[1][i];
    pixel_array_output[3 * i + 2] = from_fourier[2][i];
  }

  fftw_destroy_plan(plan_forward);
  fftw_destroy_plan(plan_inverse);
  fftw_free(initial);
  fftw_free(fourier);
  fftw_free(final);

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
