cmake_minimum_required(VERSION 3.22)



project(mypin  LANGUAGES CXX)

include(custom_overlay/intel-pin/FindIntelPIN.cmake)
message(STATUS "intelpin found : ${IntelPIN_FOUND}")
add_executable(profiler profiler.cpp)
target_link_libraries(profiler IntelPIN)
