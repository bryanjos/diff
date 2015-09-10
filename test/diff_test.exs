defmodule DiffTest do
  use ExUnit.Case

  test "no results when text matches" do
    results = Diff.diff("test", "test")
    assert results == []
  end

  test "returns changes when one character is added" do
    results = Diff.diff("test", "tests")
    assert results == [%Diff.Insert{index: 4, length: 1, text: "s"}]
  end

  test "returns changes when one character is removed" do
    results = Diff.diff("test", "tes")
    assert results == [%Diff.Delete{index: 3, length: 1, text: "t"}]
  end

  test "returns changes when one character is modified" do
    results = Diff.diff("test", "tesr")
    assert results == [%Diff.Modified{index: 3, length: 1, old_text: "t", text: "r"}]
  end

  test "returns changes when modified in the middle" do
    results = Diff.diff("test", "tart")
    assert results == [%Diff.Modified{index: 1, length: 2, old_text: "es", text: "ar"}]
  end
  
end
