cmake_minimum_required (VERSION 3.5)

project (Egg
  VERSION 2.5.1
  LANGUAGES CXX)

option (Egg_INSTALL
  "Install targets."
  ON)

option (Egg_SHARED
  "Build a shared library."
  ON)

if (NOT (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR))
  set (Egg_INSTALL OFF)
endif ()

set (BUILD_SHARED_LIBS Egg_SHARED)

add_library (egg
  include/egg/apply.hh
  src/apply.cc)

target_include_directories (egg
  PUBLIC
    $<INSTALL_INTERFACE:include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

#
# Installation and export.
#

if (Egg_INSTALL)
  include (GNUInstallDirs)
  include (CMakePackageConfigHelpers)

  set (install_cmakedir ${CMAKE_INSTALL_LIBDIR}/cmake/Egg)

  install (
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

  install (
    TARGETS egg
    EXPORT egg-export
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

  install (
    EXPORT egg-export
    FILE EggTargets.cmake
    NAMESPACE Egg::
    DESTINATION ${install_cmakedir})

  write_basic_package_version_file (
    ${CMAKE_CURRENT_BINARY_DIR}/EggConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)

  configure_package_config_file (
    ${CMAKE_CURRENT_LIST_DIR}/cmake/EggConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/EggConfig.cmake
    INSTALL_DESTINATION ${install_cmakedir})

  install (
    FILES
      ${CMAKE_CURRENT_BINARY_DIR}/EggConfig.cmake
      ${CMAKE_CURRENT_BINARY_DIR}/EggConfigVersion.cmake
    DESTINATION ${install_cmakedir})
endif ()
