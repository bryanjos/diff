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

## Diff.format

Compares 2 binaries or takes a list of patches and returns a binary ansi formatted for display

By default, unchanged binary parts are displayed in the default color, deletes are shown in red, and inserts are shown in green. You can also customize the formatting

Usage:

```elixir
iex(1)> Diff.format("test", "taste")
[[[[[[[[[[[[[[[[[] | "\e[39m"] | "\e[22m"], "t"] | "\e[31m"] | "\e[1m"], "e"] |
          "\e[32m"] | "\e[1m"], "a"] | "\e[39m"] | "\e[22m"], "st"] |
    "\e[32m"] | "\e[1m"], "e"] | "\e[0m"]
    
iex(2)> Diff.format("test", "taste") |> IO.puts
teaste
:ok

iex(3) Diff.format("test", "taste", [:default_color, :normal], [:green, :bright], [:red, :bright]) |> IO.puts
teaste
:ok
```
