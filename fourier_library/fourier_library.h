#include <stddef.h>
#include <stdint.h>

uint8_t *fourier2image(double *fourier_array, size_t width, size_t height);
void apply_filter(double *fourier, size_t fwidth, size_t fheight,
                  size_t target_x, size_t target_y, double target_radius);
double *image2fourier(uint8_t *input_array, size_t width, size_t height);
