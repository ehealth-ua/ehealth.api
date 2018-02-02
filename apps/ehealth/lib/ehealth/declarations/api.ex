defmodule EHealth.Declarations.API do
  @moduledoc false

  import Ecto.Changeset
  import EHealth.Utils.Connection, only: [get_client_id: 1, get_consumer_id: 1]
  import EHealth.Plugs.ClientContext, only: [get_context_params: 2]
  import EHealth.Declarations.View, only: [render_declarations: 1, render_declaration: 1]

  alias EHealth.API.OPS
  alias EHealth.API.MPI
  alias EHealth.API.Mithril
  alias EHealth.LegalEntities
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Employees
  alias EHealth.Employees.Employee
  alias EHealth.Divisions
  alias EHealth.Divisions.Division

  def get_declarations(params, headers) do
    with {:ok, resp} <- OPS.get_declarations(params, headers),
         related_ids <- fetch_related_ids(Map.fetch!(resp, "data")),
         divisions <- Divisions.get_by_ids(related_ids["division_ids"]),
         employees <- Employees.get_by_ids(related_ids["employee_ids"]),
         legal_entities <- LegalEntities.get_by_ids(related_ids["legal_entity_ids"]),
         {:ok, persons} <- preload_persons(Enum.join(related_ids["person_ids"], ","), headers),
         relations <- build_indexes(divisions, employees, legal_entities, persons["data"]),
         prepared_data <- merge_related_data(resp["data"], relations),
         declarations <- render_declarations(prepared_data),
         response <- Map.put(resp, "data", declarations),
         do: {:ok, response}
  end

  def fetch_related_ids(declarations) do
    acc = %{"person_ids" => [], "division_ids" => [], "employee_ids" => [], "legal_entity_ids" => []}

    declarations
    |> Enum.map_reduce(acc, fn declaration, acc ->
      acc =
        Enum.map(acc, fn {field_name, list} ->
          {field_name, put_related_id(list, declaration[String.trim_trailing(field_name, "s")])}
        end)

      {nil, acc}
    end)
    |> elem(1)
    |> Enum.into(%{})
  end

  defp preload_persons("", _), do: {:ok, %{"data" => []}}
  defp preload_persons(ids, headers), do: MPI.all_search(%{ids: ids}, headers)

  defp put_related_id(list, id) do
    case Enum.member?(list, id) do
      false -> List.insert_at(list, 0, id)
      true -> list
    end
  end

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
    |> Enum.map_reduce(%{}, fn
      %Division{} = item, acc ->
        {nil, Map.put(acc, item.id, item)}

      %LegalEntity{} = item, acc ->
        {nil, Map.put(acc, item.id, item)}

      %Employee{} = item, acc ->
        {nil, Map.put(acc, item.id, item)}

      item, acc ->
        {nil, Map.put(acc, item["id"], item)}
    end)
    |> elem(1)
  end

  def merge_related_data(data, relations) do
    Enum.map(data, fn item ->
      merge_related_data(
        item,
        Map.get(relations.persons, item["person_id"]),
        Map.get(relations.legal_entities, item["legal_entity_id"]),
        Map.get(relations.divisions, item["division_id"]),
        Map.get(relations.employees, item["employee_id"])
      )
    end)
  end

  def merge_related_data(declaration, person, legal_entity, division, employee) do
    declaration
    |> Map.merge(%{
      "person" => person,
      "division" => division,
      "employee" => employee,
      "legal_entity" => legal_entity
    })
    |> Map.drop(~W(person_id division_id employee_id legal_entity_id))
  end

  def get_declaration_by_id(id, headers) do
    with {:ok, resp} <- OPS.get_declaration_by_id(id, headers),
         {:ok, data} <- expand_declaration_relations(Map.fetch!(resp, "data"), headers),
         response <- %{"meta" => Map.fetch!(resp, "meta"), "data" => data},
         do: {:ok, response}
  end

  def update_declaration(id, attrs, headers) do
    with {:ok, %{"data" => declaration}} <- OPS.get_declaration_by_id(id, headers),
         :ok <- check_declaration_access(declaration["legal_entity_id"], headers),
         :ok <- active?(declaration) do
      OPS.update_declaration(declaration["id"], %{"declaration" => attrs}, headers)
    end
  end

  def terminate_declarations(attrs, headers) do
    user_id = get_consumer_id(headers)
    types = %{person_id: Ecto.UUID, employee_id: Ecto.UUID, reason_description: :string}

    {%{}, types}
    |> cast(attrs, Map.keys(types))
    |> validate_required_one_inclusion([:person_id, :employee_id])
    |> terminate_ops_declarations(user_id, attrs["reason_description"], headers)
  end

  defp terminate_ops_declarations(%Ecto.Changeset{valid?: false} = changeset, _, _, _), do: changeset

  defp terminate_ops_declarations(%Ecto.Changeset{changes: %{person_id: person_id}}, user_id, reason_desc, headers) do
    person_id
    |> OPS.terminate_person_declarations(user_id, "manual_person", reason_desc, headers)
    |> maybe_render_error("Person does not have active declarations")
  end

  defp terminate_ops_declarations(%Ecto.Changeset{changes: %{employee_id: employee_id}}, user_id, reason_desc, headers) do
    employee_id
    |> OPS.terminate_employee_declarations(user_id, "manual_employee", reason_desc, headers)
    |> maybe_render_error("Employee does not have active declarations")
  end

  defp maybe_render_error({:ok, %{"data" => %{"terminated_declarations" => []}}}, msg) do
    {:error, {:"422", msg}}
  end

  defp maybe_render_error(resp, _msg), do: resp

  defp validate_required_one_inclusion(%{changes: changes} = changeset, fields) do
    case map_size(Map.take(changes, fields)) do
      1 ->
        changeset

      _ ->
        add_error(
          changeset,
          hd(fields),
          "One and only one of these fields must be present: " <> Enum.join(fields, ", ")
        )
    end
  end

  def expand_declaration_relations(%{"legal_entity_id" => legal_entity_id} = declaration, headers) do
    with :ok <- check_declaration_access(legal_entity_id, headers),
         person <- load_relation(MPI, :person, declaration["person_id"], headers),
         legal_entity <- LegalEntities.get_by_id(legal_entity_id),
         division <- Divisions.get_by_id(declaration["division_id"]),
         employee <- Employees.get_by_id(declaration["employee_id"]),
         declaration <- merge_related_data(declaration, person, legal_entity, division, employee),
         response <- render_declaration(declaration),
         do: {:ok, response}
  end

  defp check_declaration_access(legal_entity_id, headers) do
    case Mithril.get_client_type_name(get_client_id(headers), headers) do
      {:ok, nil} ->
        {:error, :access_denied}

      {:ok, client_type} ->
        headers
        |> get_client_id()
        |> get_context_params(client_type)
        |> legal_entity_allowed?(legal_entity_id)

      err ->
        err
    end
  end

  def load_relation(module, func, id, headers) do
    case apply(module, func, [id, headers]) do
      {:ok, %{"data" => entity}} -> entity
      _ -> %{}
    end
  end

  def legal_entity_allowed?(%{"legal_entity_id" => id}, legal_entity_id) when legal_entity_id != id do
    {:error, :forbidden}
  end

  def legal_entity_allowed?(_, _), do: :ok

  defp active?(%{"is_active" => true}), do: :ok
  defp active?(%{"is_active" => false}), do: {:error, :not_found}
end
