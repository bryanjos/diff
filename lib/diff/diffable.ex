defprotocol Diff.Diffable do
  def to_list(diffable)
end

defimpl Diff.Diffable, for: BitString do
  def to_list(diffable) do
    String.graphemes(diffable)
  end

  defimpl Diff.Diffable, for: List do
    def to_list(diffable) do
      diffable
    end
  end
end
