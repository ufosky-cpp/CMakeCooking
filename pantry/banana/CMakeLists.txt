cmake_minimum_required (VERSION 3.5)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include (Cooking OPTIONAL)

project (Banana
  VERSION 20.4.1
  LANGUAGES CXX)

option (Banana_INSTALL
  "Install targets."
  ON)

option (Banana_SHARED
  "Build a shared library."
  ON)

if (NOT (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR))
  set (Banana_INSTALL OFF)
endif ()

find_package (Carrot 3.0.0 REQUIRED)
find_package (Durian 8.1.6 REQUIRED)

set (BUILD_SHARED_LIBS Banana_SHARED)

add_library (banana
  include/banana/apply.hh
  src/apply.cc)

target_include_directories (banana
  PUBLIC
    $<INSTALL_INTERFACE:include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries (banana
  PRIVATE
    Carrot::carrot
    Durian::durian)

#
# Installation and export.
#

if (Banana_INSTALL)
  include (GNUInstallDirs)
  include (CMakePackageConfigHelpers)

  set (install_cmakedir ${CMAKE_INSTALL_LIBDIR}/cmake/Banana)

  install (
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

  install (
    TARGETS banana
    EXPORT banana-export
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

  install (
    EXPORT banana-export
    FILE BananaTargets.cmake
    NAMESPACE Banana::
    DESTINATION ${install_cmakedir})

  write_basic_package_version_file (
    ${CMAKE_CURRENT_BINARY_DIR}/BananaConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)

  configure_package_config_file (
    ${CMAKE_CURRENT_LIST_DIR}/cmake/BananaConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/BananaConfig.cmake
    INSTALL_DESTINATION ${install_cmakedir})

  install (
    FILES
      ${CMAKE_CURRENT_BINARY_DIR}/BananaConfig.cmake
      ${CMAKE_CURRENT_BINARY_DIR}/BananaConfigVersion.cmake
    DESTINATION ${install_cmakedir})
endif ()
