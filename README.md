Diff
====

A diff library in Elixir


## Diff.diff

Compares 2 binaries and returns a list of changes from the first given binary with the second

The diff function can take the following options:

* `:keep_unchanged` - keeps unchanged binary parts in the returned patches
* `:ignore` - a regex used to ignore text. Ignored parts are kept in returned in patches

Usage:

```elixir
iex(1)> Diff.diff("test", "taste")
[%Diff.Modified{index: 1, length: 1, old_text: "e", text: "a"},
%Diff.Insert{index: 4, length: 1, text: "e"}]
```


## Diff.patch

Applies the given patches to the binary


Usage:

```elixir
iex(1)> patches = Diff.diff("test", "taste")
[%Diff.Modified{index: 1, length: 1, old_text: "e", text: "a"},
%Diff.Insert{index: 4, length: 1, text: "e"}]

iex(2)> Diff.patch("test", patches)
"taste"
```
