find_path(IntelPIN_ROOT src/intel-pin)
message("intel root : ${IntelPIN_ROOT}")

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	message(STATUS "cmake compiler id ${CMAKE_CXX_COMPILER_ID}")
	if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
		message(FATAL_ERROR "IntelPIN only supports gcc/g++ in linux")
		
	endif()
	set(TARGET_OS TARGET_LINUX)
endif()

message(STATUS "cmake_system_processor ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "cmake_host_system_processor ${CMAKE_HOST_SYSTEM_PROCESSOR}")
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
	set(TARGET_ARCH TARGET_IA32E)
	set(INTEL_ARCH intel64)
	set(ARCH x86_64)
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "i386")
	set(TARGET_ARCH TARGET_IA32)
	set(INTEL_ARCH ia32)
	set(ARCH x86)
else()
	message(FATAL_ERROR "currently, ${CMAKE_SYSTEM_PROCESSOR} is not supported architecture")
endif()

if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
	set(HOST_ARCH HOST_IA32E)
elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "i386")
	set(HOST_ARCH HOST_IA32)
else()
	message(FATAL_ERROR "currently, ${CMAKE_HOST_SYSTEM_PROCESSOR} is not supported host architecture")
endif()

set(IntelPIN_FOUND FALSE)
if(IntelPIN_ROOT)
  set(IntelPIN_FOUND TRUE)
    # Automatically detect the subfolder in the zip
    #file(GLOB PIN_DIR LIST_DIRECTORIES true ${IntelPIN_SOURCE_DIR}/pin-*)
    set(PIN_DIR ${IntelPIN_ROOT}/src/intel-pin)
		message("pindir : ${PIN_DIR}")
    # Loosely based on ${PIN_DIR}/source/tools/Config/makefile.win.config
		set(PIN_EXE "${PIN_DIR}/${INTEL_ARCH}/bin/pin${CMAKE_EXECUTABLE_SUFFIX}")
		
		#string(REGEX REPLACE "/" "\\\\" PIN_EXE ${PIN_EXE})

    add_library(IntelPIN INTERFACE)

		target_include_directories(IntelPIN SYSTEM INTERFACE
				${PIN_DIR}/extras/crt/include
				${PIN_DIR}/extras/crt/include/kernel/uapi
				${PIN_DIR}/extras/crt/include/kernel/uapi/asm-x86
			)

		target_include_directories(IntelPIN INTERFACE
        ${PIN_DIR}/source/include/pin
        ${PIN_DIR}/source/include/pin/gen
        ${PIN_DIR}/extras/components/include
        ${PIN_DIR}/extras/stlport/include
        ${PIN_DIR}/extras
				${PIN_DIR}/extras/cxx/include
				${PIN_DIR}/extras/crt/include/arch-x86_64
        ${PIN_DIR}/extras/libstdc++/include
				${PIN_DIR}/extras/crt
    )

    target_link_libraries(IntelPIN INTERFACE
        pin
        xed
				#pinvm
				#pincrt
    )
		target_compile_options(IntelPIN INTERFACE   -Wl,--hash-style=sysv  -nostdlib  -funwind-tables  -fasynchronous-unwind-tables -fno-stack-protector -fno-exceptions  -fabi-version=2 -faligned-new     )
		target_link_options(IntelPIN INTERFACE  -Wl,--hash-style=sysv   -nostdlib -fabi-version=2 -faligned-new   )
		# below go to library private
		target_link_options(IntelPIN INTERFACE -Wl,-Bsymbolic -Wl,--version-script=${PIN_DIR}/source/include/pin/pintool.ver  -fabi-version=2 )
		#target_link_options(${target} PRIVATE -nostdlib)
		set_target_properties(IntelPIN PROPERTIES  POSITION_INDEPENDENT_CODE ON)
  #if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  #target_link_options(IntelPIN INTERFACE /NODEFAULTLIB /EXPORT:main /BASE:0xC5000000 /ENTRY:Ptrace_DllMainCRTStartup /IGNORE:4210 /IGNORE:4281)
  # else()
  #     target_link_options(IntelPIN INTERFACE /NODEFAULTLIB /EXPORT:main /BASE:0x55000000 /ENTRY:Ptrace_DllMainCRTStartup@12 /IGNORE:4210 /IGNORE:4281 /SAFESEH:NO)
  # endif()
    #target_compile_options(IntelPIN INTERFACE /GR- /GS- /EHs- /EHa- /fp:strict /Oi- /FIinclude/msvc_compat.h /wd5208)

			target_include_directories(IntelPIN INTERFACE
				${PIN_DIR}/extras/xed-${INTEL_ARCH}/include/xed
				${PIN_DIR}/extras/crt/include/arch-${ARCH}
			)
			target_link_directories(IntelPIN INTERFACE
				${PIN_DIR}/${INTEL_ARCH}/lib
					${PIN_DIR}/${INTEL_ARCH}/lib-ext
					${PIN_DIR}/${INTEL_ARCH}/runtime/pincrt
					${PIN_DIR}/extras/xed-intel64/lib
			)
			set(LP_SIZE __LP64__)
			message(STATUS "target arch ${TARGET_ARCH} host arch ${HOST_ARCH} target_os ${TARGET_OS}")
		target_compile_definitions(IntelPIN INTERFACE
			${TARGET_ARCH}
			${HOST_ARCH}
			${TARGET_OS}
					__PIN__=1
					PIN_CRT=1
					${LP_SIZE}
		#      _WINDOWS_H_PATH_=../um # dirty hack
			)
			target_link_libraries(IntelPIN INTERFACE
					c++abi
					c-dynamic
					c++
					dl-dynamic
					m-dynamic
					unwind-dynamic
					pindwarf 
					dwarf 

				#ntdll-64
				#  kernel32
				#     ${PIN_DIR}/intel64/runtime/pincrt/*
				${PIN_DIR}/intel64/runtime/pincrt/crtbeginS.o 
				 ${PIN_DIR}/intel64/runtime/pincrt/crtendS.o
				)


    # Create a static library InstLib that is used in a lot of example pintools
    file(GLOB InstLib_SOURCES
        "${PIN_DIR}/source/tools/InstLib/*.cpp"
        "${PIN_DIR}/source/tools/InstLib/*.H"
    )
    add_library(InstLib STATIC EXCLUDE_FROM_ALL ${InstLib_SOURCES})
		target_include_directories(InstLib PUBLIC "${PIN_DIR}/source/tools/InstLib")
    target_link_libraries(InstLib PUBLIC IntelPIN)

    function(add_pintool target)
        add_library(${target} SHARED ${ARGN})
        target_link_libraries(${target} PRIVATE IntelPIN)
    endfunction()
endif()
