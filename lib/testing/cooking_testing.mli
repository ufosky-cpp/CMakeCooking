(** Small testing support library. *)

open Rresult

module Accounting = Accounting
module Test = Test

val test :
  string -> (unit -> (_, R.msg) result) -> Test.t
(** Define a new test.

    [test n f] defines a new test with name [n] and body [f]. In the test,
   success is indicated with a result of {! Ok} and failure with an error
   message (or by throwing an exception). *)

val execute_all :
  Accounting.state -> Test.t list -> unit
(** Execute tests and report results.

    [execute_all s ts] executes all tests in the list [ts] in unspecified order
   and records the result of each test in [s]. *)

val main :
  Test.t list -> unit
(** Define the program entry point given a list of tests.

    This is an alternative to running {! execute_all} manually. *)

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
