defmodule Diff do
  alias Diff.Matrix

  defmodule Insert do
    defstruct [:text, :index, :length]
  end

  defmodule Delete do
    defstruct [:text, :index, :length]
  end

  defmodule Modified do
    defstruct [:text, :old_text, :index, :length]
  end

  #IO.puts(IO.ANSI.format(["Hello, ", :red, :bright, "world! ", :default_color, :normal, "tour"], true))

  def patch(original, patches) do
    Enum.reduce(patches, original, fn(patch, changed) ->
      do_patch(changed, patch)
    end)
  end

  defp do_patch(original, %Insert{text: text, index: index}) do
    {left, right} = String.split_at(index)
    left <> text <> right
  end

  defp do_patch(original, %Delete{text: _, index: index, length: length}) do
    {left, deleted} = String.split_at(original, index)
    {deleted, right} = String.split_at(deleted, length)
    left <> right
  end

  defp do_patch(original, %Modified{text: text, old_text: old_text, index: index, length: length}) do
    {left, deleted} = String.split_at(original, index)
    {deleted, right} = String.split_at(deleted, length)
    left <> text <> right
  end

  def format(original, patches) do
    format(original, patches, [:default_color, :normal], [:green, :bright], [:red, :bright], [:yellow, :bright])
  end
  
  def format(original, patches, normal_format, insert_format, delete_format, replace_format) do
    list = []

    Enum.reduce(patches, original, fn(%Insert{text: text, index: index}, changed) ->
      do_format(changed, patch)
    end)
    
    
  end
  

  def diff(original, changed) do
    original = String.graphemes(original)
    changed = String.graphemes(changed)

    original_length = length(original)
    changed_length = length(changed)

    longest_common_subsequence(original, changed, original_length, changed_length)
    |> build_diff(original, changed, original_length, changed_length, [])
  end

  defp longest_common_subsequence(x, y, x_length, y_length) do
    matrix = Matrix.new(x_length + 1, y_length + 1)

    matrix = Enum.reduce(1..x_length, matrix, fn(i, matrix) ->

      Enum.reduce(1..y_length, matrix, fn(j, matrix) ->
        
      if Enum.fetch!(x, i-1) == Enum.fetch!(y, j-1) do
        value = Matrix.get(matrix, i-1, j-1)
        Matrix.put(matrix, i, j, value + 1)
      else
        o_value = Matrix.get(matrix, i, j-1)
        c_value = Matrix.get(matrix, i-1, j)

        Matrix.put(matrix, i, j, max(o_value, c_value))
      end

      end)
      
    end)

    matrix
  end

  defp build_diff(matrix, x, y, i, j, edits) do
    cond do
      i > 0 and j > 0 and Enum.fetch!(x, i-1) == Enum.fetch!(y, j-1) ->
        build_diff(matrix, x, y, i-1, j-1, edits)
      j > 0 and (i == 0 or Matrix.get(matrix, i, j-1) >= Matrix.get(matrix,i-1, j)) ->
        build_diff(matrix, x, y, i, j-1, edits ++ [{:insert, Enum.fetch!(y, j-1), j-1}])
      i > 0 and (j == 0 or Matrix.get(matrix, i, j-1) < Matrix.get(matrix, i-1, j)) ->
        build_diff(matrix, x, y, i-1, j, edits ++ [{:delete, Enum.fetch!(x, i-1), i-1}])
      true ->
        edits
        |> Enum.reverse
        |> Enum.reduce([], fn({type, char, index}, changes) ->

      if changes == [] do
        changes ++ [change(type, char, index)]
      else
        change = List.last(changes)

        if is_type(change, type) && index == (change.index + change.length) do
          change = %{change | text: change.text <> char, length: change.length + 1 }
          List.replace_at(changes, length(changes)-1, change)
        else
          changes ++ [change(type, char, index)]
        end
      end
        
        
      end)

      |> Enum.reduce([], fn(x, changes) ->
      if changes == [] do
        [x]
      else
        last_change = List.last(changes)

        if is_type(last_change,:delete) and is_type(x,:insert) and last_change.index == x.index and last_change.length == x.length do
          last_change = %Modified{ text: x.text, old_text: last_change.text, index: x.index, length: x.length }
          List.replace_at(changes, length(changes)-1, last_change)          
        else
          changes ++ [x]
        end  
      end
      end)
      
      
    end
  end

  defp change(:insert, char, index) do
    %Insert{ text: char, index: index, length: 1 }
  end

  defp change(:delete, char, index) do
    %Delete{ text: char, index: index, length: 1 }    
  end

  defp is_type(%Insert{}, :insert) do
    true
  end

  defp is_type(%Delete{}, :delete) do
    true
  end

  defp is_type(_, _) do
    false
  end
  
end
