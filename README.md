cmake-cooking - Development environments for CMake projects
-----------------------------------------

`cmake-cooking` is an extremely thin layer over CMake for creating flexible and reproducible development environments for CMake projects. Projects which use `cmake-cooking` will work even if `cmake-cooking` is not installed or used.

## Motivation

A modern CMake project should allow its dependencies to be satisfied arbitrarily through the `find_package` mechanism in order to maximize flexibility and composability with other projects.

`cmake-cooking` allows you to easily create development environments (including all dependencies) for modern CMake projects. These dependencies are seamlessly fetched, configured, and built.

`cmake-cooking` is similar to the  "superbuild" concept (in CMake-parlance). Its implementation wraps the `ExternalProject` module included in CMake.

## Usage

Simply copy `cooking.sh` into your project's root source directory.

Your `CMakeLists.txt` file is unchanged except for these two lines after the mandatory `cmake_minimum_required` statement:

```CMake
list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include (Cooking OPTIONAL)
```

With `cmake-cooking`, all of your dependencies must be specified in `CMakeLists.txt` **exclusively** with `find_package`, like so:

```CMake
find_package (Boost 1.64.0 REQUIRED)
```

In this way, the choice of how to **satisfy** the dependencies is flexible.

Instead of running `cmake` to configure the project, run `cooking.sh`. This will:

 - Generate `cmake/Cooking.cmake` in the source directory. This file should **not** be tracked in version control
 - Create the build directory
 - If a recipe is included (with the `-r` option) then fetch, configure, and build all dependencies of the project
 - Configure the project

# References

- ["Effective CMake" from C++Now 2017](https://www.youtube.com/watch?v=bsXLMQ6WgIk)
- [It's Time To Do CMake Right](https://pabloariasal.github.io/2018/02/19/its-time-to-do-cmake-right/)
