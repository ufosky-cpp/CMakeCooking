cmake_minimum_required (VERSION 3.5)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include (Cooking OPTIONAL)

project (Carrot
  VERSION 3.0.0
  LANGUAGES CXX)

option (Carrot_INSTALL
  "Install targets."
  ON)

option (Carrot_SHARED
  "Build a shared library."
  ON)

if (NOT (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR))
  set (Carrot_INSTALL OFF)
endif ()

find_package (Durian 8.1.6 REQUIRED)
find_package (Egg 2.5.1 REQUIRED)

set (BUILD_SHARED_LIBS Carrot_SHARED)

add_library (carrot
  include/carrot/apply.hh
  src/apply.cc)

target_include_directories (carrot
  PUBLIC
    $<INSTALL_INTERFACE:include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries (carrot
  PRIVATE
    Durian::durian
    Egg::egg)

#
# Installation and export.
#

if (Carrot_INSTALL)
  include (GNUInstallDirs)
  include (CMakePackageConfigHelpers)

  set (install_cmakedir ${CMAKE_INSTALL_LIBDIR}/cmake/Carrot)

  install (
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

  install (
    TARGETS carrot
    EXPORT carrot-export
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

  install (
    EXPORT carrot-export
    FILE CarrotTargets.cmake
    NAMESPACE Carrot::
    DESTINATION ${install_cmakedir})

  write_basic_package_version_file (
    ${CMAKE_CURRENT_BINARY_DIR}/CarrotConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)

  configure_package_config_file (
    ${CMAKE_CURRENT_LIST_DIR}/cmake/CarrotConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/CarrotConfig.cmake
    INSTALL_DESTINATION ${install_cmakedir})

  install (
    FILES
      ${CMAKE_CURRENT_BINARY_DIR}/CarrotConfig.cmake
      ${CMAKE_CURRENT_BINARY_DIR}/CarrotConfigVersion.cmake
    DESTINATION ${install_cmakedir})
endif ()
