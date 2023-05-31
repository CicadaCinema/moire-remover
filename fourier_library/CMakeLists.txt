cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
project(fourier_library VERSION 1.0.0 LANGUAGES C)
add_library(fourier_library SHARED fourier_library.c fourier_library.def)
target_link_libraries(fourier_library fftw3)
target_link_libraries(fourier_library m)
target_link_libraries(fourier_library z)

set_target_properties(fourier_library PROPERTIES
    PUBLIC_HEADER fourier_library.h
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    OUTPUT_NAME "fourier_library"
)
