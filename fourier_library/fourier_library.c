#include "qdbmp.h"

#include <fftw3.h>

#include <assert.h>
#include <complex.h>
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

uint8_t *fourier2image(double *fourier_array, size_t width, size_t height) {
  size_t clength = width * height;
  size_t flength = height * (width / 2 + 1);

  fftw_complex *fourier = fftw_alloc_complex(flength);
  double *final = fftw_alloc_real(clength);

  fftw_plan plan_inverse = fftw_plan_dft_c2r_2d((int)height, (int)width,
                                                fourier, final, FFTW_ESTIMATE);

  uint8_t *pixel_array_output = malloc(sizeof(unsigned char[clength * 3]));

  for (size_t channel_index = 0; channel_index < 3; channel_index++) {
    for (size_t i = 0; i < flength; i++) {
      fourier[i][0] = fourier_array[2 * (channel_index * flength + i)];
      fourier[i][1] = fourier_array[2 * (channel_index * flength + i) + 1];
    }
    fftw_execute(plan_inverse);
    for (size_t i = 0; i < clength; i++) {
      pixel_array_output[i * 3 + channel_index] = final[i] / (width * height);
    }
  }

  return pixel_array_output;
}

void apply_filter(double *fourier, size_t fwidth, size_t fheight,
                  size_t target_x, size_t target_y, double target_radius) {
  for (size_t y = 0; y < fheight; y++) {
    for (size_t x = 0; x < fwidth; x++) {
      double D = sqrt(pow((signed)target_x - (signed)x, 2) +
                      pow((signed)target_y - (signed)y, 2));
      if (D < target_radius) {
        fourier[2 * (y * fwidth + x)] = 0;
        fourier[2 * (y * fwidth + x) + 1] = 0;
      }
    }
  }
}

// the arguments height and width are the dimensions of the original image
// assume each colour channel of the input array is of length width*height.
// the output for each channel will represent height*(width/2+1) complex numbers.
double *image2fourier(uint8_t *input_array, size_t width, size_t height) {
  size_t clength = width * height;
  size_t flength = height * (width / 2 + 1);

  double *initial = fftw_alloc_real(clength);
  fftw_complex *fourier = fftw_alloc_complex(flength);

  fftw_plan plan_forward = fftw_plan_dft_r2c_2d(
      (int)height, (int)width, initial, fourier, FFTW_ESTIMATE);

  double *frequency_domain = malloc(sizeof(double[2 * 3 * flength]));

  for (size_t channel_index = 0; channel_index < 3; channel_index++) {
    for (size_t i = 0; i < clength; i++) {
      initial[i] = input_array[i * 3 + channel_index];
    }
    fftw_execute(plan_forward);
    for (size_t i = 0; i < flength; i++) {
      frequency_domain[2 * (channel_index * flength + i)] = fourier[i][0];
      frequency_domain[2 * (channel_index * flength + i) + 1] = fourier[i][1];
    }
  }

  // `frequency_domain` now contains the Fourier transforms of the three colour
  // channels, stored sequentially one after another:
  //                  channel0                             |  channel1 | channel2
  // pix0-real, pix0-complex, pix1-real, pix1-complex, ... |    ...    |   ...

  return frequency_domain;
}

int main() {
  unsigned char dummy1[1];
  double *result = image2fourier(dummy1, 1, 1);
  apply_filter(result, 1, 1, 1, 1, 1);
  fourier2image(result, 1, 1);
  return 0;
}
