# intel-pin-vcpkg
vcpkg port for intel-pin, the dynamic binary instrumentation tool


# test

```console
$ cd test
$ mkdir build && cd build
$ CC=gcc CXX=g++ cmake .. -DCMAKE_TOOLCHAIN_FILE=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake
$ make
```
