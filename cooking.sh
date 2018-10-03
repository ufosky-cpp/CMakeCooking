#!/bin/bash

#
# Copyright 2018 Jesse Haber-Kucharsky
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This is cmake-cooking v0.8.0
# The home of cmake-cooking is https://github.com/hakuch/CMakeCooking
#

set -e

CMAKE=${CMAKE:-cmake}

invoked_args=("$@")
source_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
initial_wd=$(pwd)
memory_file="${initial_wd}/.cooking_memory"

recipe=""
declare -a excluded_ingredients
declare -a included_ingredients
build_dir="${initial_wd}/build"
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

-a
-r RECIPE
-e INGREDIENT
-i INGREDIENT
-d BUILD_DIR (=${build_dir})
-p INGREDIENTS_DIR (=${build_dir}/_cooking/installed)
-t BUILD_TYPE (=${build_type})
-g GENERATOR (=${generator})
-s VAR=VALUE
-l
-h

If neither [-i] nor [-e] are specified with a recipe ([-r]), then all ingredients of the recipe
will be fetched and built.

[-i] and [-e] are mutually-exclusive options: only provide one.

Option details:

-a

    Invoke 'cooking.sh' with the arguments that were provided to it last time, instead
    of the arguments provided.

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

-s VAR=VALUE

   Set an environmental variable 'VAR' to the value 'VALUE' during the invocation of CMake.

-l

    Only list available ingredients for a given recipe, and don't do anything else.

-h

    Show this help information and exit.

EOF
}

parse_assignment() {
    IFS='=' read -ra parts <<< "${1}"
    export "${parts[0]}"="${parts[1]}"
}

yell_include_exclude_mutually_exclusive() {
    echo "Cooking: [-e] and [-i] are mutually exclusive options!" >&2
}

while getopts "ar:e:i:d:p:t:g:s:lhx" arg; do
    case "${arg}" in
        a)
            if [ ! -f "${memory_file}" ]; then
                echo "No previous invocation found to recall!" >&2
                exit 1
            fi

            source "${memory_file}"
            run_previous && exit 0
            ;;
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
        s) parse_assignment "${OPTARG}" ;;
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
#
# Copyright 2018 Jesse Haber-Kucharsky
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This file was generated by cmake-cooking v0.8.0
# The home of cmake-cooking is https://github.com/hakuch/CMakeCooking
#

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

function (_cooking_query_by_key list key var)
  list (FIND ${list} ${key} index)
  math (EXPR value_index "${index} + 1")
  list (GET ${list} ${value_index} value)
  set (${var} ${value} PARENT_SCOPE)
endfunction ()

function (_cooking_set_union x y var)
  set (r ${${x}})

  foreach (e ${${y}})
    list (APPEND r ${e})
  endforeach ()

  list (REMOVE_DUPLICATES r)
  set (${var} ${r} PARENT_SCOPE)
endfunction ()

function (_cooking_set_difference x y var)
  set (r ${${x}})

  foreach (e ${${y}})
    if (${e} IN_LIST ${x})
       list (REMOVE_ITEM r ${e})
    endif ()
  endforeach ()

  set (${var} ${r} PARENT_SCOPE)
endfunction ()

function (_cooking_set_intersection x y var)
  set (r "")

  foreach (e ${${y}})
    if (${e} IN_LIST ${x})
      list (APPEND r ${e})
    endif ()
  endforeach ()

  list (REMOVE_DUPLICATES r)
  set (${var} ${r} PARENT_SCOPE)
endfunction ()

macro (cooking_ingredient name)
  set (_cooking_args "${ARGN}")

  if ((_cooking_excluding AND (${name} IN_LIST Cooking_EXCLUDED_INGREDIENTS))
      OR (_cooking_including AND (NOT (${name} IN_LIST Cooking_INCLUDED_INGREDIENTS))))
    # Nothing.
  else ()
    set (_cooking_ingredient_dir ${_cooking_dir}/ingredient/${name})

    cmake_parse_arguments (
      _cooking_pa
      ""
      "COOKING_RECIPE"
      "CMAKE_ARGS;COOKING_CMAKE_ARGS;EXTERNAL_PROJECT_ARGS;REQUIRES"
      ${_cooking_args})

    if (NOT (SOURCE_DIR IN_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS))
      set (_cooking_source_dir ${_cooking_ingredient_dir}/src)
      set (_cooking_ep_source_dir SOURCE_DIR ${_cooking_source_dir})
    else ()
      _cooking_query_by_key (_cooking_pa_EXTERNAL_PROJECT_ARGS SOURCE_DIR _cooking_source_dir)
      set (_cooking_ep_source_dir "")
    endif ()

    if (NOT ((BUILD_IN_SOURCE IN_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS)
             OR (BINARY_DIR IN_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS)))
      set (_cooking_binary_dir ${_cooking_ingredient_dir}/build)
      set (_cooking_ep_binary_dir BINARY_DIR ${_cooking_binary_dir})
    else ()
      _cooking_query_by_key (_cooking_pa_EXTERNAL_PROJECT_ARGS BINARY_DIR _cooking_binary_dir)
      set (_cooking_ep_binary_dir "")
    endif ()

    if (Cooking_LIST_ONLY)
      set (_cooking_listing_commands
        COMMAND
        ${CMAKE_COMMAND} -E touch ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${name})

      if (_cooking_pa_COOKING_RECIPE)
        list (INSERT _cooking_listing_commands 0
          COMMAND
          ${_cooking_source_dir}/cooking.sh
          -r ${_cooking_pa_COOKING_RECIPE}
          -p ${Cooking_INGREDIENTS_DIR}
          -x
          -l)
      endif ()

      add_custom_command (
        OUTPUT ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${name}
        MAIN_DEPENDENCY ${Cooking_INGREDIENTS_DIR}/.cooking_stamp
        ${_cooking_listing_commands})

      add_custom_target (_cooking_ingredient_${name}_listed
        DEPENDS ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${name})

      foreach (d ${_cooking_pa_REQUIRES})
        add_dependencies (_cooking_ingredient_${name}_listed _cooking_ingredient_${d}_listed)
      endforeach ()

      add_dependencies (_cooking_ingredients _cooking_ingredient_${name}_listed)
    else ()
      include (ExternalProject)
      set (_cooking_stow_dir ${_cooking_dir}/stow)
      string (REPLACE "<DISABLE>" "" _cooking_forwarded_args "${_cooking_pa_EXTERNAL_PROJECT_ARGS}")

      if (_cooking_pa_REQUIRES)
        set (_cooking_ep_depends DEPENDS)

        if (_cooking_excluding)
          # Strip out any dependencies that are excluded.
          _cooking_set_difference (
            _cooking_pa_REQUIRES
            Cooking_EXCLUDED_INGREDIENTS
            _cooking_pa_REQUIRES)
        elseif (_cooking_including)
          # Eliminate dependencies that have not been included.
          _cooking_set_intersection (
            _cooking_pa_REQUIRES
            Cooking_INCLUDED_INGREDIENTS
            _cooking_pa_REQUIRES)
        endif ()

        foreach (d ${_cooking_pa_REQUIRES})
          list (APPEND _cooking_ep_depends ingredient_${d})
        endforeach ()
      else ()
        set (_cooking_ep_depends "")
      endif ()

      string (REPLACE ";" ":::" _cooking_cmake_prefix_path_with_colons "${CMAKE_PREFIX_PATH}")

      set (_cooking_extra_cmake_args
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_PREFIX_PATH=${_cooking_cmake_prefix_path_with_colons})

      if (NOT ("${ARGN}" MATCHES .*CMAKE_BUILD_TYPE.*))
        list (APPEND _cooking_extra_cmake_args -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})
      endif ()

      if (_cooking_pa_COOKING_RECIPE)
        set (_cooking_include_exclude_args "")

        if (_cooking_including)
          _cooking_set_difference (
            Cooking_INCLUDED_INGREDIENTS
            _cooking_pa_REQUIRES
            _cooking_included)

          foreach (x ${_cooking_included})
            list (APPEND _cooking_include_exclude_args -i ${x})
          endforeach ()
        elseif (_cooking_excluding)
          _cooking_set_union (
            Cooking_EXCLUDED_INGREDIENTS
            _cooking_pa_REQUIRES
            _cooking_excluded)

          foreach (x ${_cooking_excluded})
            list (APPEND _cooking_include_exclude_args -e ${x})
          endforeach ()
        else ()
          foreach (x ${_cooking_pa_REQUIRES})
            list (APPEND _cooking_include_exclude_args -e ${x})
          endforeach ()
        endif ()

        set (_cooking_ep_configure_command
          CONFIGURE_COMMAND
          <SOURCE_DIR>/cooking.sh
          -r ${_cooking_pa_COOKING_RECIPE}
          -d <BINARY_DIR>
          -p ${Cooking_INGREDIENTS_DIR}
          -g ${CMAKE_GENERATOR}
          -x
          ${_cooking_include_exclude_args}
          --
          ${_cooking_extra_cmake_args}
          ${_cooking_pa_COOKING_CMAKE_ARGS})
      elseif (NOT (CONFIGURE_COMMAND IN_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS))
        set (_cooking_ep_configure_command
          CONFIGURE_COMMAND
          ${CMAKE_COMMAND}
          ${_cooking_extra_cmake_args}
          ${_cooking_pa_CMAKE_ARGS}
          <SOURCE_DIR>)
      else ()
        set (_cooking_ep_configure_command "")
      endif ()

      if (NOT (BUILD_COMMAND IN_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS))
        set (_cooking_ep_build_command BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR>)
      else ()
        set (_cooking_ep_build_command "")
      endif ()

      if (NOT (INSTALL_COMMAND IN_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS))
        set (_cooking_ep_install_command INSTALL_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target install)
      else ()
        set (_cooking_ep_install_command "")
      endif ()

      ExternalProject_add (ingredient_${name}
        ${_cooking_ep_depends}
        ${_cooking_ep_source_dir}
        ${_cooking_ep_binary_dir}
        ${_cooking_ep_configure_command}
        ${_cooking_ep_build_command}
        ${_cooking_ep_install_command}
        PREFIX ${_cooking_ingredient_dir}
        STAMP_DIR ${_cooking_ingredient_dir}/stamp
        INSTALL_DIR ${_cooking_stow_dir}/${name}
        CMAKE_ARGS ${_cooking_extra_cmake_args}
        LIST_SEPARATOR :::
        "${_cooking_forwarded_args}")

      if ((SOURCE_DIR IN_LIST _cooking_pa_EXTERNAL_PROJECT_ARGS) OR _cooking_pa_COOKING_RECIPE)
        ExternalProject_add_step (ingredient_${name}
          cooking-reconfigure
          DEPENDS ${Cooking_INGREDIENTS_DIR}/.cooking_stamp
          DEPENDERS configure)
      endif ()

      ExternalProject_add_step (ingredient_${name}
        cooking-stow
        DEPENDEES install
        DEPENDS ${Cooking_INGREDIENTS_DIR}/.cooking_stamp
        COMMAND
          flock
          --wait 30
          ${Cooking_INGREDIENTS_DIR}/.cooking_stow.lock
          ${Cooking_STOW_EXECUTABLE}
          -t ${Cooking_INGREDIENTS_DIR}
          -d ${_cooking_stow_dir}
          ${name}
        COMMAND ${CMAKE_COMMAND} -E touch ${Cooking_INGREDIENTS_DIR}/.cooking_ingredient_${name})

      ExternalProject_add_steptargets (ingredient_${name}
        cooking-stow)

      add_dependencies (_cooking_ingredients
        ingredient_${name}-cooking-stow)
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
        echo "Cooking: The '${recipe}' recipe does not exist!" >&2
        exit 1
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

${CMAKE} -DCMAKE_BUILD_TYPE="${build_type}" "${cmake_cooking_args[@]}" -G "${generator}" "${source_dir}" "${@}"
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
fi

if [ -n "${list_only}" ]; then
    exit 0
fi

#
# Configure the project, expecting all requirements satisfied.
#

${CMAKE} -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON "${@}" .

#
# Save invocation information.
#

cd "${initial_wd}"

cat <<EOF > "${memory_file}"
run_previous() {
    "${0}" ${invoked_args[@]@Q}
}
EOF
