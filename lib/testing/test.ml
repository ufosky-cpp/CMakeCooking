open Rresult

type body =
  | Body : (unit -> (_, R.msg) result) -> body

type t = string * body

let pp_name =
  Fmt.quote Fmt.string

let pp =
  Fmt.using fst pp_name

let log_source =
  Logs.Src.create "cooking.testing.test"

module Log =
  (val Logs.src_log log_source)

let define name f =
  name, Body f

let name (n, _) =
  n

let execute s ((name, Body f) as t)  =
  Log.info (fun m -> m "Execute %a" pp t);

  match f () with
  | Ok _ -> begin
      Accounting.mark_success s name;
      Log.info (fun m -> m "Success")
    end
  | Error msg -> begin
      Accounting.mark_failure s name;
      Log.err (fun m -> m "Failure while executing %a: %a" pp t R.pp_msg msg)
    end
  | exception exn -> begin
      Accounting.mark_failure s name;
      Log.err (fun m -> m "Exception while executing %a: %a" pp t Fmt.exn exn)
    end

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
