open Bos
open Rresult

let log_source =
  Logs.Src.create "cooking.interaction.runner"

module Log =
  (val Logs.src_log log_source)

module String_map =
  Astring.String.Map

let query_for_cmake_exe ?env () =
  let default = Fpath.v "cmake" in

  let path =
    match env with
    | None -> default
    | Some env -> begin
        match String_map.find_opt "CMAKE" env with
        | Some path -> Fpath.v path
        | None -> default
      end
  in

  path

type nonrec 'a result = ('a, [`Msg of string]) result

type 'a step =
  ?env:OS.Env.t ->
  ?err:OS.Cmd.run_err ->
  unit ->
  'a result

let install_prefix p =
  Cmd.v (Fmt.strf "-DCMAKE_INSTALL_PREFIX=%a" Abs_fpath.pp p)

module Impl = struct
  let configure_cmake_project ?env ?err ~source_dir ~install_dir ~args () =
    let cmake_exe = query_for_cmake_exe ?env () in

    let cmd = Cmd.(
        v (p cmake_exe)
        % p (Abs_fpath.extract source_dir)
        %% install_prefix install_dir
        %% args)
    in

    Log.debug (fun m -> m "Configure CMake project at `%a`: %a" Abs_fpath.pp source_dir Cmd.pp cmd);
    Ok (OS.Cmd.run_out ?env ?err cmd)

  let cooking_executable =
    "cooking.sh"

  let configure_cooking_project
      ?env
      ?err
      ?restrictions
      ~source_dir
      ~build_dir
      ~install_dir
      ~recipe
      ~cmake_args
      () =
    let cmd = Cmd.(
        v (p Fpath.((Abs_fpath.extract source_dir) / cooking_executable))
        % "-d" % p (Abs_fpath.extract build_dir)
        % "-r" % recipe
        %% (match restrictions with
            | None -> empty
            | Some rs -> begin
                let slip, xs =
                  match rs with
                  | `Include xs -> "-i", xs
                  | `Exclude xs -> "-e", xs
                in

                of_list ~slip xs
              end)
        % "--"
        %% install_prefix install_dir
        %% cmake_args)
    in

    Log.debug (fun m -> m "Configure cooking project at `%a`: %a" Abs_fpath.pp source_dir Cmd.pp cmd);
    OS.Cmd.run_out ?env ?err cmd

  let build_cmake_project ?env ?err ~build_dir target =
    let cmake_exe = query_for_cmake_exe ?env () in

    let cmd = Cmd.(
        v (p cmake_exe)
        % "--build" % p (Abs_fpath.extract build_dir)
        % "--target" % target)
    in

    Log.debug (fun m ->
        m
          "Build target `%s` for CMake project at `%a`: %a"
          target
          Abs_fpath.pp
          build_dir
          Cmd.pp
          cmd);

    OS.Cmd.run_out ?env ?err cmd
end

let configure_with_cmake ?(args=Cmd.empty) p =
  fun ?env ?err () ->
    Abs_fpath.check p.Project.source_dir >>= fun source_dir ->
    Abs_fpath.check p.install_dir >>= fun install_dir ->

    Impl.configure_cmake_project
      ?env
      ?err
      ~source_dir
      ~install_dir
      ~args
      ()

type restrictions = [
  | `Exclude of string list
  | `Include of string list
]

let configure_with_cooking ?restrictions ?(cmake_args=Cmd.empty) ~recipe p =
  fun ?env ?err () ->
    Abs_fpath.check p.Project.source_dir >>= fun source_dir ->
    Abs_fpath.check p.build_dir >>= fun build_dir ->
    Abs_fpath.check p.install_dir >>= fun install_dir ->

    Impl.configure_cooking_project
      ?env
      ?err
      ?restrictions
      ~source_dir
      ~build_dir
      ~install_dir
      ~recipe
      ~cmake_args
      ()
    |> R.ok

let build_with_cmake ?(target="all") p =
  fun ?env ?err () ->
    Abs_fpath.check p.Project.build_dir >>= fun build_dir ->
    Impl.build_cmake_project ?env ?err ~build_dir target
    |> R.ok

type out = OS.Cmd.run_out -> (unit * OS.Cmd.run_status) result

let run_requiring_success out run_out =
  out run_out |> OS.Cmd.success

let combine cs bs out =
  fun ?env ?err () ->
    cs ?env ?err ()
    >>= run_requiring_success out
    >>= fun () -> bs ?env ?err ()

let configure_and_build_cmake_project ?args ?target p out =
  combine
    (configure_with_cmake ?args p)
    (build_with_cmake ?target p)
    out

let configure_and_build_cooking_project ?restrictions ?cmake_args ?target ~recipe p out =
  combine
    (configure_with_cooking ?restrictions ?cmake_args ~recipe p)
    (build_with_cmake ?target p)
    out

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
