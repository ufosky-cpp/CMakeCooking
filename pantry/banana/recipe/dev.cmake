cooking_ingredient (Durian
  EXTERNAL_PROJECT_ARGS
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/extern/durian)

cooking_ingredient (Carrot
  COOKING_RECIPE dev
  REQUIRES Durian
  EXTERNAL_PROJECT_ARGS
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/extern/carrot)
