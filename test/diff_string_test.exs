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

  test "ignores properly" do
    original = "test"
    changed = "test test"

    patches = Diff.diff(original, changed, ignore: ~r/^\s+$/)
    assert List.last(patches) == %Diff.Ignored{index: 4, length: 1, element: [" "]}
  end

  # rest of the tests are models tests
  # take two strings and generate a set of patches
  # apply the patches to the original and assert that it matches
  # the changed string

  test "applies patches when strings match" do
    original = "test"
    changed = "test"

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
  end


  test "applies patches when one character is added" do
    original = "test"
    changed = "tests"

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
  end

  test "applies patches correctly when one character is removed" do
    original = "test"
    changed = "tes"

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
  end

  test "applies patches correctly when one character is modified" do
    original = "test"
    changed = "tesr"

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
  end

  # regression tests
  test "applies patches correctly with mixed inserts and deletes" do
    original = "xab"
    changed = "x1a2"

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
  end

  test "applies patches correctly with mixed inserts and deletes (2)" do
    original = "abcc"
    changed = "bd"

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
  end

  test "applies patches correctly with mixed inserts and deletes (3)" do
    original = "aabc"
    changed = "be"

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
  end

  # bang a random test in see how she goes
  test "random stuff going on" do

    original = "sfjksfjk324m, b0 sdlkaj kdsf "
    changed = "iuw ewjnpjenjew o90ufdh ewnm2320y"

    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
  end

  # Fuzz test - generate random strings and check they all work

  test "fuzz test" do
    fuzz(1000)
  end

  defp fuzz(0) do
    :ok
  end

  defp fuzz(n) when is_integer(n) and n > 0 do

    no_of_chars = 100
    offset   = :crypto.rand_uniform(0, no_of_chars)
    sign     = :crypto.rand_uniform(0, 2) -1
    original = :crypto.strong_rand_bytes(no_of_chars)
    changed  = :crypto.strong_rand_bytes(no_of_chars + (offset * sign))
    patches = Diff.diff(original, changed)
    assert Diff.patch(original, patches, &Enum.join/1) == changed
    fuzz(n - 1)
  end

end
