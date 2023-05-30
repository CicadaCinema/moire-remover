#!/bin/bash

clang main.c qdbmp.c -Wall -Wextra -Wpedantic -Wconversion -lfftw3 -lz -lm -o temp.out
./temp.out pattern.bmp pattern_preview.bmp
rm temp.out
