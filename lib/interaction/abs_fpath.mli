(** Just like {! Fpath}, but with run-time checks that the path indicated is
   absolute (not relative). *)

(** An absolute file-system path. *)
type t

val pp :
  t Fmt.t

val check :
  Fpath.t -> (t, [> `Msg of string]) result
(** Construct an absolute path. The result is an error if the indicated path is
   not absolute. *)

val extract :
  t -> Fpath.t
(** Extract the underlying {! Fpath.t} with the knowledge that it is an absolute
   path. *)

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
