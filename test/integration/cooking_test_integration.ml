open Bos
open Cooking_interaction
open Rresult

let with_build_dir f =
  OS.Dir.with_tmp
    "cooking-test-build-%s"
    (fun build_dir () -> f build_dir)
    ()

let with_install_dir f =
  OS.Dir.with_tmp
    "cooking-test-install-%s"
    (fun install_dir () -> f install_dir)
    ()

type ingredient =
  (Project.t -> unit Runner.result) -> unit Runner.result

let ingredient ~source_dir () : ingredient =
  fun f ->
    with_build_dir (fun build_dir ->
        with_install_dir (fun install_dir ->
            let p =
              Project.{
                source_dir;
                build_dir;
                install_dir }
            in

            f p))
    |> R.join
    |> R.join

module type PANTRY = sig
  val egg :
    ingredient

  val durian :
    ingredient

  val carrot :
    ingredient

  val banana :
    ingredient

  val apple :
    ingredient
end

let pantry path =
  (module struct
    let egg =
      ingredient ~source_dir:Fpath.(path / "egg") ()

    let durian =
      ingredient ~source_dir:Fpath.(path / "durian") ()

    let carrot =
      ingredient ~source_dir:Fpath.(path / "carrot") ()

    let banana =
      ingredient ~source_dir:Fpath.(path / "banana") ()

    let apple =
      ingredient ~source_dir:Fpath.(path / "apple") ()
  end : PANTRY)

let prefix_path ps =
  let cp = List.map (fun p -> p.Project.install_dir |> Fpath.to_string) ps |> String.concat ";" in
  Cmd.v ("-DCMAKE_PREFIX_PATH=" ^ cp)

let exec (ing : ingredient) out f g =
  OS.Env.current () >>= fun env ->

  ing (fun p ->
      let (s : OS.Cmd.run_out Runner.step) = f p in

      OS.Dir.with_current
        p.Project.build_dir
        (fun () -> s ~env () >>= Runner.run_requiring_success out >>= fun () -> g p)
        ()
      |> R.join)

let exec_with_cooking ?(recipe="dev") ?restrictions ?cmake_args ?target ingredient out g =
  let f p = Runner.configure_and_build_cooking_project ?cmake_args ?restrictions ?target ~recipe p out in
  exec ingredient out f g

let exec_with_cmake ?args ?target ingredient out g =
  let f p = Runner.configure_and_build_cmake_project ?args ?target p out in
  exec ingredient out f g

let exec_and_install_with_cooking ?recipe ?restrictions ?cmake_args ingredient out g =
  exec_with_cooking ?recipe ?restrictions ?cmake_args ~target:"install" ingredient out g

let exec_and_install_with_cmake ?args ingredient out g =
  exec_with_cmake ?args ~target:"install" ingredient out g

let resolve_pantry_path p =
  if Fpath.is_abs p then Ok p
  else
    OS.Dir.current () >>= fun cwd -> Ok Fpath.(cwd // p)

let tests pantry_path log_level =
  let (module P) =
    match resolve_pantry_path (Fpath.v pantry_path) with
    | Ok p -> pantry p
    | Error msg -> begin
        Logs.err (fun m -> m "Failed to resolve pantry path: %a" R.pp_msg msg);
        exit 1
      end
  in

  let out =
    match log_level with
    | Some Logs.Debug -> OS.Cmd.out_stdout
    | _ -> OS.Cmd.out_null
  in

  let open Cooking_testing in

  let t1 =
    test "Project `egg`" (fun () ->
        exec_with_cmake P.egg out (fun _ -> Ok ()))
  in

  let t2 =
    test "Project `durian`" (fun () ->
        exec_with_cmake P.durian out (fun _ -> Ok ()))
  in

  let t3 =
    test "Project `carrot`" (fun () ->
        exec_with_cooking P.carrot out (fun _ -> Ok ()))
  in

  let t4 =
    test "Project `banana`" (fun () ->
        exec_with_cooking P.banana out (fun _ -> Ok ()))
  in

  let t5 =
    test "Project `apple`" (fun () ->
        exec_with_cooking P.apple out (fun _ -> Ok ()))
  in

  let t6 =
    test "A cooking project can be configured with CMake when its dependencies are satisfied externally" (fun () ->
        exec_and_install_with_cmake P.egg out (fun p_e ->
            exec_and_install_with_cmake P.durian out (fun p_d ->
                exec_with_cmake ~args:(prefix_path [p_e; p_d]) P.carrot out (fun _ -> Ok ()))))
  in

  let t7 =
    test "A cooking project can have one of its dependencies supplied externally via exclusion" (fun () ->
        exec_and_install_with_cmake P.egg out (fun p_e ->
            exec_with_cooking
              ~cmake_args:(prefix_path [p_e])
              ~restrictions:(`Exclude ["Egg"])
              P.carrot
              out
              (fun _ -> Ok ())))
  in

  let t8 =
    test "A cooking project can have two of its dependencies supplied externally via exclusion" (fun () ->
        exec_and_install_with_cmake P.egg out (fun p_e ->
            exec_and_install_with_cmake P.durian out (fun p_d ->
                exec_with_cooking
                  ~cmake_args:(prefix_path [p_e; p_d])
                  ~restrictions:(`Exclude ["Egg"; "Durian"])
                  P.carrot
                  out
                  (fun _ -> Ok ()))))
  in

  let t9 =
    test "A cooking project can have one of its dependencies supplied externally via inclusion" (fun () ->
        exec_and_install_with_cmake P.durian out (fun p_d ->
            exec_with_cooking
              ~cmake_args:(prefix_path [p_d])
              ~restrictions:(`Include ["Egg"; "Carrot"])
              P.banana
              out
              (fun _ -> Ok ())))
  in

  let t10 =
    test "A cooking project can have two of its dependencies supplied externally via inclusion" (fun () ->
        exec_and_install_with_cmake P.egg out (fun p_e ->
            exec_and_install_with_cmake P.durian out (fun p_d ->
                exec_with_cooking
                  ~cmake_args:(prefix_path [p_e; p_d])
                  ~restrictions:(`Include ["Carrot"])
                  P.banana
                  out
                  (fun _ -> Ok ()))))
  in

  [
    t1;
    t2;
    t3;
    t4;
    t5;
    t6;
    t7;
    t8;
    t9;
    t10
  ]

(*
 * CLI
 *)

let initialize_logging style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.Src.set_level Cooking_testing.Test.log_source level;
  Logs.Src.set_level Runner.log_source level;
  Logs.set_reporter (Logs_fmt.reporter ());
  level

open Cmdliner

let logging =
  Term.(const initialize_logging $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let pantry_path =
  let doc = "File-system path of the pantry directory." in
  Arg.(required & pos 0 (some dir) None & info [] ~docv:"PATH" ~doc)

let tests =
  Term.(const tests $ pantry_path $ logging)

let cmd =
  let doc = "Execute integration tests for cmake-cooking." in
  Term.(const Cooking_testing.main $ tests), Term.info "cooking-test-integration" ~doc

let () =
  let exit_code =
    match Term.eval cmd with
    | `Error _ -> 1
    | _ -> if Logs.err_count () > 0 then 1 else 0
  in

  exit exit_code

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
