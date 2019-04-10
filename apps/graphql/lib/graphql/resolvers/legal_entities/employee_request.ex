defmodule GraphQL.Resolvers.EmployeeRequest do
  @moduledoc false

  import Ecto.Query, only: [order_by: 3]
  import GraphQL.Filters.EmployeeRequests, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.EmployeeRequests
  alias Core.EmployeeRequests.EmployeeRequest
  alias Core.LegalEntities.LegalEntity
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Ecto.Query

  @read_repo Application.get_env(:core, :repos)[:read_repo]
  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_employee_requests(%{filter: filter, order_by: order_by} = args, _) do
    EmployeeRequest
    |> filter(filter)
    |> order_by(order_by)
    |> Connection.from_query(&@read_repo.all/1, args)
  end

  defp order_by(query, [{direction, :full_name}]) do
    order_by(query, [er], [
      {^direction, fragment("?->'party'->>'last_name'", er.data)},
      {^direction, fragment("?->'party'->>'first_name'", er.data)},
      {^direction, fragment("?->'party'->>'second_name'", er.data)}
    ])
  end

  defp order_by(query, expr), do: Query.order_by(query, ^expr)

  def create_employee_request(%{signed_content: signed_content}, %{context: %{headers: headers}}) do
    params = %{
      "signed_content" => Map.get(signed_content, :content),
      "signed_content_encoding" => signed_content |> Map.get(:encoding) |> to_string()
    }

    with {:ok, employee_request} <- EmployeeRequests.create_signed(params, headers) do
      {:ok, %{employee_request: employee_request}}
    else
      %ValidationError{} = err -> Error.dump(err)
      err -> err
    end
  end

  def resolve_legal_entity(%{data: %{"legal_entity_id" => legal_entity_id}}, _, _) do
    {:ok, @read_prm_repo.get(LegalEntity, legal_entity_id)}
  end

  def resolve_legal_entity(_, _, _), do: {:ok, nil}

  def resolve_data([_ | _] = path), do: fn _, res -> {:ok, get_in(res.source.data, path)} end
end
