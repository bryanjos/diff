defmodule Diff.Matrix do

  def new(rows, columns) do
    List.duplicate(List.duplicate(0, columns), rows)
  end

  def get(matrix, i, j) do
    list = Enum.fetch!(matrix, i)
    Enum.fetch!(list, j)
  end
  
  def put(matrix, i, j, new_value) do
    list = Enum.fetch!(matrix, i)
    list = List.update_at(list, j, fn(_) -> new_value end)
    List.update_at(matrix, i,  fn(_) -> list end) 
  end

end
