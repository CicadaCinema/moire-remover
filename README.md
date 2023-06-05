# moire_remover

A user-friendly tool for removing moiré patterns in images.

## Screenshots

TODO: add screenshots

## Technical glossary

In the below descriptions, the word *logical* means "referring to the image dimensions, or number of pixels, as opposed to the length of some array in the implementation code".

- `width` and `height` represent the logical dimensions of the input image.
- `clength` is equal to `width * height` and represents the number of intensity values used to store a *single* colour channel of the input image. In other words, the number of colour RGB pixels comprising the input image.
- `length` is equal to `3 * width * height` and represents the number of intensity values used to store *all* the colour channels of the input image.
- `fwidth` and `fheight` are equal to `(width / 2).floor() + 1` and `height` respectively and represent the dimensions of the complex-valued matrix (whose magnitudes and arguments can be viewed as an image visualisation, each with dimensions `fwidth` and `fheight`) given by the output of the 2D Fourier transform of a single colour channel of the input image.
- `flength` is equal to `fwidth * fheight` and represents the number of entries in the matrix described above.

