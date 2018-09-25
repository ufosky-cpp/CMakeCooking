(** Signatures for directed graphs. *)

(** A graph label type must have an ordering. *)
module type LABEL = sig
  type t

  val compare :
    t -> t -> int
end

(** Immutable directed graphs. *)
module type S = sig
  type t

  type label

  type value

  (** An association between a node label and its value. *)
  type pair = label * value

  (** An empty graph. *)
  val empty :
    t

  val node :
    label -> value -> t -> t

  val edge
    : pair -> pair -> t -> t
  (** [edge (k1, v1) (k2, v2) g] is the graph [g] with the addition of an edge
     from a node labelled [k1] with value [v1] to a node labelled [k2] with
     [v2]. If [k1] or [k2] refer to nodes which did not previously exist in [g]
     then they are created. Otherwise, any previous value associated with the
     labels is replaced with the new value. *)

  val value :
    label -> t -> value option
  (** [value k g] is the associated value of the node with label [k]. If no such
     node exists, then the result is {! None}. *)

  val pairs : t -> pair list
  (** [pairs g] is the list of all nodes with their associated values. The list
     is sorted according to the ordering of {! label}. *)

  val sort : t -> pair list option
  (** [sort g] is a list of node labels which reflect a topological sorting of
     the nodes in the graph [g]. The first node in the list is the one which
     should be visited first.

      If the result is {! None}, then there is a cycle in the graph and it
     cannot be sorted. *)
end

(* Copyright 2018 Jesse Haber-Kucharsky

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the
   License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
   specific language governing permissions and limitations under the License. *)
