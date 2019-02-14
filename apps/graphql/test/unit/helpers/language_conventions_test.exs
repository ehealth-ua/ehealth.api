defmodule LanguageConventionsTest do
  @moduledoc false

  use Core.ConnCase, async: true

  import GraphQL.Helpers.LanguageConventions

  describe "to external" do
    test "strings" do
      assert "fooBar" = to_external("foo_bar")
    end

    test "atoms" do
      assert "fooBar" = to_external(:foo_bar)
    end

    test "maps" do
      assert %{
               "fooBar" => 1,
               "fooBaz" => "hi_there"
             } =
               to_external(%{
                 foo_bar: 1,
                 foo_baz: "hi_there"
               })
    end

    test "nested maps" do
      assert %{"fooBar" => %{"fooBaz" => 1}} = to_external(%{foo_bar: %{foo_baz: 1}})
    end

    test "nested lists" do
      assert %{
               "fooFirst" => [%{"bazSecond" => 1}, %{"bazSecond" => 2}],
               "barFirst" => ["foo_first", 1, "baz_second"]
             } =
               to_external(%{
                 foo_first: [%{baz_second: 1}, %{baz_second: 2}],
                 bar_first: ["foo_first", 1, "baz_second"]
               })
    end
  end
end
