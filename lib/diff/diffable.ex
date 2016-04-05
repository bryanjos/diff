defprotocol Diff.Diffable do
  @moduledoc """
  Protocol used by `Diff` module to turn input into a list
  to calculate diffs
  """
  def to_list(diffable)
end

defimpl Diff.Diffable, for: BitString do
  def to_list(diffable) do
    String.graphemes(diffable)
  end
end

defimpl Diff.Diffable, for: List do
  def to_list(diffable) do
    diffable
  end
end
