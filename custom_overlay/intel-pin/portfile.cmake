#vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

set(sha "0")
if(NOT VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    # nop
elseif(VCPKG_TARGET_IS_WINDOWS)
	# currently, not able to support clang
  set(compiler msvc)
  set(os windows)
  set(compress zip)
	set(sha 3e704e83d861f093e48b78a45a21e9e10889436a417a39c5dff67709d92dabd6f624bdcb7eb10756ff2385437978a463c0d50f84c90ffac8957366d5efea0658)

elseif(VCPKG_TARGET_IS_OSX)
  set(compiler clang)
  set(os mac)
  set(compress tar.gz)
	#set(sha 7b9b8c004054603e6830fb9b9c049d5a4cfc0990c224cb182ac5262ab9f1863775a67491413040e3349c590e2cca58edcfc704db9f3b022cd2af)
elseif(VCPKG_TARGET_IS_LINUX)
  set(compiler gcc)
  set(os linux)
  set(compress tar.gz)
  set(filename pin.${compress})
  set(sha 
		5d502718a2d4e0fa438626a52f8d8ebe37357602489a7b1d76d99d2916ab6d797e21c703e6f24685c72482304415abd8673134058b75af6d374e89b91e9c098e)

endif()

#if(NOT sha)
#  message(WARNING "${PORT} is empty for ${TARGET_TRIPLET}.")
#  return()
#endif()

vcpkg_download_distfile(installer_path
#"https://software.intel.com/sites/landingpage/pintool/downloads/pin-external-3.31-98861-g71afcc22f-msvc-windows.zip"
#"https://software.intel.com/sites/landingpage/pintool/downloads/pin-external-3.31-98861-g71afcc22f-clang-windows.zip"
    URLS "https://software.intel.com/sites/landingpage/pintool/downloads/pin-external-3.31-98861-g71afcc22f-${compiler}-${os}.${compress}"
    #URLS "https://software.intel.com/sites/landingpage/pintool/downloads/pin-external-3.31-98861-g71afcc22f-gcc-linux.tar.gz"
    #URLS "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/${magic_number}/${filename}"
    FILENAME "pin-external-3.31-98861-g71afcc22f-${compiler}-${os}.${compress}"
		SHA512 "${sha}"
)

set(extract_0_dir "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-extract")
file(REMOVE_RECURSE "${extract_0_dir}")
file(MAKE_DIRECTORY "${extract_0_dir}")

if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_find_acquire_program(7Z)
    message(STATUS "Extracting offline installer")
    vcpkg_execute_required_process(
        COMMAND "${7Z}" x "${installer_path}" "-o${extract_0_dir}" "-y" "-bso0" "-bsp0"
        WORKING_DIRECTORY "${extract_0_dir}"
        LOGNAME "extract-${TARGET_TRIPLET}-0"
    )
else()
  if(VCPKG_TARGET_IS_LINUX)
      vcpkg_execute_required_process(
          COMMAND "tar" "-xzf" "${installer_path}"
          WORKING_DIRECTORY "${extract_0_dir}"
          LOGNAME "extract-${TARGET_TRIPLET}-0"
      )
    file(RENAME "${extract_0_dir}/pin-external-3.31-98861-g71afcc22f-${compiler}-${os}" "${extract_0_dir}/intel-pin")
    set(pin_dir ${extract_0_dir}/intel-pin)
		#file(COPY "${pin_dir}/intel64/bin" DESTINATION "${CURRENT_PACKAGES_DIR}")
		#file(COPY "${pin_dir}/intel64/lib" DESTINATION "${CURRENT_PACKAGES_DIR}")
    #file(COPY "${pin_dir}/intel64/runtime/pincrt" DESTINATION "${CURRENT_PACKAGES_DIR}/lib")
    file(COPY "${pin_dir}" DESTINATION "${CURRENT_PACKAGES_DIR}/src")
    #file(COPY "${pin_dir}/extras" DESTINATION "${CURRENT_PACKAGES_DIR}/pintool/extras")
    #file(RENAME "${extract_0_dir}/l_onemkl_p_2023.0.0.25398_offline/packages" "${extract_0_dir}/packages")
  elseif(VCPKG_TARGET_IS_OSX)
  endif()
endif()

#file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${pin_dir}/source/include/pin" DESTINATION "${CURRENT_PACKAGES_DIR}/include/pin")

file(INSTALL 
	"${CMAKE_CURRENT_LIST_DIR}/copyright"
	DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL 
	"${CMAKE_CURRENT_LIST_DIR}/IntelPINConfig.cmake" 
	DESTINATION "${CURRENT_PACKAGES_DIR}/share/intelpin")
configure_file("${CMAKE_CURRENT_LIST_DIR}/usage" "${CURRENT_PACKAGES_DIR}/share/${PORT}/usage" COPYONLY)
