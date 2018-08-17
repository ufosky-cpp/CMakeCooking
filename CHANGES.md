v0.5.0
------
2018-08-17

- Allow updates by default in ingredients.
- Automatically reconfigure nested local ingredients.

  If an ingredient is specified not with a URL or a `GIT_REPOSITORY` but instead is located on the local file-system (specified via `SOURCE_DIR`), then `cmake-cooking` will now correctly "pick-up" any changes when the ingredient changes.
  
- Allow environmental variables to be set via command-line options.

  Instead of setting environmental variables like
  
      CXX=clang++ ./cooking.sh -r dev
      
  it's now possible to invoke `cmake-cooking` like this:
  
      ./cooking.sh -r dev -s CXX=clang++
      
  This has the advantage that the exact `cmake-cooking`-specific modifications to the environment are known to the script itself (and can be recorded for later).
  
- Allow recalling previous arguments for convenience.

  `cmake-cooking` refreshes the state of the build every time it is invoked. Therefore, when there are many parameters, it can be inconvenient to remember them during every invocation.
  
  Now, one can write something like:
  
      ./cooking.sh -r dev -s CXX=clang++ -- -DMyProject_MAGIC=ONLY
      
  the first time, and the project can be subsequently reconfigured with the same parameters by invoking
  
      ./cooking.sh -a

v0.4.0
------
2018-07-05

- Add the `Cooking_INGREDIENTS_DIR` cache variable.
- Prefix all local variables in macro definitions to avoid conflicts.
- Use GNU Stow to install ingredients to avoid copying files gratuitously.
- Allow available ingredients to be queried with the `-l` option.
- Allow for in-source builds of ingredients which do not support out-of-source builds.
- Disable `UPDATE_COMMAND` by default to avoid unnecessary build steps.
- Improve command-line documentation.
- Allow ingredients to be selectively included or excluded from a recipe for flexibility.
- Allow ingredients to be specified which require their own `cmake-cooking` recipe with the `COOKING_RECIPE` parameter to `cooking_ingredient`.

v0.3.0
------
2018-06-05

- Support specifying the `CMAKE_BUILD_TYPE` with the `-t` option. The build-type gets forwarded to ingredients unless an ingredient overrides it. The default build-type is `Debug`.
- Rename `configure.sh` to `cooking.sh`
- Eliminate the `Cooking_${name}_ROOT_PROJECT` variable.
- Automatically set `CMAKE_INSTALL_PREFIX` for ingredients to further reduce boilerplate.

v0.2.0
------
2018-06-02

- Define `Cooking_${name}_ROOT_PROJECT` instead of `${name}_ROOT_PROJECT`.
- Reduce boilerplate in recipe definitions by making it unnecessary to specify the build and install directories. The source directory of an ingredient can be overridden if necessary.
- Improve the documentation to make it more clear.

v0.1.1
------
2018-05-30

- Correct references to examples in `README.md`.

v0.1.0
-------
2018-05-30

- Initial release.
