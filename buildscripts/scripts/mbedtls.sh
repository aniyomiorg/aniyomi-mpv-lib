#!/bin/bash -e

. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	make clean
	exit 0
else
	exit 255
fi

$0 clean # separate building not supported, always clean
if [[ "$ndk_triple" == "i686"* ]]; then
	./scripts/config.py unset MBEDTLS_AESNI_C
else
	./scripts/config.py set MBEDTLS_AESNI_C
fi

# Without threading support the PSA key store and RNG are not thread-safe, and
# concurrent TLS sessions (several inputs, or mpv playback and ffmpeg-kit
# downloads sharing this libavformat) corrupt memory.
./scripts/config.py set MBEDTLS_THREADING_C
./scripts/config.py set MBEDTLS_THREADING_PTHREAD

# Bionic has pthreads in libc and the NDK ships no libpthread. Once the
# options above are set, the Makefile auto-detects THREADING=pthread and adds
# -lpthread, which fails to link the programs; any other value skips that.
make -j$cores no_test THREADING=bionic
make DESTDIR="$prefix_dir" install THREADING=bionic
