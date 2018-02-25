defmodule Diff.Annotation.Test do
  use ExUnit.Case

  test "no results when strings match" do
    original = "test"
    changed  = "test"
    patches = Diff.diff(original, changed)
    assert Diff.annotated_patch(original, patches, get_annotations(),
      &Enum.join/1) == changed
  end

  test "do a modification" do
    original = "test"
    changed  = "tast"
    patches  = Diff.diff(original, changed)
    final    = Diff.annotated_patch(original, patches, get_annotations(),
      &Enum.join/1)
    assert final, "t<span class='modified'>a</span>st"
  end

  test "do a deletion" do
    original = "test"
    changed  = "tst"
    patches  = Diff.diff(original, changed)
    final    = Diff.annotated_patch(original, patches, get_annotations(),
      &Enum.join/1)
    assert final, "t<span class='deleted'>a</span>st"
  end

  test "do an insertion" do
    original = "test"
    changed  = "teast"
    patches  = Diff.diff(original, changed)
    final    = Diff.annotated_patch(original, patches, get_annotations(),
      &Enum.join/1)
    assert final, "te<span class='inserted'>a</span>st"
  end

  test "do a mixed test" do
    original = "abcdefghijklmnopqrst"
    changed  = "abcefgh1ikkmnqrxxst"
    patches  = Diff.diff(original, changed)
    final    = Diff.annotated_patch(original, patches, get_annotations(),
      &Enum.join/1)
    assert final, """
    abc<span class='deleted'>d</span>
    fgh
    <span class='inserted'>1</span>
    ik
    <span class='modified'>k</span>
    mn
    abc<span class='deleted'>op</span>
    qr
    <span class='inserted'>xx</span>
    st
    """
  end

  defp get_annotations() do
    [
    %{delete:   %{before: "<span class='deleted'>",
                  after:  "</span>"}},
    %{insert:   %{before: "<span class='inserted'>",
                  after:  "</span>"}},
    %{modified: %{before: "<span class='modified'>",
                  after:  "</span>"}}
  ]
  end

end
