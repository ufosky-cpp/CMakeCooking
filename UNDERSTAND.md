# Understanding cmake-cooking

## Problem statement

Consider a CMake project `p`.

In general, building a project with CMake consists of two steps. The first is the "configure" step. In this step, CMake will query the local file-system and conduct other tests to ensure that all of the requirements of the project are satisfied. For example, a project could depend on the GnuTLS library being installed and available. The results of this step are saved in a "cache", which is a specification of variables (such as `GnuTLS_INCLUDE_DIR`) and their values. The second step is to build the project by invoking the compiler based on the contents of the cache.

Consider the following five example projects, which each implement a simple mathematical function:

- "egg": A shared library defining `e(x) = x + 2`
- "durian": A shared library defining `d(x) = 10 * x`
- "carrot": A shared library defining `c(x) = d(x) - e(x)`
- "banana": A shared library defining `b(x) = c(x) * d(x)`
- "apple": An executable defining `a(x) = b(x) + e(x)` and which displays the result of ``a(5)`

(Names such as `d` will be used in other contexts, and they do not refer to the functions defined above.)

Let us define the following notation:

    b -> a
    
means that the project `b` must be installed to the file-system before the project `a` can be configured and/or built and/or executed.

We can say `b -> a` as "`a` depends on `b`."

Let us define the "direct" dependencies of a project as the ones whose components are referenced explicitly by the project.

An example will make this definition clear.

Let `d(p)` denote the set of direct dependencies of project `p`. Each project `x` such that `x in d(p)` satisfies `x -> p`.

The direct dependencies of the above examples are as follows:

- `d(egg) = {}`
- `d(durian) = {}`
- `d(carrot) = {durian, egg}`
- `d(banana) = {carrot, durian}`
- `d(apple) = {banana, egg}`

For example, `banana` has direct dependencies on `carrot` and `durian`. This means that as long as `carrot` and `durian` are accessible on the file-system then `banana` can be configured, built, and installed. `banana` shouldn't, in principle, need to know anything about `carrot` or `durian` themselves.

However, `carrot` has its own direct dependencies which become "transitive" dependencies of a project that depends on "carrot"

Suppose `d(p) = {x_1, x_2, ..., x_n}` for some project `p`. Then the transitive dependencies on `p` are defined `t(p) = d(p) U t(x_1) U t(x_2) U ... U t(x_n)`. Here, `U` denotes the union of two sets.
    
Therefore, the transitive dependencies of our above examples are:

- `t(egg) = {}`
- `t(durian) = {}`
- `t(carrot) = {durian, egg}`
- `t(banana) = {carrot, durian, egg}`
- `t(apple) = {banana, carrot, durian, egg}`

To illustrate the example of `banana`, in order to successfully configure the project we must ensure that each of `carrot`, `durian`, and `egg` are first installed and available on the file-system (in some unspecified order).

The transitive dependencies of a project (and the project itself) form a directed graph where each pair of projects in the set `t(p)` for which `y in d(x)` (that is, `y` is a direct dependency of `x`) contributes an edge in the graph from `y` to `x`.

In order to successfully configure and build a project `p`, we must configure, build, and install each of the projects in this graph exactly once while insuring that if `x -> y` than `y` is never executed before `x`. The order in which we do this is called a "recipe". For a recipe for a project `p` to exist, the directed graph formed must be acyclic: a "directed acyclic graph" (DAG).

## A language for recipes

We will describe a small language for writing recipes.

The notation `e : t` means that the value `e` has type `t`. The notation `x => y` describes a function taking a value of type `x` and producing a value of type `y`. The notation `f e` means to apply a function `f : x => y` to a value `e : x` and produce a value of type `y`. The notation `n := e` means to assign the value produced by evaluating the expression `e` to the name `n`. Finally, a type can be parametric in terms of another type. This is useful for describing types such as collections. For example, a `string set` is a parametric type `'a set` with its type parameter (`'a`) being `string`.

Note that while, at first glance, this notation appears to only allows for functions of a single value, we can express a function of multiple values as follows:

    f : string => (string => (string => string))
    
which can be written more simply as

    f : string => string => string => string
    
and instead of writing

    x := ((f "a") "b") "c"
    
we will simply write

    x := f "a" "b" "c"

For simplicity, in this document we will model errors as exceptional values that are not reflected in the type-system.

A recipe has a name:

    type name = string
    
(This is the definition of a new type).

We will call the product of a recipe an "ingredient".

One kind of ingredient is "raw". That is, it has no direct dependencies. We represent this kind of recipe as an opaque type:

    type raw
    
We can define recipes for raw ingredients with this function (with the same name as the type):

    raw : name => raw    

Another kind of ingredient is "cooked": in order to prepare this ingredient we must first prepare other ingredients. That is, the ingredient does have direct dependencies. We also represent this as an opaque type.

    type cooked
    
We can begin describing a recipe for cooked ingredients with this function:

    blank : name => name set => cooked
    
The second argument of `blank` describes the "real" transitive dependency set of the project. We use this set to verify that our recipe includes everything necessary.
    
For example, to describe `egg` above, we would define `e := raw "egg"`. Similarly, we could begin the recipe for "carrot" with `blank "carrot" {"durian"; "egg"}` (note that this is an incomplete recipe for `carrot`).

`requires` is a function which amends a recipe for a cooked ingredient to indicate that another project is necessary as part of it as a direct dependency:

    requires : raw => cooked => cooked
    
For example, we can define the recipe for `carrot` as follows:

    c := requires e (requires d (blank "carrot" {"durian"; "egg"}))
    
If we define an operator `|> : (a => (a => b)) => b` then we can express this as

    c := blank "carrot" {"durian"; "egg"} |> requires d |> requires d
    
The effect, in terms of our direct graph model, of `requires rr cr` is to add a node with the name of `rr` to the graph of `cr` and an edge from the new node to the "target" (the node corresponding to the name of `cr`) of `cr`.

Projects added to a recipe as direct dependencies of a cooked ingredient may themselves depend on one another directly. Therefore we define

    before : name => name => cooked => cooked

`before d1 d2 cr` produces a recipe for a cooked ingredient in which an edge exists from the target node of the recipe for `d1` to the target node of the recipe for `d2` assuming the graphs of both names are already present in `cr` as direct dependencies (it is an error if they are not).

The `requires` function is useful for building recipes where recipes can be composed of raw ingredients. However, we must account for projects which are required by more than one recipe and the way this impacts our two requirements. Recall that each project must appear once in the recipe and the graph corresponding to the recipe must be acyclic.

Therefore, we introduce the following function:

    prepares : cooked => name set => cooked => cooked
    
`prepares names dcr ds cr` produces a recipe for a cooked ingredient in which the graph corresponding to each name in the set `ds` is removed from the graph defined by `dcr` (if it is present), and this modified recipe (`cr''`) is added to the graph of `cr`.

We will illustrate the importance of this function later.

We now define

    type recipe =
      | Raw of raw
      | Cooked of cooked

to be able to describe recipes for either cooked or raw ingredients (this notation means that a value of type `recipe` can either be a value of `(Raw rr)` or `(Cooked cr)`).

We also define

    execute : restrictions => name set => recipe => name list
    
where `restrictions` is:

    type restrictions = 
      | Include of name set
      | Exclude of name set

This function executes each of the projects in the recipe (subject to the restrictions) according to the dependency graph and produces a list describing the order in which they were executed (excluding the target node). If any of the actual dependencies of any ingredient are not satisfied, then this function will produce an error.

## Examples

The recipe `egg` has no dependencies:

    e := raw "egg"
    
The recipe `durian` also has no dependencies:

    d := raw "durian"
    
The recipe `carrot` depends on both `durian` and `egg`:
    
    e :=
        blank "carrot" {"egg", "durian"}
        |> requires e
        |> requires d


    C <--- D
    
    ^
    |
    E
    
One possible order of execution for `carrot` is either D, E, C.

The recipe `banana` depends on `durian` and `carrot`. Because `carrot` also depends on `durian`, we need to exclude `durian` from `carrot` when it is nested in `banana`.

    b :=
        blank "banana" {"egg", "durian", "carrot"}
        |> requires d
        |> prepares c {"durian"}
        |> before "durian" "carrot"


    B <----D
           |
    ^      |
    |      |
    C <----/
    
    ^
    |
    E
    
One possible order of execution is E, D, C, B.

The recipe `apple` depends on `egg` and `banana`. Because `banana` also depends on `egg`, we need to exclude `egg` from `banana` when it is nested in `apple`.

    a :=
        blank "apple" {"egg", "durian", "carrot", "banana"}
        |> requires e
        |> prepares b {"egg"}
        |> before "egg" "banana"


           A <----E
                  |
           ^      |
           |      |
    D----> B <----/
    |
    |      ^
    |      |
    \----> C
    
One possible order of execution is E, D, C, B, A.
