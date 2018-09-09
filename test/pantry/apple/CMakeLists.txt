cmake_minimum_required (VERSION 3.5)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include (Cooking OPTIONAL)

project (Apple
  VERSION 6.0.0
  LANGUAGES CXX)

option (Apple_INSTALL
  "Install targets."
  ON)

if (NOT (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR))
  set (Apple_INSTALL OFF)
endif ()

find_package (Banana 20.4.1 REQUIRED)
find_package (Egg 2.5.1 REQUIRED)

add_executable (apple
  src/main.cc)

target_include_directories (apple
  PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries (apple
  PRIVATE
    Banana::banana
    Egg::egg)

#
# Installation and export.
#

if (Apple_INSTALL)
  include (GNUInstallDirs)
  include (CMakePackageConfigHelpers)

  set (install_cmakedir ${CMAKE_INSTALL_LIBDIR}/cmake/Apple)

  install (
    TARGETS apple
    EXPORT apple-export
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

  install (
    EXPORT apple-export
    FILE AppleTargets.cmake
    NAMESPACE Apple::
    DESTINATION ${install_cmakedir})

  write_basic_package_version_file (
    ${CMAKE_CURRENT_BINARY_DIR}/AppleConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)

  configure_package_config_file (
    ${CMAKE_CURRENT_LIST_DIR}/cmake/AppleConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/AppleConfig.cmake
    INSTALL_DESTINATION ${install_cmakedir})

  install (
    FILES
      ${CMAKE_CURRENT_BINARY_DIR}/AppleConfig.cmake
      ${CMAKE_CURRENT_BINARY_DIR}/AppleConfigVersion.cmake
    DESTINATION ${install_cmakedir})
endif ()
