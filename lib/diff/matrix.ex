defmodule Diff.Matrix do
  @moduledoc false

  defstruct rows: nil, columns: nil, data: nil

  def new(rows, columns) do
    %__MODULE__{
      rows: rows,
      columns: columns,
      data: %{}
    }
  end

  def get(matrix, x, y) do
    Map.get(matrix.data, {x, y}, 0)
  end

  def put(matrix, x, y, value) do
    %{matrix | data: Map.put(matrix.data, {x, y}, value)}
  end

  def size(matrix) do
    {matrix.rows, matrix.columns}
  end
end
