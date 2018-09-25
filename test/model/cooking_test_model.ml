open Cooking_model
open Rresult

let apple =
  "apple"

let banana =
  "banana"

let carrot =
  "carrot"

let durian =
  "durian"

let egg =
  "egg"

module Book = struct
  let e =
    Recipe.raw egg

  let d =
    Recipe.raw durian

  let c =
    Recipe.(
      blank carrot [egg; durian]
      |> requires d
      >>= requires e)
    |> R.get_ok

  let b =
    Recipe.(
      blank banana [egg; durian; carrot]
      |> requires d
      >>= prepares c [durian]
      >>= before durian carrot)
    |> R.get_ok

  let a =
    Recipe.(
      blank apple [egg; durian; carrot; banana]
      |> requires e
      >>= prepares b [egg]
      >>= before egg banana)
    |> R.get_ok
end

let equal_order (xs : Recipe.name list) ys =
  xs = ys

let pp_order =
  Fmt.(Dump.list Recipe.pp_name)

let require_order expected actual =
  if equal_order expected actual then Ok ()
  else R.error_msgf "Expected %a but got %a" pp_order expected pp_order actual

let tests () =
  let open Cooking_testing in

  let t1 =
    test "Project `carrot`" (fun () ->
        Recipe.(execute (Cooked Book.c))
        |> Recipe.error_to_msg
        >>= require_order [egg; durian])
  in

  let t2 =
    test "Project `banana`" (fun () ->
        Recipe.execute (Cooked Book.b)
        |> Recipe.error_to_msg
        >>= require_order [durian; egg; carrot])
  in

  let t3 =
    test "Project `apple`" (fun () ->
        Recipe.execute (Cooked Book.a)
        |> Recipe.error_to_msg
        >>= require_order [egg; durian; carrot; banana])
  in

  let t4 =
    test "A cooking project can have one of its dependencies supplied externally via exclusion" (fun () ->
        Recipe.execute ~restrictions:(`Exclude [egg]) (Cooked Book.c)
        |> Recipe.error_to_msg
        >>= require_order [durian])
  in

  let t5 =
    test "A cooking project can have two of its dependencies supplied externally via exclusion" (fun () ->
        Recipe.execute ~restrictions:(`Exclude [egg; durian]) (Cooked Book.c)
        |> Recipe.error_to_msg
        >>= require_order [])
  in

  let t6 =
    test "A cooking project can have one of its dependencies supplied externally via inclusion" (fun () ->
        Recipe.execute ~restrictions:(`Include [egg; carrot]) (Cooked Book.b)
        |> Recipe.error_to_msg
        >>= require_order [egg; carrot])
  in

  let t7 =
    test "A cooking project can have two of its dependencies supplied externally via inclusion" (fun () ->
        Recipe.execute ~restrictions:(`Include [carrot]) (Cooked Book.b)
        |> Recipe.error_to_msg
        >>= require_order [carrot])
  in

  [
    t1;
    t2;
    t3;
    t4;
    t5;
    t6;
    t7;
  ]

(*
 * CLI
 *)

let initialize_logging style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.Src.set_level Cooking_testing.Test.log_source level;
  Logs.Src.set_level Recipe.log_source level;
  Logs.set_reporter (Logs_fmt.reporter ())

open Cmdliner

let logging =
  Term.(const initialize_logging $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let tests =
  Term.(const tests $ logging)

let cmd =
  let doc = "Execute model tests for cmake-cooking." in
  Term.(const Cooking_testing.main $ tests), Term.info "cooking-test-model" ~doc

let () =
  let exit_code =
    match Term.eval cmd with
    | `Error _ -> 1
    | _ -> if Logs.err_count () > 0 then 1 else 0
  in

  exit exit_code

let () =
  ()

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
