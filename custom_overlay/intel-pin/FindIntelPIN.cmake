find_path(IntelPIN_ROOT src/intel-pin)
message("intel root : ${IntelPIN_ROOT}")

set(TARGET_OS TARGET_${CMAKE_SYSTEM_NAME})
message(STATUS "cmake_system_processor ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "cmake_host_system_processor ${CMAKE_HOST_SYSTEM_PROCESSOR}")
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
	set(TARGET_ARCH TARGET_${CMAKE_SYSTEM_PROCESSOR})
else()
endif()
set(HOST_ARCH HOST_${CMAKE_HOST_SYSTEM_PROCESSOR})

#intel-pin/pin-external-3.31-98861-g71afcc22f-gcc-linux
set(IntelPIN_FOUND FALSE)
if(IntelPIN_ROOT)
  set(IntelPIN_FOUND TRUE)
    # Automatically detect the subfolder in the zip
    #file(GLOB PIN_DIR LIST_DIRECTORIES true ${IntelPIN_SOURCE_DIR}/pin-*)
    set(PIN_DIR ${IntelPIN_ROOT}/src/intel-pin)
		message("pindir : ${PIN_DIR}")
    # Loosely based on ${PIN_DIR}/source/tools/Config/makefile.win.config
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(PIN_EXE "${PIN_DIR}/intel64/bin/pin${CMAKE_EXECUTABLE_SUFFIX}")
    else()
        set(PIN_EXE "${PIN_DIR}/ia32/bin/pin${CMAKE_EXECUTABLE_SUFFIX}")
    endif()
    string(REGEX REPLACE "/" "\\\\" PIN_EXE ${PIN_EXE})

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

  #if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  #target_link_options(IntelPIN INTERFACE /NODEFAULTLIB /EXPORT:main /BASE:0xC5000000 /ENTRY:Ptrace_DllMainCRTStartup /IGNORE:4210 /IGNORE:4281)
  # else()
  #     target_link_options(IntelPIN INTERFACE /NODEFAULTLIB /EXPORT:main /BASE:0x55000000 /ENTRY:Ptrace_DllMainCRTStartup@12 /IGNORE:4210 /IGNORE:4281 /SAFESEH:NO)
  # endif()

    #target_compile_options(IntelPIN INTERFACE /GR- /GS- /EHs- /EHa- /fp:strict /Oi- /FIinclude/msvc_compat.h /wd5208)

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        target_include_directories(IntelPIN INTERFACE
            ${PIN_DIR}/extras/xed-intel64/include/xed
						#${PIN_DIR}/extras/crt/include/arch-x86_64
        )
        target_link_directories(IntelPIN INTERFACE
            ${PIN_DIR}/intel64/lib
            ${PIN_DIR}/intel64/lib-ext
						${PIN_DIR}/intel64/runtime/pincrt
            ${PIN_DIR}/extras/xed-intel64/lib
        )
      target_compile_definitions(IntelPIN INTERFACE
            TARGET_IA32E
            HOST_IA32E
      #      TARGET_WINDOWS
						TARGET_LINUX
            __PIN__=1
						PIN_CRT=1
            __LP64__
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
          #  ${PIN_DIR}/intel64/runtime/pincrt/crtbeginS.obj
					)
    else()
        target_include_directories(IntelPIN INTERFACE
            ${PIN_DIR}/extras/xed-ia32/include/xed
						#${PIN_DIR}/extras/crt/include/arch-x86
        )
        target_link_directories(IntelPIN INTERFACE
            ${PIN_DIR}/ia32/lib
            ${PIN_DIR}/ia32/lib-ext
						#${PIN_DIR}/ia32/runtime/pincrt
            ${PIN_DIR}/extras/xed-ia32/lib
        )
      target_compile_definitions(IntelPIN INTERFACE
           TARGET_IA32
           HOST_IA32
      #     TARGET_WINDOWS
					 TARGET_LINUX
           __PIN__=1
           PIN_CRT=1
           __i386__
      #     _WINDOWS_H_PATH_=../um # dirty hack
       )
        target_link_libraries(IntelPIN INTERFACE
          #     ntdll-32
          # kernel32
          	c++abi
						c-dynamic
						c++
						dl-dynamic
						m-dynamic
						unwind-dynamic

						#${PIN_DIR}/ia32/runtime/pincrt/*
          #  ${PIN_DIR}/ia32/runtime/pincrt/crtbeginS.obj
        )
    endif()

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
