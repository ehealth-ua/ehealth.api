defmodule EHealth.Declarations.API do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_client_id: 1]
  import EHealth.Plugs.ClientContext, only: [get_context_params: 2]
  import EHealth.Declarations.View, only: [render_declarations: 1, render_declaration: 1]

  alias EHealth.API.OPS
  alias EHealth.API.MPI
  alias EHealth.API.PRM
  alias EHealth.API.Mithril

  def get_declarations(params, headers) do
    with {:ok, resp}      <- OPS.get_declarations(params, headers),
         related_ids      <- fetch_related_ids(Map.fetch!(resp, "data")),
         {:ok, divisions} <- PRM.get_divisions(%{ids: list_to_param(related_ids["division_ids"])}, headers),
         {:ok, employees} <- PRM.get_employees(%{ids: list_to_param(related_ids["employee_ids"])}, headers),
         {:ok, legals}    <- PRM.get_legal_entities(%{ids: list_to_param(related_ids["legal_entity_ids"])}, headers),
         {:ok, persons}   <- MPI.search(%{ids: list_to_param(related_ids["person_ids"])}, headers),
         relations        <- build_indexes(divisions["data"], employees["data"], legals["data"], persons["data"]),
         prepared_data    <- merge_related_data(resp["data"], relations),
         declarations     <- render_declarations(prepared_data),
         response         <- Map.put(resp, "data", declarations),
      do: {:ok, response}
  end

  def fetch_related_ids(declarations) do
    acc = %{"person_ids" => [], "division_ids" => [], "employee_ids" => [], "legal_entity_ids" => []}
    declarations
    |> Enum.map_reduce(acc, fn (declaration, acc) ->
         acc = Enum.map(acc, fn({field_name, list}) ->
           {field_name, put_related_id(list, declaration[String.trim_trailing(field_name, "s")])}
         end)
         {nil, acc}
       end)
    |> elem(1)
    |> Enum.into(%{})
  end

  defp put_related_id(list, id) do
    case Enum.member?(list, id) do
      false -> List.insert_at(list, 0, id)
      true -> list
    end
  end

  def list_to_param(list), do: Enum.join(list, ",")

  def build_indexes(divisions, employees, legal_entities, persons) do
    %{}
    |> Map.put(:persons, build_index(persons))
    |> Map.put(:divisions, build_index(divisions))
    |> Map.put(:employees, build_index(employees))
    |> Map.put(:legal_entities, build_index(legal_entities))
  end

  def build_index([]), do: %{}
  def build_index(data) do
    data
    |> Enum.map_reduce(%{}, fn (item, acc) -> {nil, Map.put(acc, item["id"], item)} end)
    |> elem(1)
  end

  def merge_related_data(data, relations) do
    Enum.map(data, fn (item) ->
      merge_related_data(item,
        Map.get(relations.persons, item["person_id"], %{}),
        Map.get(relations.legal_entities, item["legal_entity_id"], %{}),
        Map.get(relations.divisions, item["division_id"], %{}),
        Map.get(relations.employees, item["employee_id"], %{})
      )
    end)
  end

  def merge_related_data(declaration, person, legal_entity, division, employee) do
    declaration
    |> Map.merge(%{
         "person" => person,
         "division" => division,
         "employee" => employee,
         "legal_entity" => legal_entity,
       })
    |> Map.drop(~W(person_id division_id employee_id legal_entity_id))
  end

  def get_declaration_by_id(id, headers) do
    with {:ok, resp} <- OPS.get_declaration_by_id(id, headers),
         {:ok, data} <- expand_declaration_relations(Map.fetch!(resp, "data"), headers),
         response    <- %{"meta" => Map.fetch!(resp, "meta"), "data" => data},
      do: {:ok, response}
  end

  def update_declaration(id, attrs, headers) do
    with {:ok, %{"data" => declaration}} <- OPS.get_declaration_by_id(id, headers),
          :ok <- check_declaration_access(declaration["legal_entity_id"], headers),
          :ok <- active?(declaration) do
      OPS.update_declaration(declaration["id"], attrs, headers)
    end
  end

  def expand_declaration_relations(%{"legal_entity_id" => legal_entity_id} = declaration, headers) do
    with :ok          <- check_declaration_access(legal_entity_id, headers),
         person       <- load_relation(MPI, :person, declaration["person_id"], headers),
         legal_entity <- load_relation(PRM, :get_legal_entity_by_id, legal_entity_id, headers),
         division     <- load_relation(PRM, :get_division_by_id, declaration["division_id"], headers),
         employee     <- load_relation(PRM, :get_employee_by_id, declaration["employee_id"], headers),
         declaration  <- merge_related_data(declaration, person, legal_entity, division, employee),
         response     <- render_declaration(declaration),
      do: {:ok, response}
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

  def load_relation(module, func, id, headers) do
    case apply(module, func, [id, headers]) do
      {:ok, %{"data" => entity}} -> entity
      _ -> %{}
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

  defp active?(%{"is_active" => true}), do: :ok
  defp active?(%{"is_active" => false}), do: {:error, :not_found}
end
