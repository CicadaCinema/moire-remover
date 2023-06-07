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

## Build instructions

`cd fourier_library && cmake . && make all && cd .. && dart run ffigen && flutter run`

## Inspiration

- https://news.ycombinator.com/item?id=28663719
- https://newsletter.shifthappens.site/archive/moire-no-more/

## Existing implementations of this idea

- https://docs.opencv.org/3.4.15/d2/d0b/tutorial_periodic_noise_removing_filter.html
- http://www.descreen.net/eng/help/descreen/home/descreen_manual.htm
- https://clouard.users.greyc.fr/Pantheon/experiments/scanner-restoration/index-en.html

## General resources

- https://vincmazet.github.io/bip/filtering/fourier.html
- https://eecs.wsu.edu/~cs445/Lecture_11.pdf
- http://engr.case.edu/merat_francis/eecs490f07/lectures/lecture15.pdf
- https://www.google.com/search?q=gaussian+notch+filter&tbm=isch
- https://github.com/imdeep2905/Notch-Filter-for-Image-Processing/blob/master/filters/notch_filters.py
- http://ijournals.in/wp-content/uploads/2017/07/5.3106-Khanjan.compressed.pdf
- https://arxiv.org/pdf/1701.09037.pdf
- https://eej.aut.ac.ir/article_94_befd8a642325852c3a0d41ece10b3feb.pdf
- https://ietresearch.onlinelibrary.wiley.com/doi/10.1049/iet-ipr.2018.5707
- https://www.scantips.com/basics06.html
- https://www.scantips.com/basics6b.html
