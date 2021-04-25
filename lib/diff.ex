defmodule Diff do
  alias Diff.Matrix
  alias Diff.Diffable

  @moduledoc """
  Functions for performing diffs.
  """

  defmodule Insert do
    defstruct [:element, :index, :length]
  end

  defmodule Delete do
    defstruct [:element, :index, :length]
  end

  defmodule Modified do
    defstruct [:element, :old_element, :index, :length]
  end

  defmodule Unchanged do
    defstruct [:element, :index, :length]
  end

  defmodule Ignored do
    defstruct [:element, :index, :length]
  end

  @doc """
  Applies with patches with supplied annotation (top and tail)
  This is used to generate visual diffs, etc
  Shares the same code as patch
  """
  def annotated_patch(original, patches, annotations, from_list_fn \\ fn list -> list end) do
    apply_patches(original, patches, annotations, from_list_fn)
  end

  @doc """
  Applies the patches from a previous diff to the given string.
  Will return the patched version as a list unless a from_list_fn/1 is supplied.
  This function will takes the patched list as input and outputs the result.
  """
  def patch(original, patches, from_list_fn \\ fn list -> list end) do
    apply_patches(original, patches, [], from_list_fn)
  end

  defp apply_patches(original, patches, annotations, from_list_fn) do
    original = Diffable.to_list(original)

    patchfn = fn patch, {increment, changed} ->
      do_patch({increment, changed}, patch, annotations)
    end

    increment = 0
    {_, returnlist} = Enum.reduce(patches, {increment, original}, patchfn)
    from_list_fn.(returnlist)
  end

  defp do_patch({incr, original}, %Diff.Insert{element: element, index: index}, annotations) do
    {left, right} = Enum.split(original, index + incr)
    {newelement, newincr} = annotate(element, :insert, annotations, incr)
    return = left ++ newelement ++ right
    {newincr, return}
  end

  defp do_patch(
         {incr, original},
         %Diff.Delete{element: element, index: index, length: length},
         annotations
       ) do
    {left, deleted} = Enum.split(original, index + incr)
    {actuallydeleted, right} = Enum.split(deleted, length)

    case element do
      ^actuallydeleted ->
        {newelement, newincr} = annotate(element, :deleted, annotations, incr)
        return = left ++ newelement ++ right
        {newincr, return}

      _other ->
        exit("failed delete")
    end
  end

  defp do_patch(
         {incr, original},
         %Diff.Modified{element: element, old_element: _, index: index, length: length},
         annotations
       ) do
    {left, deleted} = Enum.split(original, index + incr)
    {_, right} = Enum.split(deleted, length)
    {newelement, newincr} = annotate(element, :modified, annotations, incr)
    return = left ++ newelement ++ right
    {newincr, return}
  end

  defp do_patch({incr, original}, %Diff.Unchanged{}, _annotations) do
    {incr, original}
  end

  defp do_patch({incr, original}, %Diff.Ignored{element: element, index: index}, annotations) do
    {left, right} = Enum.split(original, index + incr)
    {newelement, newincr} = annotate(element, :ignored, annotations, incr)
    return = left ++ newelement ++ right
    {newincr, return}
  end

  @doc """
  Creates a list of changes from the orginal binary to the changed one.
  Takes the following options:

  * `:keep_unchanged` - Keeps unchanged binary parts in the returned patches
  * `ignore` - Takes a regex and ignores matches
  """
  def diff(original, changed, options \\ []) do
    original = Diffable.to_list(original)
    changed = Diffable.to_list(changed)

    original_length = length(original)
    changed_length = length(changed)

    longest_common_subsequence(original, changed, original_length, changed_length)
    |> build_diff(original, changed, original_length, changed_length, [], options)
    |> build_changes(options)
  end

  defp longest_common_subsequence(x, y, x_length, y_length) do
    matrix = Matrix.new(x_length + 1, y_length + 1)

    # a reduction over a 2D array requires a closure inside an anonymous function
    # sorry but there is nothing to be done about that
    rowreductionFn = fn i, matrix ->
      # setup the second closure
      columnreductionFn = fn j, matrix ->
        if Enum.fetch!(x, i - 1) == Enum.fetch!(y, j - 1) do
          value = Matrix.get(matrix, i - 1, j - 1)
          Matrix.put(matrix, i, j, value + 1)
        else
          original_value = Matrix.get(matrix, i, j - 1)
          changed_value = Matrix.get(matrix, i - 1, j)

          Matrix.put(matrix, i, j, max(original_value, changed_value))
        end
      end

      Enum.reduce(1..y_length, matrix, columnreductionFn)
    end

    _matrix = Enum.reduce(1..x_length, matrix, rowreductionFn)
  end

  defp build_diff(matrix, x, y, i, j, edits, options) do
    cond do
      i > 0 and j > 0 and Enum.fetch!(x, i - 1) == Enum.fetch!(y, j - 1) ->
        newedits =
          if Keyword.get(options, :keep_unchanged, false) do
            edits ++ [{:unchanged, Enum.fetch!(x, i - 1), i - 1}]
          else
            edits
          end

        build_diff(matrix, x, y, i - 1, j - 1, newedits, options)

      j > 0 and (i == 0 or Matrix.get(matrix, i, j - 1) >= Matrix.get(matrix, i - 1, j)) ->
        newedit = {:insert, Enum.fetch!(y, j - 1), j - 1}
        build_diff(matrix, x, y, i, j - 1, edits ++ [newedit], options)

      i > 0 and (j == 0 or Matrix.get(matrix, i, j - 1) < Matrix.get(matrix, i - 1, j)) ->
        newdelete = {:delete, Enum.fetch!(x, i - 1), j}
        build_diff(matrix, x, y, i - 1, j, edits ++ [newdelete], options)

      true ->
        edits |> Enum.reverse()
    end
  end

  defp build_changes(edits, options) do
    # we now have a set of individual letter changes
    # but if there is a series of inserts or deletes then
    # we need to reduce them into single multichar changes
    mergeindividualchangesFn = fn {type, char, index}, changes ->
      if changes == [] do
        changes ++ [make_change(type, char, index)]
      else
        change = List.last(changes)
        regex = Keyword.get(options, :ignore)

        cond do
          regex && Regex.match?(regex, char) ->
            changes ++ [make_change(:ignored, char, index)]

          # one branch for deletes
          is_type(change, type) && type == :delete && index == change.index ->
            change =
              if regex && Regex.match?(regex, Enum.join(change.element)) do
                %Ignored{element: change.element, index: change.index, length: change.length}
              else
                %{change | element: change.element ++ [char], length: change.length + 1}
              end

            List.replace_at(changes, length(changes) - 1, change)

          # a different branch for everyone else
          is_type(change, type) && type != :delete && index == change.index + change.length ->
            change =
              if regex && Regex.match?(regex, Enum.join(change.element)) do
                %Ignored{element: change.element, index: change.index, length: change.length}
              else
                %{change | element: change.element ++ [char], length: change.length + 1}
              end

            List.replace_at(changes, length(changes) - 1, change)

          true ->
            changes ++ [make_change(type, char, index)]
        end
      end
    end

    # if we change a single letter it will be a consecutive delete/insert
    # this reduction merges them into a single modified statement
    makemodifiedFn = fn x, changes ->
      if changes == [] do
        [x]
      else
        last_change = List.last(changes)

        if is_type(last_change, :delete) and
             is_type(x, :insert) and
             last_change.index == x.index and
             last_change.length == x.length do
          last_change = %Modified{
            element: x.element,
            old_element: last_change.element,
            index: x.index,
            length: x.length
          }

          List.replace_at(changes, length(changes) - 1, last_change)
        else
          changes ++ [x]
        end
      end
    end

    # Now do both these sets of reduction on the edits
    Enum.reduce(edits, [], mergeindividualchangesFn)
    |> Enum.reduce([], makemodifiedFn)
  end

  defp make_change(:insert, char, index) do
    %Insert{element: [char], index: index, length: 1}
  end

  defp make_change(:delete, char, index) do
    %Delete{element: [char], index: index, length: 1}
  end

  defp make_change(:unchanged, char, index) do
    %Unchanged{element: [char], index: index, length: 1}
  end

  defp make_change(:ignored, char, index) do
    %Ignored{element: [char], index: index, length: 1}
  end

  defp is_type(%Insert{}, :insert) do
    true
  end

  defp is_type(%Delete{}, :delete) do
    true
  end

  defp is_type(%Unchanged{}, :unchanged) do
    true
  end

  defp is_type(%Ignored{}, :ignored) do
    true
  end

  defp is_type(_, _) do
    false
  end

  defp annotate(list, type, annotations, increment) do
    annotation = for a <- annotations, Map.get(a, type) != nil, do: Map.get(a, type)

    case {type, annotation} do
      {:deleted, []} -> {[], increment}
      {_, []} -> {list, increment}
      {:deleted, [annotation]} -> apply_deletion(list, annotation, increment)
      {_, [annotation]} -> apply_annotation(list, annotation, increment)
    end
  end

  defp apply_deletion(list, annotation, increment) do
    {[annotation.before] ++ list ++ [annotation.after], increment + 2}
  end

  defp apply_annotation(list, annotation, increment) do
    {[annotation.before] ++ list ++ [annotation.after], increment + 2}
  end
end
