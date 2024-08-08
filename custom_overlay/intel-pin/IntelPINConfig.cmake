find_path(IntelPIN_ROOT src/intel-pin)
message("intel root : ${IntelPIN_ROOT}")

message(STATUS "cmake_system_processor ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "cmake_host_system_processor ${CMAKE_HOST_SYSTEM_PROCESSOR}")
message(STATUS "CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS}")
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "i386" OR CMAKE_CXX_FLAGS MATCHES "-m32")
  set(TARGET_ARCH TARGET_IA32)
  set(INTEL_ARCH ia32)
  set(ARCH x86)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "(x86_64|AMD64)")
  set(TARGET_ARCH TARGET_IA32E)
  set(INTEL_ARCH intel64)
  set(ARCH x86_64)
else()
  message(
    FATAL_ERROR
      "currently, ${CMAKE_SYSTEM_PROCESSOR} is not supported architecture")
endif()

if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL
                                               "AMD64")
  set(HOST_ARCH HOST_IA32E)
elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "i386")
  set(HOST_ARCH HOST_IA32)
else()
  message(
    FATAL_ERROR
      "currently, ${CMAKE_HOST_SYSTEM_PROCESSOR} is not supported host architecture"
  )
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  message(STATUS "cmake compiler id ${CMAKE_CXX_COMPILER_ID}")
  if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    message(FATAL_ERROR "IntelPIN only supports gcc/g++ in linux")
  endif()
  set(TARGET_OS TARGET_LINUX)

elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(TARGET_OS TARGET_WINDOWS)
  if(TARGET_ARCH STREQUAL TARGET_IA32E)
    set(LP_SIZE __LP64__)
  else()
    set(LP_SIZE __i386__)
  endif()

else()
  message(
    FATAL_ERROR "can't find ${CMAKE_SYSTEM_NAME} in supported system list")
endif()

set(IntelPIN_FOUND FALSE)
if(IntelPIN_ROOT)
  set(IntelPIN_FOUND TRUE)
  # Automatically detect the subfolder in the zip file(GLOB PIN_DIR
  # LIST_DIRECTORIES true ${IntelPIN_SOURCE_DIR}/pin-*)
  set(PIN_DIR ${IntelPIN_ROOT}/src/intel-pin)
  message("pindir : ${PIN_DIR}")
  # Loosely based on ${PIN_DIR}/source/tools/Config/makefile.win.config
  set(PIN_EXE "${PIN_DIR}/${INTEL_ARCH}/bin/pin${CMAKE_EXECUTABLE_SUFFIX}")

  # string(REGEX REPLACE "/" "\\\\" PIN_EXE ${PIN_EXE})

  add_library(IntelPIN INTERFACE)

  target_include_directories(
    IntelPIN SYSTEM
    INTERFACE ${PIN_DIR}/extras/crt/include
              ${PIN_DIR}/extras/crt/include/kernel/uapi
              ${PIN_DIR}/extras/crt/include/kernel/uapi/asm-x86)

  target_include_directories(
    IntelPIN
    INTERFACE ${PIN_DIR}/source/include/pin
              ${PIN_DIR}/source/include/pin/gen
              ${PIN_DIR}/extras/components/include
              ${PIN_DIR}/extras/stlport/include
              ${PIN_DIR}/extras
              ${PIN_DIR}/extras/cxx/include
              ${PIN_DIR}/extras/crt/include/arch-x86_64
              ${PIN_DIR}/extras/libstdc++/include
              ${PIN_DIR}/extras/crt)

  set_target_properties(IntelPIN PROPERTIES POSITION_INDEPENDENT_CODE ON)
  target_include_directories(
    IntelPIN INTERFACE ${PIN_DIR}/extras/xed-${INTEL_ARCH}/include/xed
                       ${PIN_DIR}/extras/crt/include/arch-${ARCH})
  target_link_directories(
    IntelPIN INTERFACE ${PIN_DIR}/${INTEL_ARCH}/lib
    ${PIN_DIR}/${INTEL_ARCH}/lib-ext ${PIN_DIR}/${INTEL_ARCH}/runtime/pincrt
    ${PIN_DIR}/extras/xed-${INTEL_ARCH}/lib)
  message(
    STATUS
      "target arch ${TARGET_ARCH} host arch ${HOST_ARCH} target_os ${TARGET_OS}"
  )
  target_compile_definitions(
    IntelPIN INTERFACE ${TARGET_ARCH} ${HOST_ARCH} ${TARGET_OS} __PIN__=1
                       PIN_CRT=1)
  target_link_libraries(
    IntelPIN
    INTERFACE
      pin
      xed
      ${PIN_DIR}/${INTEL_ARCH}/runtime/pincrt/crtbeginS${CMAKE_CXX_OUTPUT_EXTENSION}
  )

  # target specific configuration
  if(TARGET_OS STREQUAL "TARGET_LINUX")
    target_compile_options(
      IntelPIN
      INTERFACE -Wl,--hash-style=sysv
                -nostdlib
                -funwind-tables
                -fasynchronous-unwind-tables
                -fno-stack-protector
                -fno-exceptions
                -fabi-version=2
                -faligned-new)
    target_link_options(IntelPIN INTERFACE -Wl,--hash-style=sysv -nostdlib
                        -fabi-version=2 -faligned-new)
    # below go to library private
    target_link_options(
      IntelPIN INTERFACE -Wl,-Bsymbolic
      -Wl,--version-script=${PIN_DIR}/source/include/pin/pintool.ver
      -fabi-version=2)
    target_link_libraries(
      IntelPIN
      INTERFACE
        c++
        c++abi
        c-dynamic
        dl-dynamic
        m-dynamic
        unwind-dynamic
        pindwarf
        dwarf
        ${PIN_DIR}/${INTEL_ARCH}/runtime/pincrt/crtendS${CMAKE_CXX_OUTPUT_EXTENSION}
    )
    # target_link_options(${target} PRIVATE -nostdlib)
  elseif(TARGET_OS STREQUAL "TARGET_WINDOWS")

    target_link_libraries(IntelPIN INTERFACE # pinvm
                                             pincrt pinipc kernel32)
    target_link_options(
      IntelPIN
      INTERFACE
      /NODEFAULTLIB
      /EXPORT:main
      /BASE:0xC5000000
      /ENTRY:Ptrace_DllMainCRTStartup
      /IGNORE:4210
      /IGNORE:4281)
    # else() 32bit target_link_options(IntelPIN INTERFACE /NODEFAULTLIB
    # /EXPORT:main /BASE:0x55000000 /ENTRY:Ptrace_DllMainCRTStartup@12
    # /IGNORE:4210 /IGNORE:4281 /SAFESEH:NO)
    target_compile_options(
      IntelPIN
      INTERFACE /GR-
                /GS-
                /EHs-
                /EHa-
                /fp:strict
                /Oi-
                /FIinclude/msvc_compat.h
                /wd5208)
    target_compile_definitions(
      IntelPIN INTERFACE PIN_CRT=1 ${LP_SIZE} # _WINDOWS_H_PATH_=../um # dirty
                                              # hack
    )
    # if host system is linux target_link_libraries(IntelPIN INTERFACE c++)
  endif()

  # Create a static library InstLib that is used in a lot of example pintools
  file(GLOB InstLib_SOURCES "${PIN_DIR}/source/tools/InstLib/*.cpp"
       "${PIN_DIR}/source/tools/InstLib/*.H")
  add_library(InstLib STATIC EXCLUDE_FROM_ALL ${InstLib_SOURCES})
  target_include_directories(InstLib PUBLIC "${PIN_DIR}/source/tools/InstLib")
  target_link_libraries(InstLib PUBLIC IntelPIN)

  function(add_pintool target)
    add_library(${target} SHARED ${ARGN})
    target_link_libraries(${target} PRIVATE IntelPIN)
  endfunction()
endif()
