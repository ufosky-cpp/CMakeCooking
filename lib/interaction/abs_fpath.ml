open Rresult

type t = Fpath.t

let pp =
  Fpath.pp

let extract t =
  t

let check u =
  if Fpath.is_rel u then
    Error (R.msgf "`%a` must be an absolute path" Fpath.pp u)
  else Ok u

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
