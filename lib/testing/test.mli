(** Test definitions. *)

open Rresult

type t

val pp :
  t Fmt.t

val define :
  string -> (unit -> (_, R.msg) result) -> t
(** Define a new test.

    This is documented in {! test}. *)

val name :
  t -> string
(** Query for the name of a test. *)

val execute :
  Accounting.state -> t -> unit
(** Execute a single test and record the outcome in the accounting state.  *)

val log_source :
  Logs.Src.t

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
