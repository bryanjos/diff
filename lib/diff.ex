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
  Applies the patches from a previous diff to the given string.
  Will return the patched version as a list unless a from_list_fn/1 is supplied.
  This function will takes the patched list as input and outputs the result.
  """
  def patch(original, patches, from_list_fn \\ fn(list) -> list end) do
    original = Diffable.to_list(original)

    Enum.reduce(patches, original, fn(patch, changed) ->
      do_patch(changed, patch)
    end)
    |> from_list_fn.()
  end

  defp do_patch(original, %Diff.Insert{element: element, index: index}) do
    { left, right } = Enum.split(original, index)
    left ++ element ++ right
  end

  defp do_patch(original, %Diff.Delete{ element: _, index: index, length: length }) do
    { left, deleted } = Enum.split(original, index)
    { _, right } = Enum.split(deleted, length)
    left ++ right
  end

  defp do_patch(original, %Diff.Modified{element: element, old_element: _, index: index, length: length}) do
    { left, deleted } = Enum.split(original, index)
    { _, right } = Enum.split(deleted, length)
    left ++ element ++ right
  end

  defp do_patch(original, %Diff.Unchanged{}) do
    original
  end

  defp do_patch(original, %Diff.Ignored{element: element, index: index}) do
    { left, right } = Enum.split(original, index)
    left ++ element ++ right
  end

  @doc"""
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

    matrix = Enum.reduce(1..x_length, matrix, fn(i, matrix) ->

      Enum.reduce(1..y_length, matrix, fn(j, matrix) ->

      if Enum.fetch!(x, i-1) == Enum.fetch!(y, j-1) do
        value = Matrix.get(matrix, i-1, j-1)
        Matrix.put(matrix, i, j, value + 1)
      else
        original_value = Matrix.get(matrix, i, j-1)
        changed_value = Matrix.get(matrix, i - 1, j)

        Matrix.put(matrix, i, j, max(original_value, changed_value))
      end

      end)

    end)

    matrix
  end

  defp build_diff(matrix, x, y, i, j, edits, options) do
    cond do
      i > 0 and j > 0 and Enum.fetch!(x, i-1) == Enum.fetch!(y, j-1) ->
      if Dict.get(options, :keep_unchanged, false) do
        edits = edits ++ [{:unchanged, Enum.fetch!(x, i-1), i-1}]
      end

        build_diff(matrix, x, y, i-1, j-1, edits, options)
      j > 0 and (i == 0 or Matrix.get(matrix, i, j-1) >= Matrix.get(matrix,i-1, j)) ->
        build_diff(matrix, x, y, i, j-1, edits ++ [{:insert, Enum.fetch!(y, j-1), j-1}], options)
      i > 0 and (j == 0 or Matrix.get(matrix, i, j-1) < Matrix.get(matrix, i-1, j)) ->
        build_diff(matrix, x, y, i-1, j, edits ++ [{:delete, Enum.fetch!(x, i-1), i-1}], options)
      true ->
        edits |> Enum.reverse
    end
  end

  defp build_changes(edits, options) do
    Enum.reduce(edits, [], fn({type, char, index}, changes) ->
      if changes == [] do
        changes ++ [change(type, char, index)]
      else
        change = List.last(changes)
        regex = Dict.get(options, :ignore)

        cond do
          regex && Regex.match?(regex, char) ->
            changes ++ [change(:ignored, char, index)]
          is_type(change, type) && index == (change.index + change.length) ->
            change = %{change | element: change.element ++ [char], length: change.length + 1 }

            if regex && Regex.match?(regex, Enum.join(change.element)) do
              change = %Ignored{ element: change.element, index: change.index, length: change.length }
            end

            List.replace_at(changes, length(changes)-1, change)
          true ->
           changes ++ [change(type, char, index)]

        end
      end


      end)

      |> Enum.reduce([], fn(x, changes) ->
      if changes == [] do
        [x]
      else
        last_change = List.last(changes)

        if is_type(last_change, :delete) and is_type(x, :insert) and last_change.index == x.index and last_change.length == x.length do
          last_change = %Modified{ element: x.element, old_element: last_change.element, index: x.index, length: x.length }
          List.replace_at(changes, length(changes) - 1, last_change)
        else
          changes ++ [x]
        end
      end
      end)
  end


  defp change(:insert, char, index) do
    %Insert{ element: [char], index: index, length: 1 }
  end

  defp change(:delete, char, index) do
    %Delete{ element: [char], index: index, length: 1 }
  end

  defp change(:unchanged, char, index) do
    %Unchanged{ element: [char], index: index, length: 1 }
  end

  defp change(:ignored, char, index) do
    %Ignored{ element: [char], index: index, length: 1 }
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

end
