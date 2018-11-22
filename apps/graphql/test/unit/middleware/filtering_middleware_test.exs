defmodule GraphQL.Unit.FilteringMiddlewareTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias GraphQLWeb.Middleware.Filtering

  @query """
    query UserQuery($first: Int, $filter: UserFilter) {
      users(first: $first, filter: $filter) {
        name
      }
    }
  """

  defmodule Schema do
    use Absinthe.Schema

    query do
      field :users, list_of(:user) do
        arg(:first, :integer)
        arg(:filter, :user_filter)

        middleware(Filtering, filter: [name: :equal, organization: [name: :equal, type: :equal]])

        resolve(fn args, _ ->
          send(self(), args)
          {:ok, []}
        end)
      end
    end

    input_object :user_filter do
      field(:name, :string)
      field(:organization, :organization_filter)
    end

    input_object :organization_filter do
      field(:name, :string)
      field(:type, :string)
    end

    object :user do
      field(:name, :string)
      field(:organization, :organization)
    end

    object :organization do
      field(:name, :string)
      field(:type, :string)
    end
  end

  describe "filtering middleware" do
    test "without variables" do
      Absinthe.run(@query, Schema)

      assert_receive(%{})
    end

    test "with unrelated variables" do
      variables = %{
        "first" => 10
      }

      Absinthe.run(@query, Schema, variables: variables)

      assert_receive(%{first: 10})
    end

    test "with missing arguments" do
      variables = %{
        "filter" => %{
          "name" => "Foo"
        }
      }

      Absinthe.run(@query, Schema, variables: variables)

      assert_receive(%{
        filter: [
          {:name, :equal, "Foo"}
        ]
      })
    end

    test "with nested conditions" do
      variables = %{
        "filter" => %{
          "name" => "Foo",
          "organization" => %{"name" => "Bar", "type" => "Baz"}
        }
      }

      Absinthe.run(@query, Schema, variables: variables)

      assert_receive(%{
        filter: [
          {:name, :equal, "Foo"},
          {:organization, nil, [{:name, :equal, "Bar"}, {:type, :equal, "Baz"}]}
        ]
      })
    end
  end
end
