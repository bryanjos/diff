defmodule Diff do
  alias Diff.Matrix

  @moduledoc """
  Functions for performing diffs on two binaries
  """
  

  defmodule Insert do
    defstruct [:text, :index, :length]
  end

  defmodule Delete do
    defstruct [:text, :index, :length]
  end

  defmodule Modified do
    defstruct [:text, :old_text, :index, :length]
  end

  defmodule Unchanged do
    defstruct [:text, :index, :length]
  end

  defmodule Ignored do
    defstruct [:text, :index, :length]
  end

  @doc """
  Applies the patches from a previous diff to the given string
  """
  def patch(original, patches) do
    Enum.reduce(patches, original, fn(patch, changed) ->
      do_patch(changed, patch)
    end)
  end

  defp do_patch(original, %Insert{text: text, index: index}) do
    {left, right} = String.split_at(original, index)
    left <> text <> right
  end

  defp do_patch(original, %Delete{text: _, index: index, length: length}) do
    {left, deleted} = String.split_at(original, index)
    {_, right} = String.split_at(deleted, length)
    left <> right
  end

  defp do_patch(original, %Modified{text: text, old_text: _, index: index, length: length}) do
    {left, deleted} = String.split_at(original, index)
    {_, right} = String.split_at(deleted, length)
    left <> text <> right
  end

  defp do_patch(original, %Unchanged{}) do
    original
  end

  defp do_patch(original, %Ignored{text: text, index: index}) do
    {left, right} = String.split_at(original, index)
    left <> text <> right
  end

  @doc"""
  Returns an ANSI formatted string from the patches.
  """
  def format(patches) do
    format(patches, [:default_color, :normal], [:green, :bright], [:red, :bright])
  end

  @doc"""
  Does a diff on the original and changed binaries and formats them
  """
  def format(original, changed) do
    diff(original, changed, keep_unchanged: true)
    |> format
  end

  @doc"""
  Same as format/2, but allows for the normal, insert, and delete formats to be customized
  all must be an array of formatting options for each type
  """
  def format(original, changed, normal_format, insert_format, delete_format) do
    diff(original, changed, [keep_unchanged: true, ignore: ~r/\s+/])
    |> format(normal_format, insert_format, delete_format)
  end

  @doc"""
  Same as format/1, but allows for the normal, insert, and delete formats to be customized
  all must be an array of formatting options for each type
  """  
  def format(patches, normal_format, insert_format, delete_format) do

    Enum.map(patches, fn
      (%Unchanged{text: text}) ->
        normal_format ++ [text]
      (%Ignored{text: text}) ->
        normal_format ++ [text]                        
      (%Insert{text: text}) ->
        insert_format ++ [text]
      (%Delete{text: text}) ->
        delete_format ++ [text]
      (%Modified{text: text, old_text: old_text}) ->
        delete_format ++ [old_text] ++ insert_format ++ [text]  
    end)
    |> List.flatten
    |> IO.ANSI.format(true)
  end
  

  @doc"""
  Creates a list of changes from the orginal binary to the changed one.
  Takes the following options:

  * `:keep_unchanged` - Keeps unchanged binary parts in the returned patches
  * `ignore` - Takes a regex and ignores matches
  """
  def diff(original, changed, options \\ []) do
    original = String.graphemes(original)
    changed = String.graphemes(changed)

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
            change = %{change | text: change.text <> char, length: change.length + 1 }

            if regex && Regex.match?(regex, change.text) do
              change = %Ignored{ text: change.text, index: change.index, length: change.length }
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

        if is_type(last_change,:delete) and is_type(x,:insert) and last_change.index == x.index and last_change.length == x.length do
          last_change = %Modified{ text: x.text, old_text: last_change.text, index: x.index, length: x.length }
          List.replace_at(changes, length(changes)-1, last_change)          
        else
          changes ++ [x]
        end  
      end
      end)
  end
  

  defp change(:insert, char, index) do
    %Insert{ text: char, index: index, length: 1 }
  end

  defp change(:delete, char, index) do
    %Delete{ text: char, index: index, length: 1 }    
  end

  defp change(:unchanged, char, index) do
    %Unchanged{ text: char, index: index, length: 1 }    
  end

  defp change(:ignored, char, index) do
    %Ignored{ text: char, index: index, length: 1 }    
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
