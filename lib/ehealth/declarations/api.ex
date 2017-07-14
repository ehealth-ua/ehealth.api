defmodule EHealth.Declarations.API do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_client_id: 1]
  import EHealth.Plugs.ClientContext, only: [get_context_params: 2]
  import EHealth.Declarations.View, only: [render_declaration: 5]

  alias EHealth.API.OPS
  alias EHealth.API.MPI
  alias EHealth.API.PRM
  alias EHealth.API.Mithril

  def get_declaration_by_id(id, headers) do
    with {:ok, resp} <- OPS.get_declaration_by_id(id, headers),
         {:ok, data} <- expand_declaration_relations(Map.fetch!(resp, "data"), headers),
         response    <- %{"meta" => Map.fetch!(resp, "meta"), "data" => data},
      do: {:ok, response}
  end

  def expand_declaration_relations(%{"legal_entity_id" => legal_entity_id} = declaration, headers) do
    with :ok                              <- check_declaration_access(legal_entity_id, headers),
         {:ok, %{"data" => person}}       <- MPI.person(declaration["person_id"], headers),
         {:ok, %{"data" => legal_entity}} <- PRM.get_legal_entity_by_id(legal_entity_id, headers),
         {:ok, %{"data" => division}}     <- PRM.get_division_by_id(declaration["division_id"], headers),
         {:ok, %{"data" => employee}}     <- PRM.get_employee_by_id(declaration["employee_id"], headers),
         response                         <- render_declaration(declaration, person, legal_entity, division, employee),
      do: {:ok, response}
  end

  def get_declarations(_params, _headers) do
    # ToDo: write a code
  end

  def check_declaration_access(legal_entity_id, headers) do
    case get_client_type_name(headers) do
      {:ok, client_type} ->
        headers
        |> get_client_id()
        |> get_context_params(client_type)
        |> legal_entity_allowed?(legal_entity_id)

      err -> err
    end
  end

  def get_client_type_name(headers) do
    headers
    |> get_client_id()
    |> Mithril.get_client_type_name(headers)
    |> case do
         nil -> {:error, :access_denied}
         client_type -> {:ok, client_type}
       end
  end

  def legal_entity_allowed?(%{"legal_entity_id" => id}, legal_entity_id) when legal_entity_id != id do
    {:error, :forbidden}
  end
  def legal_entity_allowed?(_, _), do: :ok
end
