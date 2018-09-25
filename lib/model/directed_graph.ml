open Directed_graph_intf

module Make (K : LABEL) (V : sig type t end) () = struct
  type label = K.t

  type value = V.t

  type pair = label * value

  module M =
    Map.Make (K)

  module S =
    Set.Make (K)

  type t = (value * S.t) M.t

  let empty =
    M.empty

  let node k v t =
    t
    |> M.update k (function
        | None -> Some (v, S.empty)
        | Some (_, es) -> Some (v, es))

  let edge (k1, v1) (k2, v2) t =
    t
    |> M.update k1 (function
        | None -> Some (v1, S.singleton k2)
        | Some (_, es) -> Some (v1, S.add k2 es))
    |> M.update k2 (function
        | None -> Some (v2, S.empty)
        | Some (_, es) -> Some (v2, es))

  let value label t =
    M.find_opt label t
    |> (function
        | None -> None
        | Some (v, _) -> Some v)

  let pairs t =
    M.bindings t |> List.map (fun (label, (value, _)) -> label, value)

  type marking =
    | Temporary
    | Permanent

  let sort t =
    let exception Cycle in
    let ys = ref [] in
    let unmarked = ref (M.bindings t |> List.map fst |> S.of_list) in
    let markings = ref (t |> M.map (fun _ -> None)) in

    let mark_with m label =
      markings := !markings |> M.update label (function
          | Some _ -> Some (Some m)
          | _ -> assert false);

      unmarked := S.remove label !unmarked
    in

    let rec visit label =
      let marking = M.find label !markings in
      let v, egress = M.find label t in

      match marking with
      | Some Permanent -> ()
      | Some Temporary -> raise Cycle
      | None -> begin
          mark_with Temporary label;
          egress |> S.iter visit;
          mark_with Permanent label;
          ys := (label, v) :: !ys
        end
    in

    let rec loop () =
      match S.elements !unmarked with
      | [] -> ()
      | n :: _ -> begin
          visit n;
          loop ()
        end
    in

    try
      loop ();
      Some !ys
    with
    | Cycle -> None
end

let%test_module _ =
  (module struct
    module G =
      Make
        (struct
          type t = string

          let compare x y =
            String.compare x y
        end)
        (struct
          type t = int
        end)
        ()

    let%test "An empty graph has no nodes" =
      match G.(pairs empty) with
      | [] -> true
      | _ -> false

    let%test "Edges can be added to a graph" =
      match G.(empty |> edge ("a", 1) ("b", 2) |> pairs) with
      | ["a", 1; "b", 2] -> true
      | _ -> false

    let%test "Referencing an existing node when adding an edge changes the value" =
      let g = G.(empty |> edge ("a", 1) ("b", 2) |> edge ("a", 10) ("c", 3)) in

      match G.pairs g with
      | ["a", 10; "b", 2; "c", 3] -> true
      | _ -> false

    let%test "A node's value can be queried based on its name" =
      let g = G.(empty |> edge ("a", 1) ("b", 2) |> edge ("a", 1) ("c", 3) |> edge ("b", 2) ("c", 3)) in

      match G.value "b" g with
      | Some 2 -> true
      | _ -> false

    let%test "An acyclic graph can be topologically sorted" =
      let g =
        G.empty
        |> G.edge ("a", 1) ("b", 2)
        |> G.edge ("a", 1) ("c", 3)
        |> G.edge ("b", 2) ("c", 3)
      in

      match G.sort g with
      | Some xs -> xs = ["a", 1; "b", 2; "c", 3]
      | None -> false

    let%test "A graph with cycles cannot be topologically sorted" =
      let g =
        G.empty
        |> G.edge ("a", 1) ("b", 2)
        |> G.edge ("a", 1) ("c", 3)
        |> G.edge ("c", 3) ("b", 2)
        |> G.edge ("b", 2) ("a", 1)
      in

      match G.sort g with
      | Some _ -> false
      | None -> true
  end)

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
