defmodule Diff.String.Test do
  use ExUnit.Case

  test "no results when strings match" do
    results = Diff.diff("test", "test")
    assert results == []
  end

  test "returns changes when one character is added" do
    results = Diff.diff("test", "tests")
    assert results == [%Diff.Insert{index: 4, length: 1, element: ["s"]}]
  end

  test "returns changes when one character is removed" do
    results = Diff.diff("test", "tes")
    assert results == [%Diff.Delete{index: 3, length: 1, element: ["t"]}]
  end

  test "returns changes when one character is modified" do
    results = Diff.diff("test", "tesr")
    assert results == [%Diff.Modified{index: 3, length: 1, old_element: ["t"], element: ["r"]}]
  end

  test "returns changes when modified in the middle" do
    results = Diff.diff("test", "tart")
    assert results == [%Diff.Modified{index: 1, length: 2, old_element: ["e", "s"], element: ["a", "r"]}]
  end

  test "applies patches correctly" do
    original = "test"
    changed = "taste"

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
  end

  test "ignores properly" do
    original = "test"
    changed = "test test"

    patches = Diff.diff(original, changed, ignore: ~r/^\s+$/)
    assert List.last(patches) == %Diff.Ignored{index: 4, length: 1, element: [" "]}
  end

end
