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
