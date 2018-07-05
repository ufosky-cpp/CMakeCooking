#!/bin/bash

# MIT License
#
# Copyright (c) 2018 Jesse Haber-Kucharsky
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#
# This is cmake-cooking v0.4.0
#

set -e

CMAKE=${CMAKE:-cmake}

source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

recipe=""
declare -a excluded_ingredients
declare -a included_ingredients
build_dir="${source_dir}/build"
build_type="Debug"
# Depends on `build_dir`.
ingredients_dir=""
generator="Ninja"
list_only=""
nested=""

usage() {
    cat <<EOF

Fetch, configure, build, and install dependencies ("ingredients") for a CMake project
in a local and repeatable development environment.

Usage: $0 [OPTIONS]

where OPTIONS are:

-r RECIPE
-e INGREDIENT
-i INGREDIENT
-d BUILD_DIR (=${build_dir})
-p INGREDIENTS_DIR (=${build_dir}/_cooking/installed)
-t BUILD_TYPE (=${build_type})
-g GENERATOR (=${generator})
-l
-h

If neither [-i] nor [-e] are specified with a recipe ([-r]), then all ingredients of the recipe
will be fetched and built.

[-i] and [-e] are mutually-exclusive options: only provide one.

Option details:

-r RECIPE

    Prepare the named recipe. Recipes are stored in 'recipe/RECIPE.cmake'.
    If no recipe is indicated, then configure the build without any ingredients.

-e INGREDIENT

    Exclude an ingredient from a recipe. This option can be supplied many times.

    For example, if a recipe consists of 'apple', 'banana', 'carrot', and 'donut', then

        ./cooking.sh -r dev -e apple -e donut

    will prepare 'banana' and 'carrot' but not prepare 'apple' and 'donut'.

    If an ingredient is excluded, then it is assumed that all ingredients that depend on it
    can satisfy that dependency in some other way from the system (ie, the dependency is
    removed internally).

-i INGREDIENT

   Include an ingredient from a recipe, ignoring the others. This option can be supplied
   many times.

   Similar to [-e], but the opposite.

   For example, if a recipe consists of 'apple', 'banana', 'carrot', and 'donut' then

       ./cooking.sh -r dev -i apple -i donut

   will prepare 'apple' and 'donut' but not prepare 'banana' and 'carrot'.

   If an ingredient is not in the "include-list", then it is assumed that all
   ingredients that are in the list and which depend on it can satisfy that dependency
   in some other way from the system.

-d BUILD_DIR (=${build_dir})

   Configure the project and build it in the named directory.

-p INGREDIENTS_DIR (=${build_dir}/_cooking/installed)

   Install compiled ingredients into this directory.

-t BUILD_TYPE (=${build_type})

   Configure all ingredients and the project with the named CMake build-type.
   An example build type is "Release".

-g GENERATOR (=${generator})

    Use the named CMake generator for building all ingredients and the project.
    An example generator is "Unix Makfiles".

-l

    Only list available ingredients for a given recipe, and don't do anything else.

-h

    Show this help information and exit.

EOF
}

yell_include_exclude_mutually_exclusive() {
    echo "Cooking: [-e] and [-i] are mutually exclusive options!" >&2
}

while getopts "r:e:i:d:p:t:g:lhx" arg; do
    case "${arg}" in
        r) recipe=${OPTARG} ;;
        e)
            if [[ ${#included_ingredients[@]} -ne 0 ]]; then
                yell_include_exclude_mutually_exclusive
                exit 1
            fi

            excluded_ingredients+=(${OPTARG})
            ;;
        i)
            if [[ ${#excluded_ingredients[@]} -ne 0 ]]; then
                yell_include_exclude_mutually_exclusive
                exit 1
            fi

            included_ingredients+=(${OPTARG})
            ;;
        d) build_dir=$(realpath "${OPTARG}") ;;
        p) ingredients_dir=$(realpath "${OPTARG}") ;;
        t) build_type=${OPTARG} ;;
        g) generator=${OPTARG} ;;
        l) list_only="1" ;;
        h) usage; exit 0 ;;
        x) nested="1" ;;
        *) usage; exit 1 ;;
    esac
done

shift $((OPTIND - 1))

cooking_dir="${build_dir}/_cooking"
cmake_dir="${source_dir}/cmake"
cache_file="${build_dir}/CMakeCache.txt"
ingredients_ready_file="${cooking_dir}/ready.txt"

if [ -z "${ingredients_dir}" ]; then
    ingredients_dir="${cooking_dir}/installed"
fi

mkdir -p "${cmake_dir}"

cat <<'EOF' > "${cmake_dir}/Cooking.cmake"
# This file was generated by cmake-cooking v0.4.0.
# cmake-cooking is copyright 2018 by Jesse Haber-Kucharsky and
# available under the terms of the MIT license.

macro (project name)
  set (_cooking_dir ${CMAKE_CURRENT_BINARY_DIR}/_cooking)

  if (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set (_cooking_root ON)
  else ()
    set (_cooking_root OFF)
  endif ()

  find_program (Cooking_STOW_EXECUTABLE
    stow
    "Executable path of GNU Stow.")

  if (NOT Cooking_STOW_EXECUTABLE)
    message (FATAL_ERROR "Cooking: GNU Stow is required!")
  endif ()

  set (Cooking_INGREDIENTS_DIR
    ${_cooking_dir}/installed
    CACHE
    PATH
    "Directory where ingredients will be installed.")

  set (Cooking_EXCLUDED_INGREDIENTS
   ""
   CACHE
   STRING
   "Semicolon-separated list of ingredients that are not provided by Cooking.")

  set (Cooking_INCLUDED_INGREDIENTS
   ""
   CACHE
   STRING
   "Semicolon-separated list of ingredients that are provided by Cooking.")

  option (Cooking_LIST_ONLY
    "Available ingredients will be listed and nothing will be installed."
    OFF)

  set (Cooking_RECIPE "" CACHE STRING "Configure ${name}'s dependencies according to the named recipe.")

  if ((NOT DEFINED Cooking_EXCLUDED_INGREDIENTS) OR (Cooking_EXCLUDED_INGREDIENTS STREQUAL ""))
    set (_cooking_excluding OFF)
  else ()
    set (_cooking_excluding ON)
  endif ()

  if ((NOT DEFINED Cooking_INCLUDED_INGREDIENTS) OR (Cooking_INCLUDED_INGREDIENTS STREQUAL ""))
    set (_cooking_including OFF)
  else ()
    set (_cooking_including ON)
  endif ()

  if (_cooking_excluding AND _cooking_including)
    message (
      FATAL_ERROR
      "Cooking: The EXCLUDED_INGREDIENTS and INCLUDED_INGREDIENTS lists are mutually exclusive options!")
  endif ()

  if (_cooking_root)
    _project (${name} ${ARGN})

    if (NOT ("${Cooking_RECIPE}" STREQUAL ""))
      add_custom_target (_cooking_ingredients)

      add_custom_command (
        OUTPUT ${_cooking_dir}/ready.txt
        DEPENDS _cooking_ingredients
        COMMAND ${CMAKE_COMMAND} -E touch ${_cooking_dir}/ready.txt)

      add_custom_target (_cooking_ingredients_ready
        DEPENDS ${_cooking_dir}/ready.txt)

      list (APPEND CMAKE_PREFIX_PATH ${Cooking_INGREDIENTS_DIR})
      include ("recipe/${Cooking_RECIPE}.cmake")

      if (NOT EXISTS ${_cooking_dir}/ready.txt)
        return ()
      endif ()
    endif ()
  endif ()
endmacro ()

set (_cooking_ingredient_name_pattern "([a-zA-Z][a-zA-Z0-9\-_]+)")

function (_cooking_prefix_ingredients var input)
  string (REGEX REPLACE
    ${_cooking_ingredient_name_pattern}
    ingredient_\\0
    result
    "${input}")

  set (${var} ${result} PARENT_SCOPE)
endfunction ()

_cooking_prefix_ingredients (
  _cooking_excluded_ingredients_prefixed
  "${Cooking_EXCLUDED_INGREDIENTS}")

_cooking_prefix_ingredients (
  _cooking_included_ingredients_prefixed
  "${Cooking_INCLUDED_INGREDIENTS}")

macro (cooking_ingredient name)
  set (_cooking_args "${ARGN}")

  if (_cooking_excluding)
    # Strip out any dependencies that are excluded.
    list (REMOVE_ITEM _cooking_args "${_cooking_excluded_ingredients_prefixed}")
  elseif (_cooking_including)
    # Eliminate dependencies that have not been included.
    foreach (x IN LISTS _cooking_args)
      if (("${x}" MATCHES ingredient_${_cooking_ingredient_name_pattern})
          AND NOT ("${x}" IN_LIST Cooking_INCLUDED_INGREDIENTS))
        list (REMOVE_ITEM _cooking_args ${x})
      endif ()
    endforeach ()
  endif ()

  if ((_cooking_excluding AND (${name} IN_LIST Cooking_EXCLUDED_INGREDIENTS))
      OR (_cooking_including AND (NOT (${name} IN_LIST Cooking_INCLUDED_INGREDIENTS))))
    # Nothing.
  else ()
    set (_cooking_ingredient_dir ${_cooking_dir}/ingredient/${name})

    add_custom_target (_cooking_ingredient_${name}_post_install
      DEPENDS ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${name})

    add_dependencies (_cooking_ingredients _cooking_ingredient_${name}_post_install)

    if (Cooking_LIST_ONLY)
      add_custom_command (
        OUTPUT ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${name}
        MAIN_DEPENDENCY ${Cooking_INGREDIENTS_DIR}/.cooking_stamp
        COMMAND ${CMAKE_COMMAND} -E touch ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${name})
    else ()
      cmake_parse_arguments (
        _cooking_parsed_args
        ""
        "COOKING_RECIPE"
        "CMAKE_ARGS;COOKING_INCLUDE;COOKING_EXCLUDE"
        ${_cooking_args})

      include (ExternalProject)
      set (_cooking_stow_dir ${_cooking_dir}/stow)
      string (REPLACE "<DISABLE>" "" _cooking_forwarded_args "${_cooking_parsed_args_UNPARSED_ARGUMENTS}")

      if (NOT (SOURCE_DIR IN_LIST _cooking_args))
        set (_cooking_source_dir SOURCE_DIR ${_cooking_ingredient_dir}/src)
      else ()
        set (_cooking_source_dir "")
      endif ()

      if (NOT ((BUILD_IN_SOURCE IN_LIST _cooking_args) OR (BINARY_DIR IN_LIST _cooking_args)))
        set (_cooking_binary_dir BINARY_DIR ${_cooking_ingredient_dir}/build)
      else ()
        set (_cooking_binary_dir "")
      endif ()

      if (NOT (UPDATE_COMMAND IN_LIST _cooking_args))
        set (_cooking_update_command UPDATE_COMMAND)
      else ()
        set (_cooking_update_command "")
      endif ()

      set (_cooking_extra_cmake_args
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>)

      if (NOT ("${ARGN}" MATCHES .*CMAKE_BUILD_TYPE.*))
        list (APPEND _cooking_extra_cmake_args -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})
      endif ()

      if (_cooking_parsed_args_COOKING_RECIPE)
        set (_cooking_include_exclude_args "")

        foreach (i ${_cooking_parsed_args_COOKING_INCLUDE})
          list (APPEND _cooking_include_exclude_args -i ${i})
        endforeach ()

        foreach (e ${_cooking_parsed_args_COOKING_EXCLUDE})
          list (APPEND _cooking_include_exclude_args -e ${e})
        endforeach ()

        set (_cooking_configure_command
          CONFIGURE_COMMAND
          <SOURCE_DIR>/cooking.sh
          -r ${_cooking_parsed_args_COOKING_RECIPE}
          -d <BINARY_DIR>
          -p ${Cooking_INGREDIENTS_DIR}
          -x
          ${_cooking_include_exclude_args}
          --
          ${_cooking_extra_cmake_args}
          ${_cooking_parsed_args_CMAKE_ARGS})
      elseif (NOT (CONFIGURE_COMMAND IN_LIST _cooking_args))
        set (_cooking_configure_command
          CONFIGURE_COMMAND
          ${CMAKE_COMMAND}
          ${_cooking_extra_cmake_args}
          ${_cooking_parsed_args_CMAKE_ARGS}
          <SOURCE_DIR>)
      else ()
        set (_cooking_configure_command "")
      endif ()

      if (NOT (BUILD_COMMAND IN_LIST _cooking_args))
        set (_cooking_build_command BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR>)
      else ()
        set (_cooking_build_command "")
      endif ()

      if (NOT (INSTALL_COMMAND IN_LIST _cooking_args))
        set (_cooking_install_command INSTALL_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target install)
      else ()
        set (_cooking_install_command "")
      endif ()

      ExternalProject_add (ingredient_${name}
        ${_cooking_source_dir}
        ${_cooking_binary_dir}
        ${_cooking_update_command} ""
        ${_cooking_configure_command}
        ${_cooking_build_command}
        ${_cooking_install_command}
        PREFIX ${_cooking_ingredient_dir}
        STAMP_DIR ${_cooking_ingredient_dir}/stamp
        INSTALL_DIR ${_cooking_stow_dir}/${name}
        STEP_TARGETS install
        CMAKE_ARGS ${_cooking_extra_cmake_args}
        "${_cooking_forwarded_args}")

      if (_cooking_parsed_args_COOKING_RECIPE)
        ExternalProject_add_step (ingredient_${name}
          cooking-reconfigure
          DEPENDS ${Cooking_INGREDIENTS_DIR}/.cooking_stamp
          DEPENDERS configure)
      endif ()

      add_custom_command (
        OUTPUT ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${name}
        MAIN_DEPENDENCY ${Cooking_INGREDIENTS_DIR}/.cooking_stamp
        DEPENDS ingredient_${name}-install
        COMMAND
          flock
          --wait 30
          ${Cooking_INGREDIENTS_DIR}/.cooking_stow.lock
          ${Cooking_STOW_EXECUTABLE}
          -t ${Cooking_INGREDIENTS_DIR}
          -d ${_cooking_stow_dir}
          ${name}
        COMMAND ${CMAKE_COMMAND} -E touch ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${name})

      add_dependencies (_cooking_ingredients ingredient_${name})
    endif ()
  endif ()
endmacro ()
EOF

cmake_cooking_args=(
    "-DCooking_INGREDIENTS_DIR=${ingredients_dir}"
    "-DCooking_RECIPE=${recipe}"
)

#
# Clean-up from a previous run.
#

if [ -e "${ingredients_ready_file}" ]; then
    rm "${ingredients_ready_file}"
fi

if [ -e "${cache_file}" ]; then
    rm "${cache_file}"
fi

if [ -d "${ingredients_dir}" -a -z "${nested}" ]; then
    rm -r --preserve-root "${ingredients_dir}"
fi

mkdir -p "${ingredients_dir}"
touch "${ingredients_dir}/.cooking_stamp"

#
# Validate recipe.
#

if [ -n "${recipe}" ]; then
    recipe_file="${source_dir}/recipe/${recipe}.cmake"

    if [ ! -f "${recipe_file}" ]; then
        echo "Cooking: The '${recipe}' recipe does not exist!" && exit 1
    fi
fi

#
# Prepare lists of included and excluded ingredients.
#

if [ -n "${excluded_ingredients}" ] && [ -z "${list_only}" ]; then
    cmake_cooking_args+=(
        -DCooking_EXCLUDED_INGREDIENTS=$(printf "%s;" "${excluded_ingredients[@]}")
        -DCooking_INCLUDED_INGREDIENTS=
    )
fi

if [ -n "${included_ingredients}" ] && [ -z "${list_only}" ]; then
    cmake_cooking_args+=(
        -DCooking_EXCLUDED_INGREDIENTS=
        -DCooking_INCLUDED_INGREDIENTS=$(printf "%s;" "${included_ingredients[@]}")
    )
fi

#
# Configure and build ingredients.
#

mkdir -p "${build_dir}"
mkdir -p "${cooking_dir}"/stow
touch "${cooking_dir}"/stow/.stow
cd "${build_dir}"

declare -a build_args

if [ "${generator}" == "Ninja" ]; then
    build_args+=(-v)
fi

if [ -n "${list_only}" ]; then
    cmake_cooking_args+=("-DCooking_LIST_ONLY=ON")
fi

${CMAKE} -DCMAKE_BUILD_TYPE="${build_type}" "${cmake_cooking_args[@]}" -G "${generator}" "${source_dir}"
${CMAKE} --build . --target _cooking_ingredients_ready -- "${build_args[@]}"

#
# Report what we've done (if we're not nested).
#

if [ -z "${nested}" ]; then
    ingredients=($(find "${ingredients_dir}" -name '.cooking_ingredient_*' -printf '%f\n' | sed -r 's/\.cooking_ingredient_(.+)/\1/'))

    if [ -z "${list_only}" ]; then
        printf "\nCooking: Installed the following ingredients:\n"
    else
        printf "\nCooking: The following ingredients are necessary for this recipe:\n"
    fi

    for ingredient in "${ingredients[@]}"; do
        echo "  - ${ingredient}"
    done

    printf '\n'

    if [ -n "${list_only}" ]; then
        exit 0
    fi
fi

#
# Configure the project, expecting all requirements satisfied.
#

${CMAKE} -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON "${@}" .
