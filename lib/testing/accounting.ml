type state = {
  mutable successful : string list;
  mutable failed : string list;
}

let empty_state =
  { successful = [];
    failed = [] }

let mark_success s name =
  s.successful <- name :: s.successful

let mark_failure s name =
  s.failed <- name :: s.failed

let successful s =
  s.successful

let failed s =
  s.failed

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
