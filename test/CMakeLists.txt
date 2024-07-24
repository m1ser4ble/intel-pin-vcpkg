cmake_minimum_required(VERSION 3.22)



project(mypin  LANGUAGES CXX)

#include(../custom_overlay/intel-pin/FindIntelPIN.cmake)
find_package(IntelPIN CONFIG REQUIRED)

set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_STANDARD
    17
    CACHE STRING "the C++ standard to use for this project")
set(CMAKE_CXX_STANDARD_REQUIRED On)

message(STATUS "intelpin found : ${IntelPIN_FOUND}")
add_pintool(profiler profiler.cpp)
