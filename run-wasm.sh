#!/bin/bash

NATIVE_SCAL="build-native-scalar"
NATIVE_SIMD="build-native-simd"
SCAL="build-wasm-scalar"
SIMD="build-wasm-simd"
D8=$HOME/v8/out/x64.release/d8
TESTIMAGES=(
  testimages/vgl_5674_0098.bmp
  testimages/vgl_6434_0018.ppm
  testimages/vgl_6548_0026.ppm
)
TESTARGS=(95 -rgb -qq -nowrite -warmup 10)

# build
(
  mkdir "$NATIVE_SCAL"
  cd "$NATIVE_SCAL"
  cmake -G 'Ninja' .. -DWITH_SIMD=0
  ninja
) &
(
  mkdir "$NATIVE_SIMD"
  cd "$NATIVE_SIMD"
  cmake -G 'Ninja' .. -DWITH_SIMD=1
  ninja
) &
(
  mkdir "$SCAL"
  cd "$SCAL"
  emcmake cmake -G 'Ninja' .. -DWITH_SIMD=0
  ninja
) &
(
  mkdir "$SIMD"
  cd "$SIMD"
  emcmake cmake -G 'Ninja' .. -DNEON_INTRINSICS=1
  ninja
) &

wait

# run benchmarks

# run native as a baseline

(
  cd "$NATIVE_SCAL"
  for image in "${TESTIMAGES[@]}"; do
    tjbench "../${TESTIMAGES[0]}" "${TESTARGS[@]}"
  done
) > native-scalar.txt

(
  cd "$NATIVE_SIMD"
  for image in "${TESTIMAGES[@]}"; do
    tjbench "../${TESTIMAGES[0]}" "${TESTARGS[@]}"
  done
) > native-simd.txt

exit

# See
# https://docs.google.com/spreadsheets/d/1uOXDFYymhonJAWFjLnlGb1z5rjlQOVwMGsEGzZfk66g/edit#gid=1476929598
# for https://libjpeg-turbo.org/pmwiki/uploads/About/libjpegturbo-1.5.ods
# imported into Google Sheets.

# Reference command:
#   tjbench {file} 95 -rgb -qq -nowrite -warmup 10
#
# -qq will write output in tabular form, it will be for 4 different
# chrominance subsampling setting: Grayscale, 4:2:0, 4:2:2, 4:4:4. Each will
# have 4 numbers in the output, compression perf (Megapixels/sec), compression
# ratio, decompression perf (Megapixels/sec).

# scalar
(
  cd "$SCAL"
  for image in "${TESTIMAGES[@]}"; do
    "$D8" tjbench.js -- "${TESTIMAGES[0]}" "${TESTARGS[@]}"
  done
) > scalar.txt

# SIMD
(
  cd "$SIMD"
  for image in "${TESTIMAGES[@]}"; do
    "$D8" tjbench.js -- "${TESTIMAGES[0]}" "${TESTARGS[@]}"
  done
) > simd.txt
