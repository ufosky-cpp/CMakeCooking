module Accounting = Accounting
module Test = Test

let test name f =
  Test.define name f

let execute_all s ts =
  ts |> List.iter (Test.execute s)

let summarize s =
  let pp_newline = Fmt.(const string "\n") in
  let pp_result ppf name = Fmt.pf ppf  "  - %s" name in
  let pp_result_list = Fmt.list ~sep:pp_newline pp_result in
  Logs.app (fun m -> m "Summary:");
  Logs.app (fun m -> m "- Successful:@.%a" pp_result_list (Accounting.successful s));
  Logs.app (fun m -> m "- Failed:@.%a" pp_result_list (Accounting.failed s))

let main ts =
  let s = Accounting.empty_state in
  execute_all s ts;
  summarize s

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
