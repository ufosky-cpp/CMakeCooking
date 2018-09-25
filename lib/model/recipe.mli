(** Descriptions of dependencies for C++ projects.

    We use the word "recipe" to describe the inter-dependencies of C++ projects
    (which we call "ingredients"). *)

open Rresult

(** A raw recipe describes a C++ project which has no dependencies. *)
type raw

(** A cooked recipe describes a C++ project which itself depends on other
    projects (it is an "ingredient" for other recipe which has to be "cooked"
    before it can be used). *)
type cooked

(** A recipe can either describe a raw or cooked ingredient. *)
type t =
  | Raw of raw
  | Cooked of cooked

(** {1 Names} *)

(** Recipes are identified through their name. *)
type name = string

val compare_name :
  name -> name -> int

val equal_name :
  name -> name -> bool

val pp_name :
  name Fmt.t

(** {1 Error handling} *)

type error = [
  | `Dependency_cycle
  | `Already_in_recipe of name
  | `Not_a_direct_dependency of name
  | `Missing_actual_dependencies of name list
]

val equal_error :
  error -> error -> bool

val pp_error :
  error Fmt.t

type nonrec 'a result = ('a, error) result

val error_to_msg :
  'a result -> ('a, R.msg) Rresult.result

(** {1 Writing recipes} *)

val raw :
  name -> raw
(** Describe a recipe for a named ingredient with no dependencies on other
    ingredients. *)

val blank :
  name -> name list -> cooked
(** Start a recipe for an ingredient which itself requires other ingredients in
    its preparation.

    [blank d ds] is the start of a recipe with name [d] which has real
    dependencies on each named ingredient in [ds]. *)

val name :
  t -> name
(** Query for the name of a recipe. *)

val requires :
  raw -> cooked -> cooked result
(** [requires rr cr] indicates that the raw recipe [rr] must be executed as part
   of the recipe for the cooked recipe [cr].

    We say that [cr] has a ""direct dependency"" on [rr].

    If [cr] already includes a requirement on an ingredient with the name of
   [rr] then the result is an error of [`Already_in_recipe]. *)

val prepares :
  cooked -> name list -> cooked -> cooked result
(** [prepares dcr ds cr] indicates that the cooked recipe [dcr] must be executed
   as part of the recipe for the cooked recipe [cr].

    All the ingredients contained in [dcr] are also added to the recipe for
   [cr], except those indicated by name in the list [ds].

    We say that [cr] has a "direct dependency" on [dcr].

    If [cr] already includes a requirement on an ingredient with the name of
   [dcr] then the result is an error of [`Already_in_recipe]. *)

val before :
  name -> name -> cooked -> cooked result
(** [before d1 d2 cr] indicates that a direct dependency of [cr] with name [d1]
   must be executed before a direct dependency of [cr] with name [d2].

    If either [d1] or [d2] refer to ingredients which are not direct
   dependencies of [cr] then the result is an error of
   [`Not_a_direct_dependency]. *)

(** {1 Executing recipes} *)

(** Restrictions specify limits on which ingredients are actually executed in a recipe. *)
type restrictions = [
  | `Include of name list
  | `Exclude of name list
]

val execute :
  ?restrictions:restrictions -> t -> name list result
(** [execute qs t] executes the recipe [t] with the application of restrictions
   [qs].

    The result is the order in which ingredients were executed in the recipe
   (excluding the name of ingredient described by the recipe itself). The first
   name in the list is the first ingredient executed.

    If the recipe is cyclic, then the result is an error of [`Dependency_cycle].

    If an ingredient has actual dependencies that are not satisfied at the time
   that it is executed, then the result is an error of
   [`Missing_actual_dependencies]. *)

(** {1 Logging} *)

val log_source :
  Logs.src
(** Log source for recipes and their execution. *)

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
