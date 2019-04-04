defmodule GraphQL.Resolvers.EmployeeRequest do
  @moduledoc false

  alias Core.EmployeeRequests
  alias Core.LegalEntities.LegalEntity

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def create_employee_request(%{signed_content: signed_content}, %{context: %{headers: headers}}) do
    params = %{
      "signed_content" => Map.get(signed_content, :content),
      "signed_content_encoding" => signed_content |> Map.get(:encoding) |> to_string()
    }

    with {:ok, employee_request} <- EmployeeRequests.create_signed(params, headers) do
      {:ok, %{employee_request: employee_request}}
    end
  end

  def resolve_legal_entity(%{data: %{"legal_entity_id" => legal_entity_id}}, _, _) do
    {:ok, @read_prm_repo.get(LegalEntity, legal_entity_id)}
  end

  def resolve_legal_entity(_, _, _), do: {:ok, nil}

  def resolve_data([_ | _] = path), do: fn _, res -> {:ok, get_in(res.source.data, path)} end
end
