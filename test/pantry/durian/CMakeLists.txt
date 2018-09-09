cmake_minimum_required (VERSION 3.5)

project (Durian
  VERSION 8.1.6
  LANGUAGES CXX)

option (Durian_INSTALL
  "Install targets."
  ON)

option (Durian_SHARED
  "Build a shared library."
  ON)

if (NOT (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR))
  set (Durian_INSTALL OFF)
endif ()

set (BUILD_SHARED_LIBS Durian_SHARED)

add_library (durian
  include/durian/apply.hh
  src/apply.cc)

target_include_directories (durian
  PUBLIC
    $<INSTALL_INTERFACE:include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

#
# Installation and export.
#

if (Durian_INSTALL)
  include (GNUInstallDirs)
  include (CMakePackageConfigHelpers)

  set (install_cmakedir ${CMAKE_INSTALL_LIBDIR}/cmake/Durian)

  install (
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

  install (
    TARGETS durian
    EXPORT durian-export
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

  install (
    EXPORT durian-export
    FILE DurianTargets.cmake
    NAMESPACE Durian::
    DESTINATION ${install_cmakedir})

  write_basic_package_version_file (
    ${CMAKE_CURRENT_BINARY_DIR}/DurianConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)

  configure_package_config_file (
    ${CMAKE_CURRENT_LIST_DIR}/cmake/DurianConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/DurianConfig.cmake
    INSTALL_DESTINATION ${install_cmakedir})

  install (
    FILES
      ${CMAKE_CURRENT_BINARY_DIR}/DurianConfig.cmake
      ${CMAKE_CURRENT_BINARY_DIR}/DurianConfigVersion.cmake
    DESTINATION ${install_cmakedir})
endif ()
