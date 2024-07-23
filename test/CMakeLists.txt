cmake_minimum_required(VERSION 3.22)



project(mypin  LANGUAGES CXX)

include(../custom_overlay/intel-pin/FindIntelPIN.cmake)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_STANDARD
    17
    CACHE STRING "the C++ standard to use for this project")
set(CMAKE_CXX_STANDARD_REQUIRED On)

message(STATUS "intelpin found : ${IntelPIN_FOUND}")
add_executable(profiler profiler.cpp)
#add_executable(profiler test.cpp)
target_link_libraries(profiler IntelPIN)
