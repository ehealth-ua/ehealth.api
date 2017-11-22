defmodule EHealth.PRM.Divisions do
  @moduledoc false

  use EHealth.PRM.Search

  alias EHealth.PRMRepo
  alias EHealth.PRM.Divisions.Search
  alias EHealth.PRM.Divisions.Schema, as: Division
  alias Ecto.Multi
  import EHealth.PRM.AuditLogs, only: [create_audit_logs: 1]

  @search_fields ~w(
    ids
    name
    legal_entity_id
    type
    status
  )a

  @fields_optional ~w(
    external_id
    mountain_group
    is_active
    location
  )a

  @fields_required ~w(
    legal_entity_id
    name
    type
    addresses
    phones
    status
    email
  )a

  @mountain_group_required_types %{mountain_group: :boolean, settlement_id: Ecto.UUID}

  def get_division_by_id!(id) do
    PRMRepo.get!(Division, id)
  end

  def get_division_by_id(id) do
    PRMRepo.get(Division, id)
  end

  def get_divisions(params) do
    %Search{}
    |> changeset(params)
    |> search(params, Division)
  end

  def get_by_ids(ids) when is_list(ids) do
    Division
    |> where([d], d.id in ^ids)
    |> PRMRepo.all()
  end

  def create_division(attrs, author_id) do
    %Division{}
    |> changeset(attrs)
    |> PRMRepo.insert_and_log(author_id)
  end

  def update_division(%Division{} = division, attrs, author_id) do
    division
    |> changeset(attrs)
    |> PRMRepo.update_and_log(author_id)
  end

  def update_divisions_mountain_group(attrs, consumer_id) do
    case validate_mountain_group_changeset(attrs) do
      %Ecto.Changeset{valid?: true} -> do_update_divisions_mountain_group(attrs, consumer_id)
      err_changeset                 -> err_changeset
    end
  end

  def get_search_query(Division = entity, %{ids: _} = changes) do
    super(entity, convert_comma_params_to_where_in_clause(changes, :ids, :id))
  end

  def get_search_query(Division = division, changes) do
    params =
      changes
      |> Map.drop([:name])
      |> Map.to_list()

    division
    |> select([d], d)
    |> query_name(Map.get(changes, :name))
    |> where(^params)
  end

  def query_name(query, nil), do: query
  def query_name(query, name) do
    query |> where([d], ilike(d.name, ^"%#{name}%"))
  end

  defp convert_comma_params_to_where_in_clause(changes, param_name, db_field) do
    changes
    |> Map.put(db_field, {String.split(changes[param_name], ","), :in})
    |> Map.delete(param_name)
  end

  defp changeset(%Division{} = division, %{"location" => %{"longitude" => lng, "latitude" => lat}} = attrs) do
    changeset(division, Map.put(attrs, "location", %Geo.Point{coordinates: {lng, lat}}))
  end
  defp changeset(%Division{} = division, attrs) do
    division
    |> cast(attrs, @fields_optional ++ @fields_required)
    |> validate_required(@fields_required)
    |> foreign_key_constraint(:legal_entity_id)
  end
  defp changeset(%Search{} = division, attrs) do
    cast(division, attrs, @search_fields)
  end

  defp validate_mountain_group_changeset(attrs) do
    required_params = Map.keys(@mountain_group_required_types)

    {%{}, @mountain_group_required_types}
    |> cast(attrs, required_params)
    |> validate_required(required_params)
  end

  defp do_update_divisions_mountain_group(%{settlement_id: settlement_id, mountain_group: mountain_group}, consumer_id)
  do
    addresses = [%{settlement_id: settlement_id}]

    query =
      from d in Division,
      where: d.mountain_group != ^mountain_group and
             fragment("? @> ?::jsonb", d.addresses, ^addresses)

    Multi.new()
    |> Multi.update_all(
        :update_divisions_mountain_group,
        query,
        [set: [mountain_group: mountain_group, updated_at: NaiveDateTime.utc_now()]],
        returning: [:id, :mountain_group])
    |> Multi.run(:log_updates, &log_changes(&1, consumer_id))
    |> PRMRepo.transaction()
  end

  defp log_changes(%{update_divisions_mountain_group: {_, updated_divisions}}, consumer_id) do
    {_, changelog} =
      updated_divisions
      |> Enum.map(fn ud ->
          %{
            actor_id: consumer_id,
            resource: "divisions",
            resource_id: ud.id,
            changeset: %{mountain_group: ud.mountain_group},
          }
         end)
      |> create_audit_logs()

    {:ok, changelog}
  end
end
