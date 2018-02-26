Diff
====

A simple diff library in Elixir


## Diff.diff

Compares 2 terms that have an implementation of the `Diff.Diffable` protocol and returns a list of changes from the first given binary with the second

The diff function can take the following options:

* `:keep_unchanged` - keeps unchanged binary parts in the returned patches
* `:ignore` - a regex used to ignore element. Ignored parts are kept in returned in patches

Usage:

```elixir
iex(1)> Diff.diff("test", "taste")
[%Diff.Modified{index: 1, length: 1, old_element: ["e"], element: ["a"]},
%Diff.Insert{index: 4, length: 1, element: ["e"]}]
```


## Diff.patch

Applies the given patches to the term. Takes an optional third parameter to turn
the patched list created from applying the patches back into the type needed.


Usage:
```elixir
iex(1)> patches = Diff.diff([1, 2, 3, 4], [1, 5, 6, 4, 8])
[%Diff.Modified{element: [5, 6], index: 1, length: 2, old_element: [2, 3]},
 %Diff.Insert{element: '\b', index: 4, length: 1}]

iex(2)> Diff.patch([1, 2, 3, 4], patches)
[1, 5, 6, 4, 8]
```


```elixir
iex(1)> patches = Diff.diff("test", "taste")
[%Diff.Modified{index: 1, length: 1, old_element: ["e"], element: ["a"]},
%Diff.Insert{index: 4, length: 1, element: ["e"]}]

iex(2)> Diff.patch("test", patches, &Enum.join/1)
"taste"
```

## Diff.annotated_patch

`Diff.annotated_patch` takes a a data structure of annotations, and uses them when applying the patch.

Usage:
```elixir
iex(1)>  annotations =   [
...(1)>     %{delete:   %{before: "<span class='deleted'>",
...(1)>                   after:  "</span>"}},
...(1)>     %{insert:   %{before: "<span class='inserted'>",
...(1)>                   after:  "</span>"}},
...(1)>     %{modified: %{before: "<span class='modified'>",
...(1)>                   after:  "</span>"}}
...(1)> ]
[%{delete: %{after: "</span>", before: "<span class='deleted'>"}},
 %{insert: %{after: "</span>", before: "<span class='inserted'>"}},
 %{modified: %{after: "</span>", before: "<span class='modified'>"}}]
iex(2)> patches = Diff.diff("test", "tast")
[%Diff.Modified{element: ["a"], index: 1, length: 1, old_element: ["e"]}]
iex(3)> Diff.annotated_patch("test", patches, annotations)
iex(3)> Diff.annotated_patch("test", patches, annotations)
["t", "<span class='modified'>", "a", "</span>", "s", "t"]
```

It takes the same optional join function as `Diff.patch` as you would expect

`Diff.diff`, `Diff.patch` and `Diff.annotated_patch` all take as a first parameter a term that has an implementation of the `Diff.Diffable` protocol.
By default one exist for `BitString` and `List`
