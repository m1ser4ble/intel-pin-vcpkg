# intel-pin-vcpkg
vcpkg port for intel-pin, the dynamic binary instrumentation tool

For more information about vcpkg, see [vcpkg](https://github.com/microsoft/vcpkg) project

# test

```console
$ cd test
$ mkdir build && cd build
$ CC=gcc CXX=g++ cmake .. --preset=release
$ ninja
```
