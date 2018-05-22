cmake-cooking - Composable CMake projects
-----------------------------------------

`cmake-cooking` is a very thin layer over CMake (`CMakeLists.txt` files are compatible even if `cmake-cooking` is not installed) for creating composable and scalable builds with arbitrary and flexible dependencies.

## Motivation

`cmake-cooking` encourages modern CMake best practises (see "References" below) by enforcing that a project's build specification (and particularly how it finds its dependencies) allows it to be composed with other projects arbitrarily.

`cmake-cooking` also supports so-called "superbuilds" (in CMake-parlance) for reproducible and easy developer environments including all dependencies. It does this with the `ExternalProject` module included in CMake.

## Usage

Simply copy `configure.sh` into your project's root source directory.

Your `CMakeLists.txt` file is unchanged except for these two lines after the mandatory `cmake_minimum_required` statement:

```CMake
list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include (Cooking OPTIONAL)
```

With `cmake-cooking`, all of your dependencies are specified in `CMakeLists.txt` **exclusively** with `find_package`, like so:

```CMake
find_package (Boost 1.64.0 REQUIRED)
```

In this way, the choice of how to **satisfy** the dependencies is flexible and up to the particular developer. They can be:

- Installed on the system
- Specified manually in the CMake cache via `cmake` or the CMake GUI
- Specified in a "recipe" (a `cmake-cooking` concept), which is collection of "ingredients" (another concept). Each ingredient is really a CMake `ExternalProject`, the source of which can be fetched from version control (e.g., Git), found on the file-system, or at a remote address.

Instead of running `cmake` directly, run `configure.sh`. This will:

 - Generate `cmake/Cooking.cmake` in the source directory. This file should **not** be tracked in version control
 - Create the build directory
 - Optionally fetch, configure, and build all dependencies if they are specified in a recipe (with the `-r` option)
 - Configure the project

# Compatibility

A common work-flow with CMake is to embed projects inside other projects with `add_subdirectory`. This approach prevents projects from being composed arbitrarily. Nonetheless, `cmake-cooking` projects will work without modification when they are included in other projects this way. The cache variable `${project_name}_ROOT_PROJECT` is defined as `YES` only when the project is not embedded.

# Examples

The [CMakeWorkflows](https://gitlab.com/jhaberku/CMakeWorkflows) repository describes in some depth a work-flow with `cmake-cooking`. You may also be interested in the CMake specification of the [Pretty](https://gitlab.com/jhaberku/Pretty) and [Snake](https://gitlab.com/jhaberku/Snake) projects for reference.

# References

- ["Effective CMake" from C++Now 2017](https://www.youtube.com/watch?v=bsXLMQ6WgIk)
- [It's Time To Do CMake Right](https://pabloariasal.github.io/2018/02/19/its-time-to-do-cmake-right/)
