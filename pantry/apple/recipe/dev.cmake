cooking_ingredient (Egg
  EXTERNAL_PROJECT_ARGS
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/extern/egg)

cooking_ingredient (Banana
  COOKING_RECIPE dev
  REQUIRES Egg
  EXTERNAL_PROJECT_ARGS
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/extern/banana)
