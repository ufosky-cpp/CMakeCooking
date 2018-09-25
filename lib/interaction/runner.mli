(** Helpers for configuring and building CMake projects interactively with or
    without [cmake-cooking]. *)

open Bos

type nonrec 'a result = ('a, [`Msg of string]) result

(** A stage of interaction execution with customizable environment and
    error-handling. *)
type 'a step =
  ?env:OS.Env.t ->
  ?err:OS.Cmd.run_err ->
  unit ->
  'a result

(** Corresponds to the [-i] and [-e] arguments of [cmake-cooking]. *)
type restrictions = [
  | `Exclude of string list
  | `Include of string list
]

val configure_with_cmake :
  ?args:Cmd.t -> Project.t -> OS.Cmd.run_out step
(** [configure_with_cmake ?args p] produces a step which configures the project
    [p] with `cmake` arguments [args]. *)

val configure_with_cooking :
  ?restrictions:restrictions ->
  ?cmake_args:Cmd.t ->
  recipe:string ->
  Project.t ->
  OS.Cmd.run_out step
(** [configure_with_cooking ?restrictions ?cmake_args ~recipe p] produces a step
    which configures the project [p] with [cmake-cooking] subject to the
    [restrictions] according to the recipe [r] and with the `cmake` arguments
    [cmake_args]. *)

val build_with_cmake :
  ?target:string -> Project.t -> OS.Cmd.run_out step
(** [build_with_cmake ?target p] produces a step which builds a project [p] via
    [cmake]. If [target] is provided, then this is the target built instead of
    the default target of the project. *)

(** Specifies how the output of a command is handled. *)
type out = OS.Cmd.run_out -> (unit * OS.Cmd.run_status) result

val run_requiring_success :
  out -> OS.Cmd.run_out -> unit result
(** Run a command and convert the output to a simple error type. *)

val combine :
  OS.Cmd.run_out step -> 'a step -> out -> 'a step
(** Combine two steps into a third step. *)

val configure_and_build_cmake_project :
  ?args:Cmd.t ->
  ?target:string ->
  Project.t ->
  out ->
  OS.Cmd.run_out step
(** [configure_and_build_cmake_project ?args ?target p o] produces a step which
    first configures the project [p] with `cmake` arguments [args] and then (with [o])
    builds the project's default target (or [target] if it is provided). *)

val configure_and_build_cooking_project :
  ?restrictions:restrictions ->
  ?cmake_args:Cmd.t ->
  ?target:string ->
  recipe:string ->
  Project.t ->
  out ->
  OS.Cmd.run_out step
(** [configure_and_build_cooking_project ?restrictions ?cmake_args ?target r p
    o] produces a step which first configures the project [p] with
    [cmake-cooking] subject to [restrictions], with [cmake] arguments
    [cmake_args], and according to the recipe [r] and then (with [o]) builds the
    project's default target (or [target] if it is provided). *)

val log_source :
  Logs.src
(** Source for controlling logging. *)

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
