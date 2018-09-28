cmake-cooking - Reproducible development environments for CMake projects
-----------------------------------------

`cmake-cooking` is a thin layer over CMake for creating flexible and reproducible development environments for CMake projects with external dependencies. Projects which use `cmake-cooking` will work even if `cmake-cooking` is not installed or used.

## Quick-start

Please read the "Motivation" below.

To understand the underlying model for `cmake-cooking`, see [UNDERSTAND.md](./UNDERSTAND.md).

To understand how to use `cmake-cooking` with your project, see [APPLY.md](./APPLY.md).

## Repository structure

The only file necessary for using `cmake-cooking` in your C or C++ project is [`cooking.sh`](./cooking.sh).

The other files and directories are strictly for modelling and testing`cmake-cooking` itself.

- `lib/model` is a library implementing in OCaml the model described in [UNDERSTAND.md](./UNDERSTAND.md). It is tested in `test/model`
- `lib/testing` is a very small library for running tests (independent of any particular thing being tested)
- `lib/interaction` is a library for running `cmake` and `cmake-cooking` interactively. This is especially useful for defining integration tests
- `test/integration` defines all the integration tests for `cmake-cooking`
- `pantry` is a set of example C++ projects which are tested with `cmake-cooking` in integration tests. These projects are also useful examples of how to apply `cmake-cooking` to your own projects

A [`Makefile`](./Makefile) exists for convenience. For example, to execute all tests (including unit tests, model tests, and integration tests) you can execute

    make test

## Motivation

Some C++ projects have *external dependencies*. These are libraries and executables that are external to the project itself (for example, Boost).

It is important that the build-system for a project is independent of these external dependencies. The build system should *only* query for their availability and know how to invoke the compiler appropriately.

The reason for this is to make it as easy as possible to integrate your project in as many environments as possible (where external dependencies can be supplied in many different ways and with many different requirements).

Good instructions for how to structure your project effectively with CMake to achieve this goal are available in the "References" section below.

Once the build is independent of your project's external dependencies, then the question of *how* to supply dependencies is important.

Some options are:

- System dependencies (like those installed with `apt-get` or `dnf`)
- C++-specific package managers (like [Conan](https://github.com/conan-io/conan))
- Manual installation (`./configure && make install`)

Each of these has benefits and disadvantages which vary based on the needs of your work-flow.

One problem with the first option -- system dependencies -- is that different distributions of Linux include packages at different versions and that versions of packages can change silently as the distribution is upgraded. In both cases, the issue is that developers may be working and debugging in fundamentally different environments and this makes collaboration and rigorous engineering challenging.

`cmake-cooking` is a lightweight way to precisely specify exact requirements on external dependencies that can be reproduced on (mostly) any system. These external dependencies are quickly fetched, configured, and installed in a project-specific location.

`cmake-cooking` can be used *selectively*. It is possible to use `cmake-cooking` for *some* dependencies which are not accessible otherwise while supplying other dependencies through other means (like system packages).

`cmake-cooking` is similar to the  "superbuild" concept (in CMake-parlance). Its implementation wraps the `ExternalProject` module included in CMake.

## Dependencies

- [GNU Stow](https://www.gnu.org/software/stow/)

## Usage

Simply copy `cooking.sh` into your project's root source directory.

Your `CMakeLists.txt` file is unchanged except for these two lines after the mandatory `cmake_minimum_required` statement:

```CMake
list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include (Cooking OPTIONAL)
```

# References

- ["Effective CMake" from C++Now 2017](https://www.youtube.com/watch?v=bsXLMQ6WgIk)
- [It's Time To Do CMake Right](https://pabloariasal.github.io/2018/02/19/its-time-to-do-cmake-right/)
