defmodule GraphQL.Unit.CheckUserRoleTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import Mox

  alias Ecto.UUID
  alias GraphQLWeb.Middleware.CheckUserRole

  @query """
    query ResourceQuery {
      resourceField {database_id}
    }
  """

  setup :verify_on_exit!

  defmodule Schema do
    @moduledoc false

    use Absinthe.Schema

    query do
      field :resource_field, list_of(:resource) do
        middleware(&put_client_id/2)
        middleware(CheckUserRole, role: "ADMIN")

        resolve(fn _, _ -> {:ok, []} end)
      end
    end

    object :resource do
      field(:database_id, :id)
    end

    def put_client_id(%{context: context} = resolution, _) do
      %{resolution | context: Map.put(context, :client_id, UUID.generate())}
    end
  end

  describe "check user role middleware" do
    test "allowed" do
      expect(MithrilMock, :search_user_roles, fn _, _ ->
        {:ok, %{"data" => [%{"role_name" => "ADMIN"}]}}
      end)

      {:ok, %{data: data}} = Absinthe.run(@query, Schema)
      assert %{"resourceField" => []} == data
    end

    test "forbidden" do
      expect(MithrilMock, :search_user_roles, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      {:ok, %{errors: [error]}} = Absinthe.run(@query, Schema)

      assert "FORBIDDEN" == error[:extensions][:code]
    end

    test "error from Mithril" do
      expect(MithrilMock, :search_user_roles, fn _, _ ->
        {:ok, %{"error" => %{}}}
      end)

      {:ok, %{errors: [error]}} = Absinthe.run(@query, Schema)

      assert "INTERNAL_SERVER_ERROR" == error[:extensions][:code]
    end
  end
end
