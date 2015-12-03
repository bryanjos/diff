defmodule Diff.List.Test do
  use ExUnit.Case

  test "no results when lists match" do
    results = Diff.diff([1, 2, 3], [1, 2, 3])
    assert results == []
  end

  test "returns changes when one item is added" do
    results = Diff.diff([1, 2, 3], [1, 2, 3, 4])
    assert results == [%Diff.Insert{ index: 3, length: 1, element: [4] }]
  end

  test "returns changes when one item is removed" do
    results = Diff.diff([1, 2, 3], [1, 2])
    assert results == [%Diff.Delete{ index: 2, length: 1, element: [3] }]
  end

  test "returns changes when one item is modified" do
    results = Diff.diff([1, 2, 3], [1, 2, 4])
    assert results == [%Diff.Modified{ index: 2, length: 1, old_element: [3], element: [4] }]
  end

  test "returns changes when modified in the middle" do
    results = Diff.diff([1, 2, 3, 4], [1, 5, 6, 4])
    assert results == [%Diff.Modified{index: 1, length: 2, old_element: [2, 3], element: [5, 6]}]
  end

  test "applies patches correctly" do
    original = [1, 2, 3, 4]
    changed = [1, 5, 6, 4, 8]

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches) == changed
  end

end
