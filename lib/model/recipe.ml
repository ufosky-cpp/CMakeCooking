open Rresult

type name = string [@@deriving eq, ord]

let pp_name =
  Fmt.(quote string)

module Compare_name = struct
  type t = name

  let compare =
    compare_name
end

module Name_set =
  Set.Make (Compare_name)

module type NAME_GRAPH = sig
  type value

  include Directed_graph_intf.S with type label = name and type value := value
end

type t =
  | Raw of raw
  | Cooked of cooked
and raw = name
and cooked = {
  name : name;
  actual : Name_set.t;
  excluded : Name_set.t;
  graph : graph;
}
and graph =
    Packed_graph : 'c * (module NAME_GRAPH with type value = t and type t = 'c) -> graph

type error = [
  | `Dependency_cycle
  | `Already_in_recipe of name
  | `Not_a_direct_dependency of name
  | `Missing_actual_dependencies of name list [@equal fun x y -> Name_set.(equal (of_list x) (of_list y))]
] [@@deriving eq]

let pp_error ppf = function
  | `Dependency_cycle -> Fmt.pf ppf "The recipe has a dependency cycle"
  | `Already_in_recipe name -> Fmt.pf ppf "%a is already in the recipe" pp_name name
  | `Missing_actual_dependencies names -> Fmt.(pf ppf "Missing actual dependencies %a" (Dump.list pp_name) names)
  | `Not_a_direct_dependency name -> Fmt.pf ppf "%a is not a direct dependency of the recipe" pp_name name

let error_to_msg r =
  R.error_to_msg ~pp_error r

type nonrec 'a result = ('a, error) result

let name = function
  | Raw d -> d
  | Cooked cr -> cr.name

let raw name =
  name

let blank name actual =
  let module G = Directed_graph.Make (Compare_name) (struct type nonrec t = t end) () in
  let graph = Packed_graph (G.empty, (module G)) in

  {
    name;
    actual = Name_set.of_list actual;
    excluded = Name_set.empty;
    graph }

let direct_dependencies cr =
  let Packed_graph (g, (module G)) = cr.graph in

  G.pairs g
  |> List.map snd
  |> List.filter (function
      | Raw _ -> true
      | Cooked dcr -> not (Name_set.mem dcr.name cr.excluded))

let rec specifies target_name t =
  equal_name target_name (name t) || (
    match t with
    | Raw _ -> false
    | Cooked cr -> direct_dependencies cr |> List.exists (specifies target_name))

let requires rr cr =
  if specifies rr (Cooked cr) then Error (`Already_in_recipe rr)
  else
    let Packed_graph (g, (module G)) = cr.graph in
    let g = G.node rr (Raw rr) g in
    Ok { cr with graph = Packed_graph (g, (module G)) }

let prepares dcr ems cr =
  let dm = dcr.name in

  if specifies dm (Cooked cr) then Error (`Already_in_recipe dcr.name)
  else
    let Packed_graph (g, (module G)) = cr.graph in
    let excluded = Name_set.(union dcr.excluded (of_list ems)) in
    let g = G.node dm (Cooked { dcr with excluded }) g in
    Ok { cr with graph = Packed_graph (g, (module G)) }

let before m1 m2 cr =
  let Packed_graph (g, (module G)) = cr.graph in

  match G.value m1 g, G.value m2 g with
  | None, _ -> Error (`Not_a_direct_dependency m1)
  | _, None -> Error (`Not_a_direct_dependency m2)
  | Some t1, Some t2 -> begin
      let g = G.edge (m1, t1) (m2, t2) g in
      Ok { cr with graph = Packed_graph (g, (module G)) }
    end

type restrictions = [
  | `Include of name list
  | `Exclude of name list
]

let pp_restrictions ppf restrictions =
  let pp_kind, names =
    match restrictions with
    | `Include names -> Fmt.(const string "include"), names
    | `Exclude names -> Fmt.(const string "exclude"), names
  in

  Fmt.(pf ppf "(%a %a)" pp_kind () (Dump.list pp_name) names)

let pp_restrictions_option =
  let none = Fmt.(const string "{}") in
  Fmt.(option ~none pp_restrictions)

let log_source =
  Logs.Src.create "cooking.model.recipe"

module Log =
  (val Logs.src_log log_source)

let amend_restrictions cr maybe_restrictions =
  match maybe_restrictions with
  | None -> Some (`Exclude (Name_set.elements cr.excluded))
  | Some (`Include ds) -> begin
      let modified = Name_set.diff (Name_set.of_list ds) cr.excluded in
      Some (`Include (Name_set.elements modified))
    end
  | Some (`Exclude ds) -> begin
      let modified = Name_set.union (Name_set.of_list ds) cr.excluded in
      Some (`Exclude (Name_set.elements modified))
    end

let refine_actual maybe_restrictions available_externally cr =
  let actual = Name_set.(diff cr.actual available_externally) in

  match maybe_restrictions with
  | None -> actual
  | Some (`Include ds) -> Name_set.(inter actual (of_list ds))
  | Some (`Exclude names) -> Name_set.(diff actual (of_list names))

let verify_actual_satisfied maybe_restrictions already_executed cr =
  let missing_actual = refine_actual maybe_restrictions already_executed cr in

  Log.debug (fun m ->
      let pp_name_list = Fmt.(using Name_set.elements (Dump.list pp_name)) in
      m
        "With restrictions %a and %a installed, actual dependencies of %a (%a) \
         reduced to %a"
        pp_restrictions_option maybe_restrictions
        pp_name_list already_executed
        pp_name cr.name
        pp_name_list cr.actual
        pp_name_list missing_actual);

  match Name_set.elements missing_actual with
  | [] -> Ok ()
  | names -> Error (`Missing_actual_dependencies names)

let verify maybe_restrictions available_externally = function
  | Raw _ -> Ok ()
  | Cooked cr -> verify_actual_satisfied maybe_restrictions available_externally cr

let should_execute maybe_restrictions d =
  match maybe_restrictions with
  | None -> true
  | Some (`Include ds) -> List.mem d ds
  | Some (`Exclude ds) -> not (List.mem d ds)

exception Intermediate_error of error

let raise_intermediate e =
  raise_notrace (Intermediate_error e)

let require = function
  | Ok a -> a
  | Error e -> raise_intermediate e

let rec execute maybe_restrictions already_executed t =
  match t with
  | Raw d -> begin
      Log.debug (fun m -> m "Fetching raw %a" pp_name d);
      Ok []
    end
  | Cooked cr -> begin
      try
        Ok (execute_cooked_exn maybe_restrictions already_executed cr)
      with
      | Intermediate_error e -> Error e
    end
and execute_cooked_exn maybe_restrictions already_executed cr =
  Log.debug (fun m -> m "Starting to cook %a" pp_name cr.name);
  let Packed_graph (g, (module G)) = cr.graph in

  match G.sort g with
  | None -> raise_intermediate `Dependency_cycle
  | Some sorted_pairs -> begin
      let executed = ref [] in
      let already_executed = ref already_executed in

      let mark_completed cooked_names =
        Log.debug (fun m ->
            match cooked_names with
            | [] -> ()
            | _ -> m "%a marked %a completed" pp_name cr.name Fmt.(Dump.list pp_name) cooked_names);

        executed := cooked_names @ !executed;
        already_executed := Name_set.(union !already_executed (of_list cooked_names))
      in

      List.iter
        (fun (name, t) ->
           match execute_dependency_exn maybe_restrictions !already_executed t with
           | Some cooked_names -> begin
               mark_completed cooked_names;
               require (verify maybe_restrictions !already_executed t);
               Log.debug (fun m -> m "Done %a" pp_name name);
               mark_completed [name]
             end
           | None -> ())
        sorted_pairs;

      !executed
    end
and execute_dependency_exn maybe_restrictions already_executed t =
  let maybe_restrictions =
    match t with
    | Raw _ -> maybe_restrictions
    | Cooked cr -> amend_restrictions cr maybe_restrictions
  in

  let name = name t in

  if not (should_execute maybe_restrictions name) then None
  else Some (require (execute maybe_restrictions already_executed t))

let execute ?restrictions t =
  execute restrictions Name_set.empty t
  |> R.map List.rev

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
