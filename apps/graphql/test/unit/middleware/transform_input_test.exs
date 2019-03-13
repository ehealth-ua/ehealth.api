defmodule GraphQL.Unit.Middleware.TransformInputTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Ecto.UUID
  alias GraphQL.Middleware.TransformInput

  @query """
    query UserQuery($filter: UserFilter){
      users(filter: $filter){
        database_id
      }
    }
  """

  defmodule Schema do
    @moduledoc false

    use Absinthe.Schema

    query do
      field :users, list_of(:user) do
        arg(:filter, :user_filter)

        middleware(TransformInput, %{
          :user_id => [:database_id],
          :manager_id => [:manager, :database_id],
          :organization_id => [:manager, :organization, :database_id],
          [:supervisor, :name] => [:manager, :first_name],
          [:supervisor, :last_name] => [:manager, :last_name],
          :non_exist => [:something]
        })

        resolve(fn args, _ ->
          send(self(), args)
          {:ok, []}
        end)
      end
    end

    input_object :user_filter do
      field(:database_id, :id)
      field(:manager, :manager_filter)
    end

    input_object :manager_filter do
      field(:database_id, :id)
      field(:first_name, :string)
      field(:last_name, :string)
      field(:organization, :organization_filter)
    end

    input_object :organization_filter do
      field(:database_id, :id)
    end

    object :user do
      field(:database_id, :id)
    end
  end

  describe "transform input middleware" do
    test "empty request" do
      Absinthe.run(@query, Schema)

      assert_receive(%{filter: %{}})
    end

    test "full request data" do
      [user_id, manager_id, orgranization_id] = generate_uuids(3)

      variables = %{
        "filter" => %{
          "databaseId" => user_id,
          "manager" => %{
            "databaseId" => manager_id,
            "firstName" => "John",
            "lastName" => "Doe",
            "organization" => %{
              "databaseId" => orgranization_id
            }
          }
        }
      }

      Absinthe.run(@query, Schema, variables: variables)

      assert_receive(%{
        filter: %{
          user_id: user_id,
          manager_id: manager_id,
          organization_id: organization_id,
          supervisor: %{name: "John", last_name: "Doe"}
        }
      })
    end

    test "partial request data" do
      [user_id, organization_id] = generate_uuids(2)

      variables = %{
        "filter" => %{
          "databaseId" => user_id,
          "manager" => %{
            "organization" => %{
              "databaseId" => organization_id
            }
          }
        }
      }

      Absinthe.run(@query, Schema, variables: variables)

      assert_receive(%{
        filter: %{
          organization_id: organization_id,
          user_id: user_id
        }
      })
    end
  end

  defp generate_uuids(count) when count >= 1, do: Enum.map(1..count, fn _ -> UUID.generate() end)
end
