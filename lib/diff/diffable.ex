defprotocol Diff.Diffable do
  def patch(original, patches)
  def to_list(diffable)
end

defimpl Diff.Diffable, for: BitString do
  def patch(original, patches) do
    Enum.reduce(patches, original, fn
      (%Diff.Unchanged{}, changed) ->
        changed
      (patch, changed) ->
        Enum.join(do_patch(changed, patch))
    end)
  end

  defp do_patch(original, %Diff.Insert{element: element, index: index}) do
    list = Diff.Diffable.to_list(original)
    {left, right} = Enum.split(list, index)

    left ++ element ++ right
  end

  defp do_patch(original, %Diff.Delete{element: _, index: index, length: length}) do
    {left, deleted} = String.split_at(original, index)
    {_, right} = String.split_at(deleted, length)

    Diff.Diffable.to_list(left) ++ Diff.Diffable.to_list(right)
  end

  defp do_patch(original, %Diff.Modified{element: element, old_element: _, index: index, length: length}) do
    {left, deleted} = String.split_at(original, index)
    {_, right} = String.split_at(deleted, length)

    Diff.Diffable.to_list(left) ++ element ++ Diff.Diffable.to_list(right)
  end

  defp do_patch(original, %Diff.Ignored{element: element, index: index}) do
    {left, right} = String.split_at(original, index)

    Diff.Diffable.to_list(left) ++ element ++ Diff.Diffable.to_list(right)
  end

  def to_list(diffable) do
    String.graphemes(diffable)
  end

  defimpl Diff.Diffable, for: List do
    def patch(original, patches) do
      Enum.reduce(patches, original, fn(patch, changed) ->
        do_patch(changed, patch)
      end)
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

    def to_list(diffable) do
      diffable
    end
  end
end
